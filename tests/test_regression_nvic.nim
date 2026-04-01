import unittest2
import volatile_mock

# File under test:
import minisvd2nimpkg/metagenerator

#!fmt: off
declarePeripheral(peripheralName = NVIC, baseAddress = 0xE000E100'u32, peripheralDesc = "Nested Vectored Interrupt Controller")
declareRegister(peripheralName = NVIC, registerName = NVIC_IPR, addressOffset = 0x00000300'u32, dim = 124, dimIncrement = 4, readAccess = true, writeAccess = true, registerDesc = "Interrupt Priority Register sets or reads interrupt priorities")
declareField(peripheralName = NVIC, registerName = NVIC_IPR, fieldName = PRI_N3, bitOffset = 24, bitWidth = 8, dim = 0, dimIncrement = 0, readAccess = true, writeAccess = true, fieldDesc = "For register NVIC_IPRn, priority of interrupt number 4n+3")
declareField(peripheralName = NVIC, registerName = NVIC_IPR, fieldName = PRI_N2, bitOffset = 16, bitWidth = 8, dim = 0, dimIncrement = 0, readAccess = true, writeAccess = true, fieldDesc = "For register NVIC_IPRn, priority of interrupt number 4n+2")
declareField(peripheralName = NVIC, registerName = NVIC_IPR, fieldName = PRI_N1, bitOffset = 8, bitWidth = 8, dim = 0, dimIncrement = 0, readAccess = true, writeAccess = true, fieldDesc = "For register NVIC_IPRn, priority of interrupt number 4n+1")
declareField(peripheralName = NVIC, registerName = NVIC_IPR, fieldName = PRI_N0, bitOffset = 0, bitWidth = 8, dim = 0, dimIncrement = 0, readAccess = true, writeAccess = true, fieldDesc = "For register NVIC_IPRn, priority of interrupt number 4n")

suite "Regression of field access of dimensioned register":
  test "field read of dimensioned register SHOULD compile":
    check compiles (discard NVIC.NVIC_IPR[123].PRI_N3(3'u32);)
  test "all declared fields SHOULD allow rmw":
    check compiles (NVIC.NVIC_IPR[123].PRI_N3(3'u32).PRI_N2(2'u32).PRI_N1(1'u32).PRI_N0(0'u32).write();)
  test "rmw of dimensioned register SHOULD work":
    const dimRegAddr = 0xE000E100'u32 + 0x300 + 123 * 4
    mockInitRegs()
    mockRegPreset(dimRegAddr, 0xFFFF_FFFF'u32)
    NVIC.NVIC_IPR[123].PRI_N3(3'u32).write
    check mockRegRead(dimRegAddr) == 0x03FF_FFFF

