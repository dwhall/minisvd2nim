import unittest2
import volatile_mock

# File under test:
import minisvd2nimpkg/metagenerator

#!fmt: off
declarePeripheral(peripheralName = NVIC, baseAddress = 0xE000E100'u32, peripheralDesc = "Nested Vectored Interrupt Controller")
declareRegister(peripheralName = NVIC, registerName = NVIC_ISER, addressOffset = 0x00000000'u32, dim = 16, dimIncrement = 4, readAccess = true, writeAccess = true, registerDesc = "Interrupt Set-Enable Register enables or reads the enable state of a group of interrupts")
declareField(peripheralName = NVIC, registerName = NVIC_ISER, fieldName = SETENA, bitOffset = 0, bitWidth = 1, dim = 32, dimIncrement = 1, readAccess = true, writeAccess = true, fieldDesc = "For register ISER[n], enables or shows the current enabled state of interrupt (m+(32*n))")
declareRegister(peripheralName = NVIC, registerName = NVIC_IPR, addressOffset = 0x00000300'u32, dim = 124, dimIncrement = 4, readAccess = true, writeAccess = true, registerDesc = "Interrupt Priority Register sets or reads interrupt priorities")
declareField(peripheralName = NVIC, registerName = NVIC_IPR, fieldName = PRI_N3, bitOffset = 24, bitWidth = 8, dim = 0, dimIncrement = 0, readAccess = true, writeAccess = true, fieldDesc = "For register NVIC_IPRn, priority of interrupt number 4n+3")
declareField(peripheralName = NVIC, registerName = NVIC_IPR, fieldName = PRI_N2, bitOffset = 16, bitWidth = 8, dim = 0, dimIncrement = 0, readAccess = true, writeAccess = true, fieldDesc = "For register NVIC_IPRn, priority of interrupt number 4n+2")
declareField(peripheralName = NVIC, registerName = NVIC_IPR, fieldName = PRI_N1, bitOffset = 8, bitWidth = 8, dim = 0, dimIncrement = 0, readAccess = true, writeAccess = true, fieldDesc = "For register NVIC_IPRn, priority of interrupt number 4n+1")
declareField(peripheralName = NVIC, registerName = NVIC_IPR, fieldName = PRI_N0, bitOffset = 0, bitWidth = 8, dim = 0, dimIncrement = 0, readAccess = true, writeAccess = true, fieldDesc = "For register NVIC_IPRn, priority of interrupt number 4n")

suite "Regression of field access of dimensioned register":
  test "field read of dimensioned register SHOULD compile":
    check compiles NVIC.NVIC_IPR(123).read().PRI_N3(3'u32)
  test "all declared fields SHOULD allow rmw":
    check compiles NVIC.NVIC_IPR(123).read().PRI_N3(3'u32).PRI_N2(2'u32).PRI_N1(1'u32).PRI_N0(0'u32).write()
  test "rmw of dimensioned register SHOULD work":
    const dimRegAddr = 0xE000E100'u32 + 0x300 + 123 * 4
    mockInitRegs()
    mockRegPreset(dimRegAddr, 0xFFFF_FFFF'u32)
    NVIC.NVIC_IPR(123).read().PRI_N3(3'u32).write()
    check mockRegRead(dimRegAddr) == 0x03FF_FFFF

  test "rmw of dimensioned field in dimensioned register SHOULD compile":
    check compiles NVIC.NVIC_ISER(0).SETENA(17, 1)

  test "rmw of dimensioned field in dimensioned register SHOULD work":
    const dimRegAddr = 0xE000E100'u32 + 0x0 + 0 * 16
    mockInitRegs()
    mockRegPreset(dimRegAddr, 0xFFFF_FFFF'u32)
    NVIC.NVIC_ISER(0).read().SETENA(17, 0).write()
    check mockRegRead(dimRegAddr) == 0xFFFD_FFFF'u32
    mockRegPreset(dimRegAddr, 0'u32)
    NVIC.NVIC_ISER(0).read().SETENA(17, 1).write()
    check mockRegRead(dimRegAddr) == 0x0002_0000'u32

  test "rmw of chained dimensioned fields in dimensioned register SHOULD work":
    const dimRegAddr = 0xE000E100'u32 + 0x0 + 0 * 16
    mockInitRegs()
    mockRegPreset(dimRegAddr, 0xFFFF_FFFF'u32)
    NVIC.NVIC_ISER(0).read().SETENA(17, 0).SETENA(31, 0).write()
    check mockRegRead(dimRegAddr) == 0x7FFD_FFFF'u32
    mockRegPreset(dimRegAddr, 0'u32)
    NVIC.NVIC_ISER(0).read().SETENA(17, 1).SETENA(31, 1).write()
    check mockRegRead(dimRegAddr) == 0x8002_0000'u32

declarePeripheral(peripheralName = RTC1, baseAddress = 0x40011000'u32, peripheralDesc = "Real time counter 0")
declareRegister(peripheralName = RTC1, registerName = CC, addressOffset = 0x00000540'u32, dim = 4, dimIncrement = 4, readAccess = true, writeAccess = true, registerDesc = "Description collection: Compare register n")
declareField(peripheralName = RTC1, registerName = CC, fieldName = COMPARE, bitOffset = 0, bitWidth = 24, dim = 0, dimIncrement = 0, readAccess = true, writeAccess = true, fieldDesc = "Compare value")

suite "Regression of register access":
  test "write to a dimensioned register SHOULD compile":
    check compiles RTC1.CC(0).COMPARE(0'u32)
