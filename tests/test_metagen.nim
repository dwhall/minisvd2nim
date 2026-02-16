# File under test:
include minisvd2nimpkg/metagenerator

import unittest2

declarePeripheral(peripheralName = CRC, baseAddress = 0x40023000'u32, peripheralDesc = "Cryptographic processor")
declareRegister(peripheralName = CRC, registerName = IDR, addressOffset = 0x4'u32, readAccess = true, writeAccess = true, registerDesc = "Independent Data register")
declareField(peripheralName = CRC, registerName = IDR, fieldName = IDRF, bitOffset = 0, bitWidth = 8, readAccess = true, writeAccess = true, fieldDesc = "Independent Data register")

suite "Test the metagenerator.":

  test "declarePeripheral SHOULD give access to a peripheral":
    check compiles CRC
    let p = CRC
    check typeof(p) is CRCBase

  test "declareRegister SHOULD give access to a register":
    check compiles CRC.IDR
    let regAddress = cast[uint32](CRC_IDR)
    check regAddress == 0x40023004'u32

  test "declareField SHOULD give access to a field":
    check compiles CRC.IDR.IDRF
