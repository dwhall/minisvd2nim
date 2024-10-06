## Copyright 2024 Dean Hall, all rights reserved.  See LICENSE.txt for details.
##
## renderer.nim
##
## Renders an SvdDevice object to a Nim source package.
##
## renderNimPackageFromSvd() is the only entry point to this module.
## It takes the arguments outPath and svdDevice
## and produces a nimble-compliant package of nim source code.
## outPath is a path of where to put the new nimble package directory:
##
##    <outPath>/<yourDevice>/<package files>
##
## where <yourDevice> is determined by the SVD file contents;
## it is the lowercase of the XML: <device>.<name>'s innerText.
##
## The package declares one special module, `device` and a module
## for every peripheral described in the SVD file.  The `device` module
## contains constants related to the device and cpu.  Peripherals reside
## in a module matching their name.  Enumerated peripherals are grouped into
## a single module named after the peripheral, less the number.  For example,
## peripherals SPI1, SPI2 ... SPIn reside in spi.nim.
##
## The resulting Nimble-compliant package may be installed like any other package
## or added to a project as a dependency in source form.
##

import std/[dirs, files, os, paths, strformat, strutils]

import svdtypes
import versions

using
  device: SvdDevice
  devicePath: Path
  outPath: Path
  outf: File
  peripheral: SvdPeripheral
  interrupt: SvdInterrupt
  register: SvdRegister
  field: SvdRegField
  access: SvdAccess

const importMetaGenerator =
  """# To understand how to use the output of the declarations below, visit:
# https://github.com/dwhall/minisvd2nim/blob/main/README.md#how-to-access-the-device

import minisvd2nimpkg/metagenerator

"""

proc renderPackageFile(devicePath, device)
proc renderReadme(devicePath, device)
proc renderLicense(devicePath)
proc renderDevice(devicePath, device)
proc renderPeripherals(devicePath, device)
proc renderPeripheral(outf, device, peripheral)
proc renderInterrupt(outf, device, peripheral, interrupt)
proc renderRegister(outf, device, peripheral, register)
proc renderField(outf, device, peripheral, register, field)
func getPeripheralBaseName(p: SvdPeripheral): string

func readAccess(access): bool =
  access == readWrite or access == readOnly
func writeAccess(access): bool =
  access == readWrite or access == writeOnly

proc renderNimPackageFromSvd*(outPath, device) =
  ## Renders the Nim device package at the outPath path.
  ## The result is a nimblec-compliant package:
  ##    <outPath>/<device.name.toLower>/
  ##        <device.name.toLower>.nimble
  ##        device.nim
  ##        toLower(<peripheral.name>).nim
  ##        ...
  ##
  assert dirExists(outPath)
  let devicePath = outPath / Path(device.name.toLower())
  if dirExists(devicePath):
    stderr.write(&"Exiting.  Target path already exists: {devicePath.string}")
    quit(QuitFailure)
  createDir(devicePath)
  renderPackageFile(devicePath, device)
  renderReadme(devicePath, device)
  renderLicense(devicePath)
  renderDevice(devicePath, device)
  renderPeripherals(devicePath, device)

proc renderPackageFile(devicePath, device) =
  let packageFn = devicePath / Path(device.name.toLower).addFileExt("nimble")
  var outf: File
  assert outf.open(packageFn.string, fmWrite)
  defer:
    outf.close()
  outf.write(
    &"""
#!fmt: off

version       = {getVersion().strip()}  # same as minisvd2nim's version
author        = "minisvd2nim (generated)"
description   = "Device and peripheral modules for the {device.name}."
license       = "MIT"

requires
  "minisvd2nim >= 1.0.0"
  "nim >= 2.0.0"
"""
  )

proc renderReadme(devicePath, device) =
  let filenameParts = getAppFilename().splitFile()
  let toolName = filenameParts.name & filenameParts.ext
  let readme = devicePath / Path("README.txt")
  var outf: File
  assert outf.open(readme.string, fmWrite)
  defer:
    outf.close()
  outf.write(
    &"""
This package is auto-generated by minisvd2nim, https://github.com/dwhall/minisvd2nim
Edits will be lost if the tool is run again.

Tool:                 {toolName}
Tool version:         {getVersion().strip()}
Tool args:            {commandLineParams()}
Input file version:   {device.version}
"""
  )

