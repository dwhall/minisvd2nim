## Copyright 2026 Dean Hall See LICENSE for details
##
## Mocks the std/volatile module for testing purposes.
##

import std/tables

# A simple table holds the register test values.
# The table's key is the register address and the value
# is the register's value.
var regs: Table[uint32, uint32]

# The interfaces we are mocking
proc volatileLoad*[T](src: ptr T): T =
  T(regs[cast[uint32](src)])

proc volatileStore*[T](dest: ptr T, val: T) =
  regs[cast[uint32](dest)] = val.uint32

# Test support interface
proc mockInitRegs*() =
  regs = initTable[uint32, uint32]()

proc mockRegPreset*(regAddr: uint32, value: uint32) =
  regs[regAddr] = value

proc mockRegRead*(regAddr: uint32): uint32 =
  # we want an exception if the value at regAddr does not exist
  regs[regAddr]
