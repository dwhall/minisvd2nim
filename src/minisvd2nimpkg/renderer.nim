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
  register: SvdRegister
  field: SvdRegField

proc renderHeader(outf, device)
proc renderCpu(outf, device)
proc renderInterrupts(outf, device)
proc renderPeripherals(outf, device)
proc renderPeripheral(outf, device, peripheral)
proc renderRegister(outf, device, peripheral, register)
proc renderField(outf, device, peripheral, register, field)

proc renderNimFromSvd*(outf, device) =
  renderHeader(outf, device)
  renderCpu(outf, device)
  renderInterrupts(outf, device)
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

import templates

"""
  )

proc renderCpu(outf, device) =
  write(
    outf,
    fmt"""
# CPU details
const DEVICE* = "{device.name}"
const MPU_PRESET* = {device.cpu.mpuPresent}
const FPU_PRESENT* = {device.cpu.fpuPresent}
const NVIC_PRIO_BITS* = {device.cpu.nvicPrioBits}

"""
  )

proc renderInterrupts(outf, device) =
  write(
    outf,
    fmt"""
# TODO: fill in this placeholder
Interrupts* = enum
  discard

"""
  )

proc renderPeripherals(outf, device) =
  if not isNil(device.peripherals):
    write(outf, "# Peripherals\p")
    for p in device.peripherals[]:
      renderPeripheral(outf, device, p)

proc renderPeripheral(outf, device, peripheral) =
  # We do not output anything specific for a peripheral
  if not isNil(peripheral.registers):
    for r in peripheral.registers[]:
      renderRegister(outf, device, peripheral, r)

proc renderRegister(
    outf, device, peripheral, register
) =
  let regAddress = peripheral.baseAddress + register.addressOffset.uint
  write(
    outf,
    fmt"""
declareRegister("{peripheral.name}", "{register.name}", 0x{toHex(regAddress, 8)}, "{register.description}")
"""
  )
  if not isNil(register.fields):
    for f in register.fields[]:
      renderField(outf, device, peripheral, register, f)

proc renderField( outf, device, peripheral, register, field) =
  write(
    outf,
    fmt"""
declareField("{peripheral.name}", "{register.name}", "{field.name}", {field.bitOffset}, {field.bitWidth}, {field.access}, "{field.description}")
"""
  )
