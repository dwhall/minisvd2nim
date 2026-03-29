#!fmt: off

import unittest2
import volatile_mock

# File under test:
import minisvd2nimpkg/metagenerator
# NOTE: the patchFile directive in config.nims replaces std/volatile
# with volatile_mock which enables the mock*() procs used in this file

# DFPER.DREG has a 4-element read-write dimensioned field DFLD
# DFLD[i] occupies bits [(i*4)+3 : i*4], each 4 bits wide
declarePeripheral(peripheralName = DFPER, baseAddress = 0xF003_0000'u32, peripheralDesc = "Test peripheral with dimensioned fields")
declareRegister(peripheralName = DFPER, registerName = DREG, addressOffset = 0x00'u32, readAccess = true, writeAccess = true, registerDesc = "Test register with dimensioned field")
declareField(peripheralName = DFPER, registerName = DREG, fieldName = DFLD, bitOffset = 0, bitWidth = 4, dim = 4, dimIncrement = 4, readAccess = true, writeAccess = true, fieldDesc = "Test dimensioned field")

# ROFPER.ROREG has a 3-element read-only dimensioned field ROFLD
# ROFLD[i] occupies bits [(i*8)+7 : i*8], each 8 bits wide
declarePeripheral(peripheralName = ROFPER, baseAddress = 0xF003_1000'u32, peripheralDesc = "Test peripheral with read-only dim field")
declareRegister(peripheralName = ROFPER, registerName = ROREG, addressOffset = 0x00'u32, readAccess = true, writeAccess = true, registerDesc = "Test register with read-only dim field")
declareField(peripheralName = ROFPER, registerName = ROREG, fieldName = ROFLD, bitOffset = 0, bitWidth = 8, dim = 3, dimIncrement = 8, readAccess = true, writeAccess = false, fieldDesc = "Test read-only dimensioned field")

# WOFPER.WOREG has a 2-element write-only dimensioned field WOFLD
# WOFLD[i] occupies bits [(i*8)+7 : i*8], each 8 bits wide
declarePeripheral(peripheralName = WOFPER, baseAddress = 0xF003_2000'u32, peripheralDesc = "Test peripheral with write-only dim field")
declareRegister(peripheralName = WOFPER, registerName = WOREG, addressOffset = 0x00'u32, readAccess = true, writeAccess = true, registerDesc = "Test register with write-only dim field")
declareField(peripheralName = WOFPER, registerName = WOREG, fieldName = WOFLD, bitOffset = 0, bitWidth = 8, dim = 2, dimIncrement = 8, readAccess = false, writeAccess = true, fieldDesc = "Test write-only dimensioned field")

suite "Direct register, dim field access":
  # read
  test "Direct register, declareField SHOULD provide a symbol for the dim field":
    check compiles(DFPER.DREG.DFLD)
  test "Direct register, dim field read at index 0 SHOULD compile":
    check compiles(DFPER.DREG.DFLD[0])
  test "Direct register, dim field read at index 0 SHOULD work":
    mockInitRegs()
    mockRegPreset(0xF003_0000'u32, 0x0000_DCBA'u32)
    let v = DFPER.DREG.DFLD[0]
    check v == 0xA'u32
  test "Direct register, dim field read at index 1 SHOULD work":
    mockInitRegs()
    mockRegPreset(0xF003_0000'u32, 0x0000_DCBA'u32)
    let v = DFPER.DREG.DFLD[1]
    check v == 0xB'u32
  test "Direct register, dim field read at index 3 SHOULD work":
    mockInitRegs()
    mockRegPreset(0xF003_0000'u32, 0x0000_DCBA'u32)
    let v = DFPER.DREG.DFLD[3]
    check v == 0xD'u32
  test "Direct register, dim field runtime index read SHOULD work":
    mockInitRegs()
    mockRegPreset(0xF003_0000'u32, 0x0000_DCBA'u32)
    let n = 2'u8
    let v = DFPER.DREG.DFLD[n]
    check v == 0xC'u32
  test "Direct register, read from read-only dim field SHOULD work":
    mockInitRegs()
    mockRegPreset(0xF003_1000'u32, 0x00AB_CD12'u32)
    let v = ROFPER.ROREG.ROFLD[0]
    check v == 0x12'u32
  test "Direct register, read from write-only dim field SHOULD NOT compile":
    check not compiles(WOFPER.WOREG.WOFLD[0])
  # write
  test "Direct register, dim field write at index 0 SHOULD work":
    mockInitRegs()
    DFPER.DREG.DFLD[0] = 0x5'u32
    check mockRegRead(0xF003_0000'u32) == 0x0000_0005'u32
  test "Direct register, dim field write at index 1 SHOULD work":
    mockInitRegs()
    DFPER.DREG.DFLD[1] = 0x7'u32
    check mockRegRead(0xF003_0000'u32) == 0x0000_0070'u32
  test "Direct register, dim field write at index 3 SHOULD work":
    mockInitRegs()
    DFPER.DREG.DFLD[3] = 0x3'u32
    check mockRegRead(0xF003_0000'u32) == 0x0000_3000'u32
  test "Direct register, dim field runtime index write SHOULD work":
    mockInitRegs()
    let n = 2'u8
    DFPER.DREG.DFLD[n] = 0x6'u32
    check mockRegRead(0xF003_0000'u32) == 0x0000_0600'u32
  test "Direct register, write to read-only dim field SHOULD NOT compile":
    check not compiles(ROFPER.ROREG.ROFLD[0] = 0x12'u32)
  test "Direct register, write to write-only dim field SHOULD work":
    mockInitRegs()
    WOFPER.WOREG.WOFLD[0] = 0xAB'u32
    check mockRegRead(0xF003_2000'u32) == 0x0000_00AB'u32
  test "Direct register, write unsupported type to dim field SHOULD NOT compile":
    check not compiles(DFPER.DREG.DFLD[0] = 0'i32)
    check not compiles(DFPER.DREG.DFLD[0] = "wrong")
  test "Direct register, dim field read at out-of-bounds static index SHOULD NOT compile":
    check not compiles(DFPER.DREG.DFLD[4])
  test "Direct register, dim field write at out-of-bounds static index SHOULD NOT compile":
    check not compiles(DFPER.DREG.DFLD[4] = 0x1'u32)

suite "Indirect register, dim field access":
  test "Indirect register, dim field read SHOULD compile":
    let r = DFPER.DREG
    check compiles(r.DFLD[0])
  test "Indirect register, dim field read at index 0 SHOULD work":
    let r = DFPER.DREG
    mockInitRegs()
    mockRegPreset(0xF003_0000'u32, 0x0000_DCBA'u32)
    let v = r.DFLD[0]
    check v == 0xA'u32
  test "Indirect register, dim field read at index 2 SHOULD work":
    let r = DFPER.DREG
    mockInitRegs()
    mockRegPreset(0xF003_0000'u32, 0x0000_DCBA'u32)
    let v = r.DFLD[2]
    check v == 0xC'u32
  test "Indirect register, dim field runtime index read SHOULD work":
    let r = DFPER.DREG
    mockInitRegs()
    mockRegPreset(0xF003_0000'u32, 0x0000_DCBA'u32)
    let n = 3'u8
    let v = r.DFLD[n]
    check v == 0xD'u32
  test "Indirect register, dim field write at index 0 SHOULD work":
    let r = DFPER.DREG
    mockInitRegs()
    r.DFLD[0] = 0x9'u32
    check mockRegRead(0xF003_0000'u32) == 0x0000_0009'u32
  test "Indirect register, dim field write at index 2 SHOULD work":
    let r = DFPER.DREG
    mockInitRegs()
    r.DFLD[2] = 0x4'u32
    check mockRegRead(0xF003_0000'u32) == 0x0000_0400'u32
  test "Indirect register, dim field runtime index write SHOULD work":
    let r = DFPER.DREG
    mockInitRegs()
    let n = 1'u8
    r.DFLD[n] = 0x8'u32
    check mockRegRead(0xF003_0000'u32) == 0x0000_0080'u32
  test "Indirect register, read from read-only dim field SHOULD work":
    let r = ROFPER.ROREG
    mockInitRegs()
    mockRegPreset(0xF003_1000'u32, 0x00AB_CD12'u32)
    let v = r.ROFLD[1]
    check v == 0xCD'u32
  test "Indirect register, read from write-only dim field SHOULD NOT compile":
    let r = WOFPER.WOREG
    check not compiles(r.WOFLD[0])
  test "Indirect register, write to read-only dim field SHOULD NOT compile":
    let r = ROFPER.ROREG
    check not compiles(r.ROFLD[0] = 0x12'u32)
  test "Indirect register, write to write-only dim field SHOULD work":
    let r = WOFPER.WOREG
    mockInitRegs()
    r.WOFLD[1] = 0xCD'u32
    check mockRegRead(0xF003_2000'u32) == 0x0000_CD00'u32
  test "Indirect register, write unsupported type to dim field SHOULD NOT compile":
    let r = DFPER.DREG
    check not compiles(r.DFLD[0] = 0'i32)
    check not compiles(r.DFLD[0] = "wrong")
  test "Indirect register, dim field read at out-of-bounds static index SHOULD NOT compile":
    let r = DFPER.DREG
    check not compiles(r.DFLD[4])
  test "Indirect register, dim field write at out-of-bounds static index SHOULD NOT compile":
    let r = DFPER.DREG
    check not compiles(r.DFLD[4] = 0x1'u32)

suite "Indirect dim field, field access":
  test "Indirect dim field, read at index 0 SHOULD compile":
    let f = DFPER.DREG.DFLD
    check compiles(f[0])
  test "Indirect dim field, read at index 0 SHOULD work":
    let f = DFPER.DREG.DFLD
    mockInitRegs()
    mockRegPreset(0xF003_0000'u32, 0x0000_DCBA'u32)
    check f[0] == 0xA'u32
  test "Indirect dim field, read at index 2 SHOULD work":
    let f = DFPER.DREG.DFLD
    mockInitRegs()
    mockRegPreset(0xF003_0000'u32, 0x0000_DCBA'u32)
    check f[2] == 0xC'u32
  test "Indirect dim field, runtime index read SHOULD work":
    let f = DFPER.DREG.DFLD
    mockInitRegs()
    mockRegPreset(0xF003_0000'u32, 0x0000_DCBA'u32)
    let n = 3'u8
    check f[n] == 0xD'u32
  test "Indirect dim field, write at index 1 SHOULD work":
    let f = DFPER.DREG.DFLD
    mockInitRegs()
    f[1] = 0x2'u32
    check mockRegRead(0xF003_0000'u32) == 0x0000_0020'u32
  test "Indirect dim field, write at index 3 SHOULD work":
    let f = DFPER.DREG.DFLD
    mockInitRegs()
    f[3] = 0xE'u32
    check mockRegRead(0xF003_0000'u32) == 0x0000_E000'u32
  test "Indirect dim field, runtime index write SHOULD work":
    let f = DFPER.DREG.DFLD
    mockInitRegs()
    let n = 2'u8
    f[n] = 0x1'u32
    check mockRegRead(0xF003_0000'u32) == 0x0000_0100'u32
  test "Indirect dim field, read from read-only dim field SHOULD work":
    let f = ROFPER.ROREG.ROFLD
    mockInitRegs()
    mockRegPreset(0xF003_1000'u32, 0x00AB_CD12'u32)
    let v = f[2]
    check v == 0xAB'u32
  test "Indirect dim field, read from write-only dim field SHOULD NOT compile":
    let f = WOFPER.WOREG.WOFLD
    check not compiles(f[0])
  test "Indirect dim field, write to read-only dim field SHOULD NOT compile":
    let f = ROFPER.ROREG.ROFLD
    check not compiles(f[0] = 0x12'u32)
  test "Indirect dim field, write to write-only dim field SHOULD work":
    let f = WOFPER.WOREG.WOFLD
    mockInitRegs()
    f[0] = 0xEF'u32
    check mockRegRead(0xF003_2000'u32) == 0x0000_00EF'u32

suite "Indirect peripheral, dim field access":
  test "Indirect peripheral, dim field read SHOULD compile":
    let p = DFPER
    check compiles(p.DREG.DFLD[0])
  test "Indirect peripheral, dim field read at index 0 SHOULD work":
    let p = DFPER
    mockInitRegs()
    mockRegPreset(0xF003_0000'u32, 0x0000_DCBA'u32)
    let v = p.DREG.DFLD[0]
    check v == 0xA'u32
  test "Indirect peripheral, dim field read at index 3 SHOULD work":
    let p = DFPER
    mockInitRegs()
    mockRegPreset(0xF003_0000'u32, 0x0000_DCBA'u32)
    let v = p.DREG.DFLD[3]
    check v == 0xD'u32
  test "Indirect peripheral, dim field runtime index read SHOULD work":
    let p = DFPER
    mockInitRegs()
    mockRegPreset(0xF003_0000'u32, 0x0000_DCBA'u32)
    let n = 1'u8
    let v = p.DREG.DFLD[n]
    check v == 0xB'u32
  test "Indirect peripheral, dim field write at index 2 SHOULD work":
    let p = DFPER
    mockInitRegs()
    p.DREG.DFLD[2] = 0x5'u32
    check mockRegRead(0xF003_0000'u32) == 0x0000_0500'u32
  test "Indirect peripheral, dim field runtime index write SHOULD work":
    let p = DFPER
    mockInitRegs()
    let n = 0'u8
    p.DREG.DFLD[n] = 0xF'u32
    check mockRegRead(0xF003_0000'u32) == 0x0000_000F'u32
  test "Indirect peripheral, write unsupported type to dim field SHOULD NOT compile":
    let p = DFPER
    check not compiles(p.DREG.DFLD[0] = 0'i32)
    check not compiles(p.DREG.DFLD[0] = "wrong")
  test "Indirect peripheral, dim field read at out-of-bounds static index SHOULD NOT compile":
    let p = DFPER
    check not compiles(p.DREG.DFLD[4])
  test "Indirect peripheral, dim field write at out-of-bounds static index SHOULD NOT compile":
    let p = DFPER
    check not compiles(p.DREG.DFLD[4] = 0x1'u32)
  test "Indirect peripheral, read from read-only dim field SHOULD work":
    let p = ROFPER
    mockInitRegs()
    mockRegPreset(0xF003_1000'u32, 0x00AB_CD12'u32)
    let v = p.ROREG.ROFLD[2]
    check v == 0xAB'u32
  test "Indirect peripheral, read from write-only dim field SHOULD NOT compile":
    let p = WOFPER
    check not compiles(p.WOREG.WOFLD[0])
  test "Indirect peripheral, write to read-only dim field SHOULD NOT compile":
    let p = ROFPER
    check not compiles(p.ROREG.ROFLD[0] = 0x12'u32)
  test "Indirect peripheral, write to write-only dim field SHOULD work":
    let p = WOFPER
    mockInitRegs()
    p.WOREG.WOFLD[1] = 0xAB'u32
    check mockRegRead(0xF003_2000'u32) == 0x0000_AB00'u32

suite "Dim field, read-modify-write":
  # RMW syntax for dim fields: PERIPH.REG.FIELD[index](value).write()
  # Reads the register, updates only the selected field element's bits, writes back.
  # Multiple elements can be chained: FIELD[j](val1).FIELD[k](val2).write()
  test "Direct register, dim field RMW at index 0 SHOULD compile":
    check compiles(DFPER.DREG.DFLD[0](0x5'u32).write())
  test "Direct register, dim field RMW at index 0 SHOULD work":
    mockInitRegs()
    mockRegPreset(0xF003_0000'u32, 0x0000_DCBA'u32)
    DFPER.DREG.DFLD[0](0x5'u32).write()
    check mockRegRead(0xF003_0000'u32) == 0x0000_DCB5'u32
  test "Direct register, dim field RMW at index 2 SHOULD work":
    mockInitRegs()
    mockRegPreset(0xF003_0000'u32, 0x0000_DCBA'u32)
    DFPER.DREG.DFLD[2](0x3'u32).write()
    check mockRegRead(0xF003_0000'u32) == 0x0000_D3BA'u32
  test "Direct register, chained dim field RMW SHOULD work":
    # Modifies DFLD[1] (bits[7:4]: B→7) then DFLD[3] (bits[15:12]: D→1)
    mockInitRegs()
    mockRegPreset(0xF003_0000'u32, 0x0000_DCBA'u32)
    DFPER.DREG.DFLD[1](0x7'u32).DFLD[3](0x1'u32).write()
    check mockRegRead(0xF003_0000'u32) == 0x0000_1C7A'u32
  test "Direct register, dim field RMW on write-only field SHOULD NOT compile":
    check not compiles(WOFPER.WOREG.WOFLD[0](0xAB'u32).write())

