#!fmt: off

## These templates and macros are not used by the minisvd2nim program.
## Instead, they are used by the code generated by minisvd2nim.
## This allows the programmer to change the final form of the Nim source
## without changing and recompiling minisvd2nim.
##
## References:
##    https://gcc.gnu.org/onlinedocs/gcc/Using-Assembly-Language-with-C.html
##

import std/macros
import std/volatile

# FIXME: find a compiler-agnostic way to check for support
# of the BFI and UBFX instructions.
# For now, this assumes arch v4 (armv7 and later) supports
# the instructions used in emit/asm pragmas below.
const ARM_ARCH {.intdefine: "__ARM_ARCH".} = 0
const ArmArchSupportsAsmInstructions: bool = (ARM_ARCH >= 4)
# If the ARM architecture does not support assembly instructions used below,
# import the bitops module to perform the operations manually.
when not ArmArchSupportsAsmInstructions:
  import std/bitops

type RegisterVal = uint32

template declareDevice*(
    deviceName: untyped,
    mpuPresent: static bool,
    fpuPresent: static bool,
    nvicPrioBits: static int,
): untyped =
  # Device details
  const DEVICE* {.inject.} = astToStr(deviceName)
  const MPU_PRESET* {.inject.} = mpuPresent
  const FPU_PRESENT* {.inject.} = fpuPresent
  const NVIC_PRIO_BITS* {.inject.} = nvicPrioBits

template declarePeripheral*(
    peripheralName: untyped, baseAddress: static uint32, peripheralDesc: static string
): untyped =
  type `peripheralName Base` {.inject.} = distinct RegisterVal
  const peripheralName* {.inject.} = `peripheralName Base`(baseAddress)

template declareInterrupt*(
    peripheralName: untyped,
    interruptName: untyped,
    interruptValue: static int,
    interruptDesc: static string,
): untyped =
  const `irq interruptName`* {.inject.} = interruptValue # `interruptDesc`

template declareRegister(
    peripheralName: untyped,
    registerName: untyped,
    addressOffset: static uint32,
    readAccess: static bool,
    writeAccess: static bool,
    registerDesc: static string,
    baseRegisterName: untyped
): untyped =
  # Registers that have a baseRegister use its Val class so all siblings are type compatible.
  # This allows, for example, one of the sibling register types to be selected from a case/of of all sibling register types.
  # Registers that do not declare a baseRegisterName receive the default, RegisterVal, which
  # makes that register type distinct.
  type `peripheralName _ registerName Val`* {.inject.} = distinct `baseRegisterName`
  type `peripheralName _ registerName Ptr` {.inject.} =
    ptr `peripheralName _ registerName Val`

  const `peripheralName _ registerName` {.inject.} =
    cast[`peripheralName _ registerName Ptr`](`peripheralName`.uint32 + addressOffset)

  when readAccess:
    proc `registerName`*(
        base: static `peripheralName Base`
    ): `peripheralName _ registerName Val` {.inline.} =
      volatileLoad(`peripheralName _ registerName`)

  when writeAccess:
    template `registerName=`*(
        base: static `peripheralName Base`, val: `peripheralName _ registerName Val`
    ) =
      volatileStore(`peripheralName _ registerName`, val)

    template `registerName=`*(base: static `peripheralName Base`, val: uint32) =
      volatileStore(`peripheralName _ registerName`, `peripheralName _ registerName Val`(val))

    proc write*(regVal: `peripheralName _ registerName Val`) {.inline.} =
      volatileStore(`peripheralName _ registerName`, regVal)

template declareDerivedRegister*(
    peripheralName: untyped,
    registerName: untyped,
    addressOffset: static uint32,
    readAccess: static bool,
    writeAccess: static bool,
    registerDesc: static string,
    baseRegisterName: untyped
): untyped =
  declareRegister(peripheralName, registerName, addressOffset, readAccess, writeAccess, registerDesc, `peripheralName _ baseRegisterName Val`)

template declareDistinctRegister*(
    peripheralName: untyped,
    registerName: untyped,
    addressOffset: static uint32,
    readAccess: static bool,
    writeAccess: static bool,
    registerDesc: static string
): untyped =
  declareRegister(peripheralName, registerName, addressOffset, readAccess, writeAccess, registerDesc, RegisterVal)

