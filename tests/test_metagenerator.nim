## Copyright 2026 Dean Hall See LICENSE for details
##
## Note: std/volatile is patched to use volatile_mock in config.nims.
##
#!fmt: off

import unittest2
import volatile_mock

# File under test:
import minisvd2nimpkg/metagenerator
# NOTE: the patchFile directive in config.nims replaces std/volatile
# with volatile_mock which enables the mock*() procs used in this file

# PERIPH.REG is read/write
declarePeripheral(peripheralName = PERIPH, baseAddress = 0xF000F000'u32, peripheralDesc = "Test peripheral")
declareRegister(peripheralName = PERIPH, registerName = REG, addressOffset = 0x20'u32, readAccess = true, writeAccess = true, registerDesc = "Test register")
declareField(peripheralName = PERIPH, registerName = REG, fieldName = FIELD_NM, bitOffset = 4, bitWidth = 4, dim = 0, dimIncrement = 0, readAccess = true, writeAccess = true, fieldDesc = "Test field")
declareField(peripheralName = PERIPH, registerName = REG, fieldName = FIELD_XX, bitOffset = 16, bitWidth = 4, dim = 0, dimIncrement = 0, readAccess = true, writeAccess = true, fieldDesc = "Test field")
declareField(peripheralName = PERIPH, registerName = REG, fieldName = FIELD_RO, bitOffset = 31, bitWidth = 1, dim = 0, dimIncrement = 0, readAccess = true, writeAccess = false, fieldDesc = "Test field")
declareRegister(peripheralName = PERIPH, registerName = REG_OTHER, addressOffset = 0x40'u32, readAccess = true, writeAccess = true, registerDesc = "Test register")

# SYSTICK.SYST_CALIB is read-only
declarePeripheral(peripheralName = SYSTICK, baseAddress = 0xE000E010'u32, peripheralDesc = "SysTick Timer")
declareRegister(peripheralName = SYSTICK, registerName = SYST_CALIB, addressOffset = 0xC'u32, readAccess = true, writeAccess = false, registerDesc = "SysTick Calibration value Register reads the calibration value and parameters for SysTick")
declareField(peripheralName = SYSTICK, registerName = SYST_CALIB, fieldName = NOREF, bitOffset = 31, bitWidth = 1, dim = 0, dimIncrement = 0, readAccess = true, writeAccess = false, fieldDesc = "Indicates whether the IMPLEMENTATION DEFINED reference clock is implemented")
declareField(peripheralName = SYSTICK, registerName = SYST_CALIB, fieldName = SKEW, bitOffset = 30, bitWidth = 1, dim = 0, dimIncrement = 0, readAccess = true, writeAccess = false, fieldDesc = "Indicates whether the 10ms calibration value is exact")
declareField(peripheralName = SYSTICK, registerName = SYST_CALIB, fieldName = TENMS, bitOffset = 0, bitWidth = 24, dim = 0, dimIncrement = 0, readAccess = true, writeAccess = false, fieldDesc = "Optionally, holds a reload value to be used for 10ms (100Hz) timing, subject to system clock skew errors")

# SIG.STIR is write-only
declarePeripheral(peripheralName = SIG, baseAddress = 0xE000EF00'u32, peripheralDesc = "Software Interrupt Generation")
declareRegister(peripheralName = SIG, registerName = STIR, addressOffset = 0x0'u32, readAccess = false, writeAccess = true, registerDesc = "Software Triggered Interrupt Register provides a mechanism for software to generate an interrupt")
declareField(peripheralName = SIG, registerName = STIR, fieldName = INTID, bitOffset = 0, bitWidth = 9, dim = 0, dimIncrement = 0, readAccess = false, writeAccess = true, fieldDesc = "Indicates the interrupt to be triggered")

# make sure our mock tools work as expected
suite "volatile_mock tests":
  test "mockRegRead SHOULD error if the register value has not been written":
    expect KeyError:
      discard mockRegRead(0x1000'u32)
  test "register preset and read SHOULD work":
    mockInitRegs()
    mockRegPreset(0xF000A000'u32, 0x000A_0000'u32)
    check mockRegRead(0xF000A000'u32) == 0x000A_0000'u32
  test "register preset and volatileLoad SHOULD work":
    mockInitRegs()
    mockRegPreset(0xF000B000'u32, 0x000B_0042'u32)
    check volatileLoad(cast[ptr uint32](0xF000B000)) == 0x000B_0042'u32
  test "volatileStore and mockRegRead SHOULD work":
    volatileStore(cast[ptr uint32](0xF000C000), 0x000C_C000'u32)
    check mockRegRead(0xF000C000'u32) == 0x000C_C000'u32
  test "volatileStore and volatileLoad SHOULD work":
    volatileStore(cast[ptr uint32](0xF000D000), 0x000D_D000'u32)
    check volatileLoad(cast[ptr uint32](0xF000D000)) == 0x000D_D000'u32

# TODO: make sure our desktop equivalents of the ARM instructions work as expected

suite "Peripheral tests":
  test "Direct peripheral, declarePeripheral SHOULD provide a symbol for the peripheral":
    check compiles(PERIPH)
  test "Direct peripheral, peripheral SHOULD NOT allow assignment":
    check not compiles(PERIPH = 42'u32)

suite "Direct peripheral, register access":
  # read
  test "Direct peripheral, declareRegister SHOULD provide a symbol for the register":
    check compiles(PERIPH.REG)
  test "Direct peripheral, read SHOULD compile":
    check compiles(PERIPH.REG.read())
  test "Direct peripheral, read SHOULD work":
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0x0001_BEEF'u32)
    let v = PERIPH.REG.read()
    check v.uint32 == 0x0001_BEEF'u32
  test "Direct peripheral, raw read SHOULD yield a distinct type":
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0x0002_BEEF'u32)
    let v = PERIPH.REG.read()
    check not compiles(v + 1'i32)
  test "Direct peripheral, read from a read-only register SHOULD work":
    mockInitRegs()
    mockRegPreset(0xE000E01C'u32, 0x8000_0001'u32)
    let v = SYSTICK.SYST_CALIB.read()
    check v.uint32 == 0x8000_0001'u32
  test "Direct peripheral, read from the write-only register SHOULD NOT compile":
    check not compiles(0 == SIG.STIR.read())
  # write
  test "Direct peripheral, write to the register SHOULD work":
    mockInitRegs()
    PERIPH.REG.write(0x0001_F00D'u32)
    check mockRegRead(0xF000F020'u32) == 0x0001_F00D'u32
  test "Direct peripheral, write the register's distinct type SHOULD compile":
    let v = PERIPH.REG.read()
    check compiles (PERIPH.REG.write(v); )
  test "Direct peripheral, read then write the register's distinct type SHOULD work":
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0x0001_FFFF'u32)
    let v = PERIPH.REG.read()
    mockRegPreset(0xF000F020'u32, 0'u32)
    PERIPH.REG.write(v)
    check mockRegRead(0xF000F020'u32) == 0x0001_FFFF'u32
  test "Direct peripheral, write another register's distinct type SHOULD NOT compile":
    mockInitRegs()
    mockRegPreset(0xF000F040'u32, 0'u32)
    let v = PERIPH.REG_OTHER.read()
    check not compiles(PERIPH.REG.write(v))
    discard v
  test "Direct peripheral, write unsupported type to the register SHOULD NOT compile":
    check not compiles(PERIPH.REG.write(0'i32))
  test "Direct peripheral, write unsupported type to write-only register SHOULD NOT compile":
    check not compiles(SIG.STIR.write(0'i32))
  test "Direct peripheral, write type that is too large to write-only register SHOULD NOT compile":
    check not compiles(SIG.STIR.write(0'u64))
  test "Direct peripheral, write to the read-only register SHOULD NOT compile":
    check not compiles(SYSTICK.SYST_CALIB.write(0x1234'u32))
  test "Direct peripheral, write to the write-only register SHOULD work":
    mockInitRegs()
    SIG.STIR.write(0x1FF'u32)
    check mockRegRead(0xE000EF00'u32) == 0x1FF'u32

suite "Direct peripheral, field access":
  test "Direct peripheral, declareField SHOULD provide a symbol for the field":
    check compiles PERIPH.REG.FIELD_NM(0)
  test "Direct peripheral, field read SHOULD compile":
    check compiles(PERIPH.REG.read().FIELD_NM)
  test "Direct peripheral, field read SHOULD work":
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0x1234_5678'u32)
    let f = PERIPH.REG.read().FIELD_NM.uint32
    check f == 0x7
  test "Direct peripheral, field write (field=) SHOULD compile":
    check compiles (PERIPH.REG.FIELD_NM(0xC'u32); )
  test "Direct peripheral, field write (field=) SHOULD overwrite the whole register":
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0xFFFF_FFFF'u32)
    PERIPH.REG.FIELD_NM(0xC'u32)
    check mockRegRead(0xF000F020'u32) == 0xC0'u32
  test "Direct peripheral, field rmw SHOULD only change the bits of the field":
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0xFFFF_FFFF'u32)
    PERIPH.REG.read().FIELD_NM(5).write
    check mockRegRead(0xF000F020'u32) == 0xFFFF_FF5F'u32
  test "Direct peripheral, two-field rmw SHOULD change the bits of both fields an no others":
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0xFFFF_FFFF'u32)
    PERIPH.REG.read()
          .FIELD_NM(5)
          .FIELD_XX(10)
          .write
    check mockRegRead(0xF000F020'u32) == 0xFFFA_FF5F'u32
  test "Direct peripheral, read-only field rmw SHOULD NOT compile":
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0xFFFF_FFFF'u32)
    check not compiles PERIPH.REG.read()
                             .FIELD_NM(5)
                             .FIELD_XX(10)
                             .FIELD_RO(1)
                             .write()
  test "Direct peripheral, read from write-only field SHOULD NOT compile":
    check not compiles(0 == SIG.STIR.read().INTID)
  test "Direct peripheral, write to read-only field SHOULD NOT compile":
    check not compiles(SYSTICK.SYST_CALIB.NOREF.write(1'u32))
  test "Direct peripheral, write to write-only field SHOULD work":
    mockInitRegs()
    mockRegPreset(0xE000EF00'u32, 0xFFFF_FFFF'u32)
    SIG.STIR.INTID(0x123'u32)
    check mockRegRead(0xE000EF00'u32) == 0x0000_0123'u32
  test "Direct peripheral, read the various fields SHOULD return the proper bit values":
    mockInitRegs()
    mockRegPreset(0xE000E01C'u32, 0x800C_0001'u32)
    check SYSTICK.SYST_CALIB.read().NOREF.uint32 == 1
    check SYSTICK.SYST_CALIB.read().SKEW.uint32 == 0
    check SYSTICK.SYST_CALIB.read().TENMS.uint32 == 0xC0001

suite "Indirect peripheral, register access":
  test "Indirect peripheral, register read SHOULD compile":
    let p = PERIPH
    check compiles p.REG.read()
  test "Indirect peripheral, register read SHOULD work":
    let p = PERIPH
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0x0003_BEEF'u32)
    let v = p.REG.read()
    check v.uint32 == 0x0003_BEEF'u32
  test "Indirect peripheral, raw read SHOULD yield a distinct type":
    let p = PERIPH
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0x0004_BEEF'u32)
    let v = p.REG.read()
    check not compiles(v + 1'i32)
  test "Indirect peripheral, read from read-only register SHOULD work":
    let p = SYSTICK
    mockInitRegs()
    mockRegPreset(0xE000E01C'u32, 0x8000_0002'u32)
    let v = p.SYST_CALIB.read()
    check v.uint32 == 0x8000_0002'u32
  test "Indirect peripheral, read from write-only register SHOULD NOT compile":
    let p = SIG
    check not compiles(p.STIR.read())
  test "Indirect peripheral, write to the register SHOULD work":
    let p = PERIPH
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0xFFFF'u32)
    p.REG.write(0x0002_F00D'u32)
    check mockRegRead(0xF000F020'u32) == 0x0002_F00D'u32
  test "Indirect peripheral, write the register's distinct type SHOULD compile":
    let p = PERIPH
    let v = p.REG.read()
    check compiles (p.REG.write(v); )
  test "Indirect peripheral, write the register's distinct type SHOULD work":
    let p = PERIPH
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0x0001_FFFF'u32)
    let v = p.REG.read()
    mockRegPreset(0xF000F020'u32, 0'u32)
    p.REG.write(v)
    check mockRegRead(0xF000F020'u32) == 0x0001_FFFF'u32
  test "Indirect peripheral, write unsupported type to the register SHOULD NOT compile":
    let p = PERIPH
    check not compiles(p.REG.read() = 0'i32)
    check not compiles(p.REG.read() = "wrong")
  test "Indirect peripheral, write to the read-only register SHOULD NOT compile":
    let p = SYSTICK
    check not compiles(p.SYST_CALIB.write(0x1234'u32))
  test "Indirect peripheral, write to the write-only register SHOULD work":
    let p = SIG
    mockInitRegs()
    mockRegPreset(0xE000EF00'u32, 0xFFFF_FFFF'u32)
    p.STIR.write(0x1EE'u32)
    check mockRegRead(0xE000EF00'u32) == 0x1EE'u32
  test "Indirect peripheral, write another register's distinct type SHOULD NOT compile":
    let p = PERIPH
    mockInitRegs()
    mockRegPreset(0xF000F040'u32, 0'u32)
    let v = p.REG_OTHER.read()
    check not compiles(p.REG.write(v))
  test "Indirect peripheral, read then write the register as a uint32 SHOULD work":
    let p = PERIPH
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0x0002_FFFF'u32)
    var r = p.REG.read()
    mockRegPreset(0xF000F020'u32, 0'u32)
    p.REG.write(r)
    check mockRegRead(0xF000F020'u32) == 0x0002_FFFF'u32

suite "Indirect peripheral, field access":
  test "Indirect peripheral, declareField SHOULD provide a symbol for the field":
    let p = PERIPH
    check compiles(p.REG.read().FIELD_NM)
  test "Indirect peripheral, field read SHOULD compile":
    let p = PERIPH
    var f = p.REG.read().FIELD_NM
    discard f
  test "Indirect peripheral, read SHOULD work":
    let p = PERIPH
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0x1234_5678'u32)
    var f = p.REG.read().FIELD_NM
    check f.uint32 == 0x7
  test "Indirect peripheral, write SHOULD overwrite the whole register":
    let p = PERIPH
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0xFFFF_FFFF'u32)
    p.REG.FIELD_NM(0x8'u32)
    check mockRegRead(0xF000F020'u32) == 0x80'u32
  test "Indirect peripheral, rmw the field SHOULD only change the bits of the field":
    let p = PERIPH
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0xFFFF_FFFF'u32)
    p.REG.read().FIELD_NM(5).write
    check mockRegRead(0xF000F020'u32) == 0xFFFF_FF5F'u32
  test "Indirect peripheral, rmw two fields SHOULD change the bits of both fields an no others":
    let p = PERIPH
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0xFFFF_FFFF'u32)
    p.REG.read().FIELD_NM(5).FIELD_XX(10).write
    check mockRegRead(0xF000F020'u32) == 0xFFFA_FF5F'u32
  test "Indirect peripheral, rmw with one read-only field SHOULD NOT compile":
    let p = PERIPH
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0xFFFF_FFFF'u32)
    check not compiles p.REG
                        .FIELD_NM(5)
                        .FIELD_XX(10)
                        .FIELD_RO(1)
                        .write
  test "Indirect peripheral, read from read-only field SHOULD work":
    let p = SYSTICK
    mockInitRegs()
    mockRegPreset(0xE000E01C'u32, 0x4000_0000'u32)
    let f = p.SYST_CALIB.read().SKEW
    check f.uint32 == 1
  test "Indirect peripheral, read from write-only field SHOULD NOT compile":
    let p = SIG
    check not compiles(p.STIR.read().INTID)
  test "Indirect peripheral, write to read-only field SHOULD NOT compile":
    let p = SYSTICK
    check not compiles(p.SYST_CALIB.NOREF(1'u32))
  test "Indirect peripheral, write to write-only field SHOULD work":
    let p = SIG
    mockInitRegs()
    mockRegPreset(0xE000EF00'u32, 0xFFFF_FFFF'u32)
    p.STIR.INTID(0x1DD'u32)
    check mockRegRead(0xE000EF00'u32) == 0x0000_01DD'u32
  test "Indirect peripheral, read the various fields SHOULD return the proper bit values":
    mockInitRegs()
    mockRegPreset(0xE000E01C'u32, 0x7FF3_FFFE'u32)
    let p = SYSTICK
    check p.SYST_CALIB.read().NOREF.uint32 == 0
    check p.SYST_CALIB.read().SKEW.uint32 == 1
    check p.SYST_CALIB.read().TENMS.uint32 == 0xF3FFFE

suite "Indirect register, register access":
  test "Indirect register,read SHOULD compile":
    let r = PERIPH.REG
    check compiles(r.read())
  test "Indirect register, read SHOULD work":
    let r = PERIPH.REG
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0x0004_BEEF'u32)
    check r.read().uint32 == 0x0004_BEEF'u32
  test "Indirect register, raw read SHOULD yield a distinct type":
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0x0004_BEEF'u32)
    let r = PERIPH.REG.read()
    check not compiles(r + 1'i32)
  test "Indirect register, write to the register SHOULD work":
    var r = PERIPH.REG
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0xFFFF'u32)
    r.write(0x0003_F00D'u32)
    check mockRegRead(0xF000F020'u32) == 0x0003_F00D'u32
  test "Indirect register, write the register's distinct type SHOULD compile":
    var r = PERIPH.REG
    let v = r.read()
    check compiles (r.write(v); )
  test "Indirect register, write the register's distinct type SHOULD work":
    var r = PERIPH.REG
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0x0003_FFFF'u32)
    let v = r.read()
    mockRegPreset(0xF000F020'u32, 0'u32)
    r.write(v)
    check mockRegRead(0xF000F020'u32) == 0x0003_FFFF'u32
  test "Indirect register, write another register's distinct type SHOULD NOT compile":
    let r = PERIPH.REG
    mockInitRegs()
    mockRegPreset(0xF000F040'u32, 0'u32)
    let v = PERIPH.REG_OTHER.read()
    check not compiles(r = v)
  test "Indirect register, read then write the register's distinct type SHOULD work":
    let r = PERIPH.REG
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0x0004_FFFF'u32)
    let v = r.read()
    mockRegPreset(0xF000F020'u32, 0'u32)
    r.write(v)
    check mockRegRead(0xF000F020'u32) == 0x0004_FFFF'u32
  test "Indirect register, read from read-only register SHOULD work":
    let r = SYSTICK.SYST_CALIB
    mockInitRegs()
    mockRegPreset(0xE000E01C'u32, 0x8000_0003'u32)
    let v = r.read()
    check v.uint32 == 0x8000_0003'u32
  test "Indirect register, read from write-only register SHOULD NOT compile":
    let r = SIG.STIR
    check not compiles(r.read())
  test "Indirect register, write unsupported type to the register SHOULD NOT compile":
    let r = PERIPH.REG
    check not compiles(r.write(0'i32))
    check not compiles(r.write("wrong"))
  test "Indirect register, write to the read-only register SHOULD NOT compile":
    let r = SYSTICK.SYST_CALIB
    check not compiles(r.write(0x5678'u32))
  test "Indirect register, write to the write-only register SHOULD work":
    var r = SIG.STIR
    mockInitRegs()
    mockRegPreset(0xE000EF00'u32, 0'u32)
    r.write(0x1CC'u32)
    check mockRegRead(0xE000EF00'u32) == 0x1CC'u32

suite "Indirect register, field access":
  test "Indirect register, declareField SHOULD provide a symbol for the field":
    let r = PERIPH.REG
    check compiles r.FIELD_NM(0)
  test "Indirect register, field read SHOULD compile":
    let r = PERIPH.REG
    check compiles(r.read().FIELD_NM)
  test "Indirect register, field read SHOULD work":
    let r = PERIPH.REG
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0x1234_ABCD'u32)
    let v = r.read().FIELD_NM
    check v.uint32 == 0xC'u32
  test "Indirect register, field write (field=) SHOULD overwrite the whole register":
    let r = PERIPH.REG
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0xFFFF_FFFF'u32)
    r.FIELD_NM(0xC'u32)
    check mockRegRead(0xF000F020'u32) == 0xC0'u32
  test "Indirect register, rmw the field SHOULD only change the bits of the field":
    let r = PERIPH.REG
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0xFFFF_FFFF'u32)
    r.read().FIELD_NM(5).write
    check mockRegRead(0xF000F020'u32) == 0xFFFF_FF5F'u32
  test "Indirect register, rmw two fields SHOULD change the bits of both fields an no others":
    let r = PERIPH.REG
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0xFFFF_FFFF'u32)
    r.read().FIELD_NM(5).FIELD_XX(10).write
    check mockRegRead(0xF000F020'u32) == 0xFFFA_FF5F'u32
  test "Indirect register, rmw with one read-only field SHOULD NOT compile":
    let r = PERIPH.REG
    mockInitRegs()
    mockRegPreset(0xF000F020'u32, 0xFFFF_FFFF'u32)
    check not compiles r.read().FIELD_NM(5).FIELD_XX(10).FIELD_RO(1).write
  test "Indirect register, read from read-only field SHOULD work":
    let r = SYSTICK.SYST_CALIB
    mockInitRegs()
    mockRegPreset(0xE000E01C'u32, 0x8000_0000'u32)
    let f = r.read().NOREF
    check f.uint32 == 1
  test "Indirect register, read from write-only field SHOULD NOT compile":
    let r = SIG.STIR
    check not compiles(r.read().INTID)
  test "Indirect register, write to read-only field SHOULD NOT compile":
    let r = SYSTICK.SYST_CALIB
    check not compiles(r.NOREF = 1'u32)
  test "Indirect register, write to write-only field SHOULD work":
    var r = SIG.STIR
    mockInitRegs()
    mockRegPreset(0xE000EF00'u32, 0xFFFF_FFFF'u32)
    r.INTID(0x1BB'u32)
    check mockRegRead(0xE000EF00'u32) == 0x0000_01BB'u32







