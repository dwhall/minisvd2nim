## Copyright 2024 Dean Hall, all rights reserved.  See LICENSE.txt for details.
##
## Renders Nim source to represent a device
## according to the given SVD data
##

import std/os
import std/strformat
import std/strutils

import svdtypes
import versions

using
  outf: File
  device: SvdDevice
  peripheral: SvdPeripheral
  interrupt: SvdInterrupt
  register: SvdRegister
  field: SvdRegField
  access: SvdAccess

proc renderHeader(outf, device)
proc renderDevice(outf, device)
proc renderPeripherals(outf, device)
proc renderPeripheral(outf, device, peripheral)
proc renderInterrupt(outf, device, peripheral, interrupt)
proc renderRegister(outf, device, peripheral, register)
proc renderField(outf, device, peripheral, register, field)

func readAccess(access): bool =
  access == readWrite or access == readOnly
func writeAccess(access): bool =
  access == readWrite or access == writeOnly

proc renderNimFromSvd*(outf, device) =
  renderHeader(outf, device)
  renderDevice(outf, device)
  renderPeripherals(outf, device)

proc renderHeader(outf, device) =
  let filenameParts = getAppFilename().splitFile()
  let toolName = filenameParts.name & filenameParts.ext
  outf.write(
    &"""
# This file is auto-generated.
# Edits will be lost if the tool is run again.
#
# Tool:                 {toolName}
# Tool version:         {getVersion().strip()}
# Tool args:            {commandLineParams()}
# Input file version:   {device.version}

import minisvd2nimpkg/metagenerator

"""
  )

proc renderDevice(outf, device) =
  outf.write(
    &"declareDevice(deviceName = {device.name}, mpuPresent = {device.cpu.mpuPresent}, fpuPresent = {device.cpu.fpuPresent}, nvicPrioBits = {device.cpu.nvicPrioBits})\n"
  )

proc renderPeripherals(outf, device) =
  for p in device.peripherals:
    renderPeripheral(outf, device, p)

proc renderPeripheral(outf, device, peripheral) =
  outf.write(
    &"declarePeripheral(peripheralName = {peripheral.name}, baseAddress = 0x{peripheral.baseAddress:X}'u32, peripheralDesc = \"{peripheral.description}\")\n"
  )
  for irq in peripheral.interrupt:
    renderInterrupt(outf, device, peripheral, irq)
  for r in peripheral.registers:
    renderRegister(outf, device, peripheral, r)

proc renderInterrupt(outf, device, peripheral, interrupt) =
  outf.write(
    &"declareInterrupt(peripheralName = {peripheral.name}, interruptName = {interrupt.name}, interruptValue = {interrupt.value}, interruptDesc = \"{interrupt.description}\")\n"
  )

proc renderRegister(outf, device, peripheral, register) =
  let declaration =
    if len(register.derivedFrom) > 0:
      &"declareRegister(peripheralName = {peripheral.name}, registerName = {register.name}, addressOffset = 0x{toHex(register.addressOffset.uint, 8)}'u32, readAccess = {readAccess(register.access)}, writeAccess = {writeAccess(register.access)}, registerDesc = \"{register.description}\", derivedFrom = {register.derivedFrom})\n"
    else:
      &"declareRegister(peripheralName = {peripheral.name}, registerName = {register.name}, addressOffset = 0x{toHex(register.addressOffset.uint, 8)}'u32, readAccess = {readAccess(register.access)}, writeAccess = {writeAccess(register.access)}, registerDesc = \"{register.description}\")\n"
  outf.write(declaration)
  for f in register.fields:
    renderField(outf, device, peripheral, register, f)

proc renderField(outf, device, peripheral, register, field) =
  outf.write(
    &"declareField(peripheralName = {peripheral.name}, registerName = {register.name}, fieldName = {field.name}, bitOffset = {field.bitOffset}, bitWidth = {field.bitWidth}, readAccess = {readAccess(register.access)}, writeAccess = {writeAccess(register.access)}, fieldDesc = \"{field.description}\")\n"
  )
  if field.enumeratedValues.values.len > 0:
    outf.write(
      &"declareFieldEnum(peripheralName = {peripheral.name}, registerName = {register.name}, fieldName = {field.name}, bitOffset = {field.bitOffset}, bitWidth = {field.bitWidth}):\n"
    )
    for enumVal in field.enumeratedValues.values.items():
      outf.write(&"  {enumVal.name} = {enumVal.value}\n")
