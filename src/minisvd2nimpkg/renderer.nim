## Renders Nim source to represent a device
## according to the given SVD data
##
## Reference:
##    https://www.keil.com/pack/doc/CMSIS/SVD/html/svd_Format_pg.html
##

import std/os
import std/strformat
import std/strutils

import svdtypes
import versions

type Renderer* = ref object
  device*: SvdDevice
  outf*: File

proc renderHeader(outf: File, device: SvdDevice)
proc renderCpu(outf: File, device: SvdDevice)
proc renderInterrupts(outf: File, device: SvdDevice)

proc renderNimFromSvd*(outf: File, device: SvdDevice) =
  renderHeader(outf, device)
  renderCpu(outf, device)
  renderInterrupts(outf, device)
  # renderPeripherals
  #   renderRegisters
  #     renderFields

proc renderHeader(outf: File, device: SvdDevice) =
  let filenameParts = getAppFilename().splitFile()
  let toolName = filenameParts.name & filenameParts.ext
  write(outf, fmt"""
# This file is auto-generated.
# Edits will be lost if the tool is run again.
#
# Tool:                 {toolName}
# Tool version:         {getVersion().strip()}
# Tool args:            {commandLineParams()}
# Input file version:   {device.version}

import std/volatile

import templates

""")

proc renderCpu(outf: File, device: SvdDevice) =
  write(outf, fmt"""
# CPU details
const DEVICE* = "{device.name}"
const MPU_PRESET* = {device.cpu.mpuPresent}
const FPU_PRESENT* = {device.cpu.fpuPresent}
const NVIC_PRIO_BITS* = {device.cpu.nvicPrioBits}

""")

proc renderInterrupts(outf: File, device: SvdDevice) =
  write(outf, fmt"""
# TODO: fill in this placeholder
Interrupts* = enum
  discard

""")
