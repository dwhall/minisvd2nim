## Tests for declareFieldEnum - enum support for register fields.
## Tests define the desired behavior; the macro will be updated to pass them.
##
#!fmt: off

import unittest2
import volatile_mock

# File under test:
import minisvd2nimpkg/metagenerator
# NOTE: the patchFile directive in config.nims replaces std/volatile
# with volatile_mock which enables the mock*() procs used in this file

# EPER.EREG: read-write register with two 2-bit enum fields
#   EFLD:  bits [3:2], RW, enum Disabled=0 Input=1 Output=2 AltFunc=3
#   EFLD2: bits [7:6], RW, enum Low=0 Med=1 High=2 Max=3
declarePeripheral(peripheralName = EPER, baseAddress = 0xF004_0000'u32, peripheralDesc = "Test peripheral for enum fields")
declareRegister(peripheralName = EPER, registerName = EREG, addressOffset = 0x00'u32, readAccess = true, writeAccess = true, registerDesc = "Test register with enum fields")
declareField(peripheralName = EPER, registerName = EREG, fieldName = EFLD, bitOffset = 2, bitWidth = 2, dim = 0, dimIncrement = 0, readAccess = true, writeAccess = true, fieldDesc = "Test enum field")
declareFieldEnum(peripheralName = EPER, registerName = EREG, fieldName = EFLD, bitOffset = 2, bitWidth = 2, readAccess = true, writeAccess = true):
  Disabled = 0
  Input = 1
  Output = 2
  AltFunc = 3
declareField(peripheralName = EPER, registerName = EREG, fieldName = EFLD2, bitOffset = 6, bitWidth = 2, dim = 0, dimIncrement = 0, readAccess = true, writeAccess = true, fieldDesc = "Test enum field 2")
declareFieldEnum(peripheralName = EPER, registerName = EREG, fieldName = EFLD2, bitOffset = 6, bitWidth = 2, readAccess = true, writeAccess = true):
  Low = 0
  Med = 1
  High = 2
  Max = 3

# EPER.ROENREG: read-write register with a read-only 2-bit enum field
#   ROENFL: bits [1:0], RO, enum Off=0 On=1 Fault=2 Unknown=3
declareRegister(peripheralName = EPER, registerName = ROENREG, addressOffset = 0x04'u32, readAccess = true, writeAccess = true, registerDesc = "Test register with RO enum field")
declareField(peripheralName = EPER, registerName = ROENREG, fieldName = ROENFL, bitOffset = 0, bitWidth = 2, dim = 0, dimIncrement = 0, readAccess = true, writeAccess = false, fieldDesc = "Test read-only enum field")
declareFieldEnum(peripheralName = EPER, registerName = ROENREG, fieldName = ROENFL, bitOffset = 0, bitWidth = 2, readAccess = true, writeAccess = false):
  Off = 0
  On = 1
  Fault = 2
  Unknown = 3

# EPER.WOENREG: read-write register with a write-only 2-bit enum field
#   WOENFL: bits [5:4], WO, enum ModeA=0 ModeB=1 ModeC=2 ModeD=3
declareRegister(peripheralName = EPER, registerName = WOENREG, addressOffset = 0x08'u32, readAccess = true, writeAccess = true, registerDesc = "Test register with WO enum field")
declareField(peripheralName = EPER, registerName = WOENREG, fieldName = WOENFL, bitOffset = 4, bitWidth = 2, dim = 0, dimIncrement = 0, readAccess = false, writeAccess = true, fieldDesc = "Test write-only enum field")
declareFieldEnum(peripheralName = EPER, registerName = WOENREG, fieldName = WOENFL, bitOffset = 4, bitWidth = 2, readAccess = false, writeAccess = true):
  ModeA = 0
  ModeB = 1
  ModeC = 2
  ModeD = 3

suite "Enum type declaration":
  test "declareFieldEnum SHOULD create the enum type":
    check compiles(EPER_EREG_EFLDVal)
  test "Enum values SHOULD be accessible":
    check compiles(Disabled)
    check compiles(Input)
    check compiles(Output)
    check compiles(AltFunc)
  test "Enum values SHOULD have correct numeric values":
    check Disabled.uint32 == 0'u32
    check Input.uint32 == 1'u32
    check Output.uint32 == 2'u32
    check AltFunc.uint32 == 3'u32
  test "Each field SHOULD have its own distinct enum type":
    check compiles(EPER_EREG_EFLDVal)
    check compiles(EPER_EREG_EFLD2Val)
    check not compiles (var x: EPER_EREG_EFLDVal = Low;)

suite "Enum field write (field= zeroes other bits)":
  test "Direct register, write enum value SHOULD compile":
    check compiles (EPER.EREG.EFLD = Output;)
  test "Direct register, write enum value SHOULD store correct bits":
    # Output=2, bits[3:2], so stored value is 2 shl 2 = 0x08; all other bits zero
    mockInitRegs()
    EPER.EREG.EFLD = Output
    check mockRegRead(0xF004_0000'u32) == 0x0000_0008'u32
  test "Direct register, write a different enum value SHOULD store correct bits":
    # AltFunc=3, bits[3:2], so stored value is 3 shl 2 = 0x0C
    mockInitRegs()
    EPER.EREG.EFLD = AltFunc
    check mockRegRead(0xF004_0000'u32) == 0x0000_000C'u32
  test "Direct register, write enum value SHOULD zero bits outside the field":
    mockInitRegs()
    mockRegPreset(0xF004_0000'u32, 0xFFFF_FFFF'u32)
    EPER.EREG.EFLD = Input
    # Input=1, bits[3:2] → 1 shl 2 = 0x04; all other bits zeroed
    check mockRegRead(0xF004_0000'u32) == 0x0000_0004'u32
  test "Direct register, write wrong enum type to field SHOULD NOT compile":
    check not compiles(EPER.EREG.EFLD = Low)
  test "Direct register, write enum to read-only field SHOULD NOT compile":
    check not compiles(EPER.ROENREG.ROENFL = EPER_ROENREG_ROENFLVal.On)
  test "Direct register, write enum to write-only field SHOULD compile":
    check compiles (EPER.WOENREG.WOENFL = EPER_WOENREG_WOENFLVal.ModeC;)
  test "Direct register, write enum to write-only field SHOULD store correct bits":
    # ModeC=2, bits[5:4], so stored value is 2 shl 4 = 0x20
    mockInitRegs()
    EPER.WOENREG.WOENFL = EPER_WOENREG_WOENFLVal.ModeC
    check mockRegRead(0xF004_0008'u32) == 0x0000_0020'u32
  test "Indirect peripheral, write enum value SHOULD store correct bits":
    let p = EPER
    mockInitRegs()
    p.EREG.EFLD = Output
    check mockRegRead(0xF004_0000'u32) == 0x0000_0008'u32
  test "Indirect register, write enum value SHOULD store correct bits":
    let r = EPER.EREG
    mockInitRegs()
    r.EFLD = AltFunc
    check mockRegRead(0xF004_0000'u32) == 0x0000_000C'u32

suite "Enum field read-modify-write":
  test "Direct register, enum RMW SHOULD compile":
    check compiles(EPER.EREG.EFLD(Output).write())
  test "Direct register, enum RMW SHOULD change only the field's bits":
    # Output=2, bits[3:2]: mask=0x0C; starting from 0xFFFF_FFFF
    # clear bits[3:2], set to 0b10 → 0xFFFF_FFF3 | 0x08 = 0xFFFF_FFFB
    mockInitRegs()
    mockRegPreset(0xF004_0000'u32, 0xFFFF_FFFF'u32)
    EPER.EREG.EFLD(Output).write()
    check mockRegRead(0xF004_0000'u32) == 0xFFFF_FFFB'u32
  test "Direct register, enum RMW to zero SHOULD clear only the field's bits":
    # Disabled=0, bits[3:2]: starting from 0xFFFF_FFFF → clear bits[3:2]
    mockInitRegs()
    mockRegPreset(0xF004_0000'u32, 0xFFFF_FFFF'u32)
    EPER.EREG.EFLD(Disabled).write()
    check mockRegRead(0xF004_0000'u32) == 0xFFFF_FFF3'u32
  test "Direct register, chained enum RMW on two fields SHOULD change only those fields":
    # EFLD=Output(2) bits[3:2] → 0b10, EFLD2=High(2) bits[7:6] → 0b10
    # Starting from 0xFFFF_FFFF:
    #   clear bits[3:2] and bits[7:6]: ~(0x0C | 0xC0) = ~0xCC = 0xFFFF_FF33
    #   0xFFFF_FFFF & 0xFFFF_FF33 = 0xFFFF_FF33
    #   set bits: (2 shl 2) | (2 shl 6) = 0x08 | 0x80 = 0x88
    #   result: 0xFFFF_FF33 | 0x88 = 0xFFFF_FFBB
    mockInitRegs()
    mockRegPreset(0xF004_0000'u32, 0xFFFF_FFFF'u32)
    EPER.EREG.EFLD(Output).EFLD2(High).write()
    check mockRegRead(0xF004_0000'u32) == 0xFFFF_FFBB'u32
  test "Direct register, chained RMW mixing enum and uint32 SHOULD work":
    # EFLD=AltFunc(3) bits[3:2] → 0b11, EFLD2=1(Med) bits[7:6] → 0b01
    # Starting from 0x0000_0000:
    #   set bits: (3 shl 2) | (1 shl 6) = 0x0C | 0x40 = 0x4C
    mockInitRegs()
    mockRegPreset(0xF004_0000'u32, 0x0000_0000'u32)
    EPER.EREG.EFLD(AltFunc).EFLD2(1'u32).write()
    check mockRegRead(0xF004_0000'u32) == 0x0000_004C'u32
  test "Direct register, enum RMW on read-only field SHOULD NOT compile":
    check not compiles(EPER.ROENREG.ROENFL(EPER_ROENREG_ROENFLVal.On).write())
  test "Direct register, enum RMW with wrong enum type SHOULD NOT compile":
    check not compiles(EPER.EREG.EFLD(Low).write())
  test "Indirect peripheral, enum RMW SHOULD change only the field's bits":
    let p = EPER
    mockInitRegs()
    mockRegPreset(0xF004_0000'u32, 0xFFFF_FFFF'u32)
    p.EREG.EFLD(Input).write()
    # Input=1, bits[3:2]: 0xFFFF_FFF3 | (1 shl 2) = 0xFFFF_FFF3 | 0x04 = 0xFFFF_FFF7
    check mockRegRead(0xF004_0000'u32) == 0xFFFF_FFF7'u32
  test "Indirect register, enum RMW SHOULD change only the field's bits":
    let r = EPER.EREG
    mockInitRegs()
    mockRegPreset(0xF004_0000'u32, 0xFFFF_FFFF'u32)
    r.EFLD(Disabled).write()
    check mockRegRead(0xF004_0000'u32) == 0xFFFF_FFF3'u32

suite "Enum field read":
  test "Direct register, field read SHOULD return a value matching the enum":
    # bits[3:2]=0b10 → Output=2
    mockInitRegs()
    mockRegPreset(0xF004_0000'u32, 0x0000_0008'u32)
    let v = EPER.EREG.EFLD
    check v.uint32 == Output.uint32
  test "Direct register, read from read-only enum field SHOULD work":
    # bits[1:0]=0b01 → On=1
    mockInitRegs()
    mockRegPreset(0xF004_0004'u32, 0x0000_0001'u32)
    let v = EPER.ROENREG.ROENFL
    check v.uint32 == EPER_ROENREG_ROENFLVal.On.uint32
  test "Direct register, read from write-only enum field SHOULD NOT compile":
    check not compiles(EPER.WOENREG.WOENFL)
  test "Indirect peripheral, field read SHOULD return a value matching the enum":
    let p = EPER
    mockInitRegs()
    mockRegPreset(0xF004_0000'u32, 0x0000_000C'u32)
    let v = p.EREG.EFLD
    check v.uint32 == AltFunc.uint32
  test "Indirect register, field read SHOULD return a value matching the enum":
    let r = EPER.EREG
    mockInitRegs()
    mockRegPreset(0xF004_0000'u32, 0x0000_0004'u32)
    let v = r.EFLD
    check v.uint32 == Input.uint32