proc renderLicense(devicePath) =
  const licenseFileContents =
    """Copyright 2024 Dean Hall

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the �Software�), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED �AS IS�, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  """
  let licenseFn = devicePath / Path("LICENSE.txt")
  var outf: File
  assert outf.open(licenseFn.string, fmWrite)
  defer:
    outf.close()
  outf.write(licenseFileContents)

proc renderDevice(devicePath, device) =
  let fn = devicePath / Path("device.nim")
  var outf: File
  assert outf.open(fn.string, fmWrite)
  defer:
    outf.close()
  outf.write(
    importMetaGenerator & &"#!fmt: off\n" &
      &"declareDevice(deviceName = {device.name}, mpuPresent = {device.cpu.mpuPresent}, fpuPresent = {device.cpu.fpuPresent}, nvicPrioBits = {device.cpu.nvicPrioBits})\p"
  )

proc renderPeripherals(devicePath, device) =
  ## Write distinct peripherals to their own module.
  ## Write enumerated peripherals to a common module
  ## (e.g. SPI1, SPI2, SPIn are written to spi.nim).
  var outf: File
  for p in device.peripherals:
    let lowerPeriphName = getPeripheralBaseName(p).toLower
    let periphModule = devicePath / Path(lowerPeriphName).addFileExt("nim")
    let exists = fileExists(periphModule)
    assert outf.open(periphModule.string, fmAppend)
    if not exists:
      outf.write(importMetaGenerator)
      outf.write("#!fmt: off\n")
    outf.renderPeripheral(device, p)
    outf.close()

func getPeripheralBaseName(p: SvdPeripheral): string =
  ## Removes digits from the tail of the peripheral's name.
  ## Returns the possibly shortened peripheral name.
  let fullName = p.name
  var i = len(fullName) - 1
  while i > 0 and fullName[i].isDigit:
    dec i
  result = fullName[0 .. i]

proc renderPeripheral(outf, device, peripheral) =
  outf.write(
    &"declarePeripheral(peripheralName = {peripheral.name}, baseAddress = 0x{peripheral.baseAddress:X}'u32, peripheralDesc = \"{peripheral.description}\")\p"
  )
  for irq in peripheral.interrupt:
    renderInterrupt(outf, device, peripheral, irq)
  for r in peripheral.registers:
    renderRegister(outf, device, peripheral, r)

proc renderInterrupt(outf, device, peripheral, interrupt) =
  outf.write(
    &"declareInterrupt(peripheralName = {peripheral.name}, interruptName = {interrupt.name}, interruptValue = {interrupt.value}, interruptDesc = \"{interrupt.description}\")\p"
  )

proc renderRegister(outf, device, peripheral, register) =
  let declaration =
    if len(register.derivedFrom) > 0:
      &"declareRegister(peripheralName = {peripheral.name}, registerName = {register.name}, addressOffset = 0x{toHex(register.addressOffset.uint, 8)}'u32, readAccess = {readAccess(register.access)}, writeAccess = {writeAccess(register.access)}, registerDesc = \"{register.description}\", derivedFrom = {register.derivedFrom})\p"
    else:
      &"declareRegister(peripheralName = {peripheral.name}, registerName = {register.name}, addressOffset = 0x{toHex(register.addressOffset.uint, 8)}'u32, readAccess = {readAccess(register.access)}, writeAccess = {writeAccess(register.access)}, registerDesc = \"{register.description}\")\p"
  outf.write(declaration)
  for f in register.fields:
    renderField(outf, device, peripheral, register, f)

proc renderField(outf, device, peripheral, register, field) =
  outf.write(
    &"declareField(peripheralName = {peripheral.name}, registerName = {register.name}, fieldName = {field.name}, bitOffset = {field.bitOffset}, bitWidth = {field.bitWidth}, readAccess = {readAccess(register.access)}, writeAccess = {writeAccess(register.access)}, fieldDesc = \"{field.description}\")\p"
  )
  if field.enumeratedValues.values.len > 0:
    outf.write(
      &"declareFieldEnum(peripheralName = {peripheral.name}, registerName = {register.name}, fieldName = {field.name}, bitOffset = {field.bitOffset}, bitWidth = {field.bitWidth}):\p"
    )
    for enumVal in field.enumeratedValues.values.items():
      outf.write(&"  {enumVal.name} = {enumVal.value}\p")
