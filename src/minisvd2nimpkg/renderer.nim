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

proc renderHeader(outf, device)
proc renderDevice(outf, device)
proc renderPeripherals(outf, device)
proc renderPeripheral(outf, device, peripheral)
proc renderInterrupt(outf, device, peripheral, interrupt)
proc renderRegister(outf, device, peripheral, register)
proc renderField(outf, device, peripheral, register, field)

proc renderNimFromSvd*(outf, device) =
  renderHeader(outf, device)
  renderDevice(outf, device)
  renderPeripherals(outf, device)

proc renderHeader(outf, device) =
  let filenameParts = getAppFilename().splitFile()
  let toolName = filenameParts.name & filenameParts.ext
  write(
    outf,
    fmt"""
# This file is auto-generated.
# Edits will be lost if the tool is run again.
#
# Tool:                 {toolName}
# Tool version:         {getVersion().strip()}
# Tool args:            {commandLineParams()}
# Input file version:   {device.version}

import std/volatile

from minisvd2nim import templates

"""
  )

proc renderDevice(outf, device) =
  write(
    outf,
    fmt"""
declareDevice(deviceName = "{device.name}", mpuPresent = {device.cpu.mpuPresent}, fpuPresent = {device.cpu.fpuPresent}, nvicPrioBits = {device.cpu.nvicPrioBits})
"""
  )

proc renderPeripherals(outf, device) =
  if not isNil(device.peripherals):
    write(outf, "# Peripherals\p")
    for p in device.peripherals[]:
      renderPeripheral(outf, device, p)

proc renderPeripheral(outf, device, peripheral) =
  if not isNil(peripheral.interrupts):
    for irq in peripheral.interrupts[]:
      renderInterrupt(outf, device, peripheral, irq)
  if not isNil(peripheral.registers):
    for r in peripheral.registers[]:
      renderRegister(outf, device, peripheral, r)

proc renderInterrupt(outf, device, peripheral, interrupt) =
  write(
    outf,
    fmt"""
declareInterrupt(peripheralName = "{peripheral.name}", interruptName = "{interrupt.name}", interruptValue = {interrupt.value}, interruptDesc = "{interrupt.description}")
"""
  )

proc renderRegister(outf, device, peripheral, register) =
  let regAddress = peripheral.baseAddress + register.addressOffset.uint
  write(
    outf,
    fmt"""
declareRegister(peripheralName = "{peripheral.name}", registerName = "{register.name}", registerAddress = 0x{toHex(regAddress, 8)}, registerDesc = "{register.description}")
"""
  )
  if not isNil(register.fields):
    for f in register.fields[]:
      renderField(outf, device, peripheral, register, f)

proc renderField( outf, device, peripheral, register, field) =
  write(
    outf,
    fmt"""
declareField(peripheralName = "{peripheral.name}", registerName = "{register.name}", fieldName = "{field.name}", bitOffset = {field.bitOffset}, bitWidth = {field.bitWidth}, access = {field.access}, fieldDesc = "{field.description}")
"""
  )
