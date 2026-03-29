#!fmt: off

import unittest2
import volatile_mock

# File under test:
import minisvd2nimpkg/metagenerator
# NOTE: the patchFile directive in config.nims replaces std/volatile
# with volatile_mock which enables the mock*() procs used in this file

# DIMPERIPH.DREG is a 4-element read-write dimensioned register
declarePeripheral(peripheralName = DIMPERIPH, baseAddress = 0xF002_0000'u32, peripheralDesc = "Test peripheral with dimensioned registers")
declareRegister(peripheralName = DIMPERIPH, registerName = DREG, addressOffset = 0x00'u32, dim = 4, dimIncrement = 4, readAccess = true, writeAccess = true, registerDesc = "Test dimensioned register")

# ROPER.ROREG is a 3-element read-only dimensioned register
declarePeripheral(peripheralName = ROPER, baseAddress = 0xF002_1000'u32, peripheralDesc = "Test peripheral with read-only dim register")
declareRegister(peripheralName = ROPER, registerName = ROREG, addressOffset = 0x00'u32, dim = 3, dimIncrement = 4, readAccess = true, writeAccess = false, registerDesc = "Test read-only dimensioned register")

# WOPER.WOREG is a 3-element write-only dimensioned register
declarePeripheral(peripheralName = WOPER, baseAddress = 0xF002_2000'u32, peripheralDesc = "Test peripheral with write-only dim register")
declareRegister(peripheralName = WOPER, registerName = WOREG, addressOffset = 0x00'u32, dim = 3, dimIncrement = 4, readAccess = false, writeAccess = true, registerDesc = "Test write-only dimensioned register")

suite "Direct peripheral, dim register access":
  # read
  test "Direct peripheral, declareRegister SHOULD provide a symbol for the dim register":
    check compiles(DIMPERIPH.DREG)
  test "Direct peripheral, dim register read at index 0 SHOULD compile":
    check compiles(DIMPERIPH.DREG[0])
  test "Direct peripheral, dim register read at index 0 SHOULD work":
    mockInitRegs()
    mockRegPreset(0xF002_0000'u32, 0x0001_BEEF'u32)
    let v = DIMPERIPH.DREG[0]
    check v.uint32 == 0x0001_BEEF'u32
  test "Direct peripheral, dim register read at index 1 SHOULD work":
    mockInitRegs()
    mockRegPreset(0xF002_0004'u32, 0x0002_BEEF'u32)
    let v = DIMPERIPH.DREG[1]
    check v.uint32 == 0x0002_BEEF'u32
  test "Direct peripheral, dim register read at index 3 SHOULD work":
    mockInitRegs()
    mockRegPreset(0xF002_000C'u32, 0x0003_BEEF'u32)
    let v = DIMPERIPH.DREG[3]
    check v.uint32 == 0x0003_BEEF'u32
  test "Direct peripheral, dim register runtime index read SHOULD work":
    mockInitRegs()
    mockRegPreset(0xF002_0008'u32, 0x0004_BEEF'u32)
    let n = 2'u8
    let v = DIMPERIPH.DREG[n]
    check v.uint32 == 0x0004_BEEF'u32
  test "Direct peripheral, dim register raw read SHOULD yield a distinct type":
    mockInitRegs()
    mockRegPreset(0xF002_0000'u32, 0x0005_BEEF'u32)
    let v = DIMPERIPH.DREG[0]
    check not compiles(v + 1'i32)
  test "Direct peripheral, read from read-only dim register SHOULD work":
    mockInitRegs()
    mockRegPreset(0xF002_1004'u32, 0x8000_0001'u32)
    let v = ROPER.ROREG[1]
    check v.uint32 == 0x8000_0001'u32
  test "Direct peripheral, read from write-only dim register SHOULD NOT compile":
    check not compiles(0 == WOPER.WOREG[0])
  # write
  test "Direct peripheral, dim register write at index 0 SHOULD work":
    mockInitRegs()
    DIMPERIPH.DREG[0] = 0x0001_F00D'u32
    check mockRegRead(0xF002_0000'u32) == 0x0001_F00D'u32
  test "Direct peripheral, dim register write at index 2 SHOULD work":
    mockInitRegs()
    DIMPERIPH.DREG[2] = 0x0002_F00D'u32
    check mockRegRead(0xF002_0008'u32) == 0x0002_F00D'u32
  test "Direct peripheral, dim register runtime index write SHOULD work":
    mockInitRegs()
    let n = 3'u8
    DIMPERIPH.DREG[n] = 0x0003_F00D'u32
    check mockRegRead(0xF002_000C'u32) == 0x0003_F00D'u32
  test "Direct peripheral, write dim register's distinct type SHOULD work":
    mockInitRegs()
    mockRegPreset(0xF002_0004'u32, 0x0001_FFFF'u32)
    let v = DIMPERIPH.DREG[1]
    mockRegPreset(0xF002_0004'u32, 0'u32)
    DIMPERIPH.DREG[1] = v
    check mockRegRead(0xF002_0004'u32) == 0x0001_FFFF'u32
  test "Direct peripheral, write unsupported type to dim register SHOULD NOT compile":
    check not compiles(DIMPERIPH.DREG[0] = 0'i32)
  test "Direct peripheral, write to the read-only dim register SHOULD NOT compile":
    check not compiles(ROPER.ROREG[0] = 0x1234'u32)
  test "Direct peripheral, write to the write-only dim register SHOULD work":
    mockInitRegs()
    WOPER.WOREG[0] = 0x1FF'u32
    check mockRegRead(0xF002_2000'u32) == 0x1FF'u32

suite "Indirect peripheral, dim register access":
  test "Indirect peripheral, dim register read SHOULD compile":
    let p = DIMPERIPH
    check compiles(p.DREG[0])
  test "Indirect peripheral, dim register read at index 0 SHOULD work":
    let p = DIMPERIPH
    mockInitRegs()
    mockRegPreset(0xF002_0000'u32, 0x0006_BEEF'u32)
    let v = p.DREG[0]
    check v.uint32 == 0x0006_BEEF'u32
  test "Indirect peripheral, dim register read at index 3 SHOULD work":
    let p = DIMPERIPH
    mockInitRegs()
    mockRegPreset(0xF002_000C'u32, 0x0007_BEEF'u32)
    let v = p.DREG[3]
    check v.uint32 == 0x0007_BEEF'u32
  test "Indirect peripheral, dim register runtime index read SHOULD work":
    let p = DIMPERIPH
    mockInitRegs()
    mockRegPreset(0xF002_0008'u32, 0x0008_BEEF'u32)
    let n = 2'u8
    let v = p.DREG[n]
    check v.uint32 == 0x0008_BEEF'u32
  test "Indirect peripheral, write to the dim register at index 1 SHOULD work":
    let p = DIMPERIPH
    mockInitRegs()
    p.DREG[1] = 0x0002_F00D'u32
    check mockRegRead(0xF002_0004'u32) == 0x0002_F00D'u32
  test "Indirect peripheral, write dim register's distinct type SHOULD work":
    let p = DIMPERIPH
    mockInitRegs()
    mockRegPreset(0xF002_0008'u32, 0x0003_FFFF'u32)
    let v = p.DREG[2]
    mockRegPreset(0xF002_0008'u32, 0'u32)
    p.DREG[2] = v
    check mockRegRead(0xF002_0008'u32) == 0x0003_FFFF'u32
  test "Indirect peripheral, write unsupported type to dim register SHOULD NOT compile":
    let p = DIMPERIPH
    check not compiles(p.DREG[0] = 0'i32)
    check not compiles(p.DREG[0] = "wrong")
  test "Indirect peripheral, read from read-only dim register SHOULD work":
    let p = ROPER
    mockInitRegs()
    mockRegPreset(0xF002_1008'u32, 0x8000_0002'u32)
    let v = p.ROREG[2]
    check v.uint32 == 0x8000_0002'u32
  test "Indirect peripheral, read from write-only dim register SHOULD NOT compile":
    let p = WOPER
    check not compiles(p.WOREG[0])
  test "Indirect peripheral, write to the read-only dim register SHOULD NOT compile":
    let p = ROPER
    check not compiles(p.ROREG[0] = 0x1234'u32)
  test "Indirect peripheral, write to the write-only dim register SHOULD work":
    let p = WOPER
    mockInitRegs()
    p.WOREG[1] = 0x1EE'u32
    check mockRegRead(0xF002_2004'u32) == 0x1EE'u32

suite "Indirect dim register, register access":
  test "Indirect dim register, read at index 0 SHOULD compile":
    let r = DIMPERIPH.DREG
    check compiles(r[0])
  test "Indirect dim register, read at index 0 SHOULD work":
    let r = DIMPERIPH.DREG
    mockInitRegs()
    mockRegPreset(0xF002_0000'u32, 0x0009_BEEF'u32)
    check r[0].uint32 == 0x0009_BEEF'u32
  test "Indirect dim register, read at index 2 SHOULD work":
    let r = DIMPERIPH.DREG
    mockInitRegs()
    mockRegPreset(0xF002_0008'u32, 0x000A_BEEF'u32)
    check r[2].uint32 == 0x000A_BEEF'u32
  test "Indirect dim register, runtime index read SHOULD work":
    let r = DIMPERIPH.DREG
    mockInitRegs()
    mockRegPreset(0xF002_000C'u32, 0x000B_BEEF'u32)
    let n = 3'u8
    check r[n].uint32 == 0x000B_BEEF'u32
  test "Indirect dim register, raw read SHOULD yield a distinct type":
    let r = DIMPERIPH.DREG
    mockInitRegs()
    mockRegPreset(0xF002_0000'u32, 0x000C_BEEF'u32)
    let v = r[0]
    check not compiles(v + 1'i32)
  test "Indirect dim register, write at index 1 SHOULD work":
    let r = DIMPERIPH.DREG
    mockInitRegs()
    r[1] = 0x0004_F00D'u32
    check mockRegRead(0xF002_0004'u32) == 0x0004_F00D'u32
  test "Indirect dim register, write at index 3 SHOULD work":
    let r = DIMPERIPH.DREG
    mockInitRegs()
    r[3] = 0x0005_F00D'u32
    check mockRegRead(0xF002_000C'u32) == 0x0005_F00D'u32
  test "Indirect dim register, runtime index write SHOULD work":
    let r = DIMPERIPH.DREG
    mockInitRegs()
    let n = 2'u8
    r[n] = 0x0006_F00D'u32
    check mockRegRead(0xF002_0008'u32) == 0x0006_F00D'u32
  test "Indirect dim register, write the register's distinct type SHOULD work":
    let r = DIMPERIPH.DREG
    mockInitRegs()
    mockRegPreset(0xF002_0004'u32, 0x0005_FFFF'u32)
    let v = r[1]
    mockRegPreset(0xF002_0004'u32, 0'u32)
    r[1] = v
    check mockRegRead(0xF002_0004'u32) == 0x0005_FFFF'u32
  test "Indirect dim register, read from read-only register SHOULD work":
    let r = ROPER.ROREG
    mockInitRegs()
    mockRegPreset(0xF002_1000'u32, 0x8000_0003'u32)
    let v = r[0]
    check v.uint32 == 0x8000_0003'u32
  test "Indirect dim register, read from write-only register SHOULD NOT compile":
    let r = WOPER.WOREG
    check not compiles(r[0])
  test "Indirect dim register, write unsupported type to the register SHOULD NOT compile":
    let r = DIMPERIPH.DREG
    check not compiles(r[0] = 0'i32)
    check not compiles(r[0] = "wrong")
  test "Indirect dim register, write to the read-only register SHOULD NOT compile":
    let r = ROPER.ROREG
    check not compiles(r[0] = 0x5678'u32)
  test "Indirect dim register, write to the write-only register SHOULD work":
    let r = WOPER.WOREG
    mockInitRegs()
    r[2] = 0x1CC'u32
    check mockRegRead(0xF002_2008'u32) == 0x1CC'u32