func getField[T](regVal: T, bitOffset: static int, bitWidth: static int): T {.inline.} =
  ## Extracts a bitfield from regVal, zero extends it to 32 bits.
  ## Returns the field value, down-shifted to no bit offset, as a register-distinct type.
  ## Employs the Unsigned Bit Field eXtract instruction, UBFX, when the target supports it.
  doAssert bitOffset >= 0, "bitOffset must not be negative"
  doAssert bitWidth > 0, "bitWidth must be greater than zero"
  doAssert (bitOffset + bitWidth) <= 32, "bit field must not exceed register size in bits"
  when ArmArchSupportsAsmInstructions:
    {.emit: ["asm (\"ubfx %0, %1, %2, %3\"\n\t: \"=r\" (", result, ")\n\t: \"r\" (", regVal, "), \"n\" (", bitOffset, "), \"n\" (", bitWidth, "));\n"].}
  else:
    const bitEnd = bitOffset + bitWidth - 1
    const bitMask = toMask[uint32](bitOffset .. bitEnd)
    var r = regVal.RegisterVal
    r = r and bitMask
    r = r shr bitOffset
    r.T

func setField[T](
    regVal: T, fieldVal: RegisterVal, bitOffset: static int, bitWidth: static int
): T {.inline.} =
  ## Replaces width bits in regVal starting at the low bit position bitOffset,
  ## with bitWidth bits from fieldVal starting at bit[0]. Other bits in regVal are unchanged.
  ## Employs the ARMv7 Bit Field Insert instruction, BFI, when the target supports it.
  doAssert bitOffset >= 0, "bitOffset must not be negative"
  doAssert bitWidth > 0, "bitWidth must be greater than zero"
  doAssert (bitOffset + bitWidth) <= 32, "bit field must not exceed register size in bits"
  when ArmArchSupportsAsmInstructions:
    result = regVal
    {.emit: ["asm (\"bfi %0, %1, %2, %3\"\n\t: \"+r\" (", result, ")\n\t: \"r\" (", fieldVal, "), \"n\" (", bitOffset, "), \"n\" (", bitWidth, "));\n"].}
  else:
    const bitEnd = bitOffset + bitWidth - 1
    const bitMask = toMask[uint32](bitOffset .. bitEnd)
    var r = regVal.RegisterVal
    r = r and bitnot(bitMask)
    r = r or ((fieldVal shl bitOffset) and bitMask)
    r.T

template declareField*(
    peripheralName: untyped,
    registerName: untyped,
    fieldName: untyped,
    bitOffset: static int,
    bitWidth: static int,
    readAccess: static bool,
    writeAccess: static bool,
    fieldDesc: static string,
) =
  when readAccess:
    template `fieldName`*(
        regVal: `peripheralName _ registerName Val`
    ): `peripheralName _ registerName Val` =
      getField[`peripheralName _ registerName Val`](regVal, bitOffset, bitWidth)

  when writeAccess:
    proc `fieldName`*(
        regVal: `peripheralName _ registerName Val`, fieldVal: uint32
    ): `peripheralName _ registerName Val` {.inline.} =
      setField[`peripheralName _ registerName Val`](
        regVal, fieldVal, bitOffset, bitWidth
      )

macro declareEnum(enumType: untyped, enumPairsStmtList: untyped) {.inject.} =
  enumPairsStmtList.expectKind(nnkStmtList)
  var fields: seq[NimNode]
  for asgnNode in enumPairsStmtList:
    asgnNode.expectKind(nnkAsgn)
    var node = newNimNode(nnkEnumFieldDef)
    node.add(asgnNode[0])
    node.add(asgnNode[1])
    fields.add(node)
  newEnum(enumType, fields, true, true)

macro declareFieldEnum*(
  peripheralName: untyped,
  registerName: untyped,
  fieldName: untyped,
  bitOffset: static int,
  bitWidth: static int,
  values: untyped
) {.inject.} =
  let enumType = ident(peripheralName.strVal & '_' & registerName.strVal & '_' & fieldName.strVal & "Val")
  let regValType = ident(peripheralName.strVal & '_' & registerName.strVal & "Val")
  result = quote do:
    declareEnum(`enumType`, `values`)
    proc `fieldName`*(regVal: `regValType`, fieldVal: `enumType`): `regValType` {.inline.} =
      setField[`regValType`](regVal, fieldVal.uint32, `bitOffset`, `bitWidth`)