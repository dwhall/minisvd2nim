#!fmt: off

## These templates and macros are not used by the minisvd2nim program.
## Instead, they are used by the code generated by minisvd2nim.
## This allows the programmer to change the final form of the Nim source
## without changing and recompiling minisvd2nim.
##
## References:
##    https://gcc.gnu.org/onlinedocs/gcc/Using-Assembly-Language-with-C.html
##
## DEVELOPERS: if you edit this file in a way that changes the generated
## output, you MUST update at least the minisvd2nim tool's version number.
##

import std/[macros, volatile]

# FIXME: find a compiler-agnostic way to check for support
# of ARM instructions BFI and UBFX.
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

template declareRegisterBody(
    peripheralName: untyped,
    registerName: untyped,
    addressOffset: static uint32,
    readAccess: static bool,
    writeAccess: static bool,
    registerDesc: static string
): untyped =
  # Registers that have a non-empty derivedFrom field use its Val class so the derived registers are type compatible.
  # This allows, for example, one of the sibling register types to be selected from a case/of of all sibling register types.
  # Registers that do not declare a derivedFrom receive the default, RegisterVal, which
  # makes that register type distinct.
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

template declareRegister*(
    peripheralName: untyped,
    registerName: untyped,
    addressOffset: static uint32,
    readAccess: static bool,
    writeAccess: static bool,
    registerDesc: static string,
    derivedFrom: untyped
): untyped =
  ## Declares `PERIPH_REGVal` derived from another register,
  ## so that the two registers are type-compatible.
  ## The `PERIPH_REGVal` type does NOT need to be public.
  ## The programmer receives a value of this type by reading
  ## the register: `var v = PERIPH.REG`
  type `peripheralName _ registerName Val`* {.inject.} = `peripheralName _ derivedFrom Val`
  declareRegisterBody(peripheralName, registerName, addressOffset, readAccess, writeAccess, registerDesc)

template declareRegister*(
    peripheralName: untyped,
    registerName: untyped,
    addressOffset: static uint32,
    readAccess: static bool,
    writeAccess: static bool,
    registerDesc: static string
): untyped =
  ## Declares `PERIPH_REGVal` as a distinct type
  ## so that no other register value types are compatible.
  ## The `PERIPH_REGVal` type does NOT need to be public.
  ## The programmer receives a value of this type by reading
  ## the register: `var v = PERIPH.REG`
  type `peripheralName _ registerName Val`* {.inject.} = distinct RegisterVal
  declareRegisterBody(peripheralName, registerName, addressOffset, readAccess, writeAccess, registerDesc)

func getField[T](regVal: T, bitOffset: static int, bitWidth: static int): T {.inline.} =
  # Extracts a bitfield from regVal, zero extends it to 32 bits.
  # Returns the field value, down-shifted to no bit offset, as a register-distinct type.
  # Employs the Unsigned Bit Field eXtract instruction, UBFX, when the target supports it.
  assert bitOffset >= 0, "bitOffset must not be negative"
  assert bitWidth > 0, "bitWidth must be greater than zero"
  assert (bitOffset + bitWidth) <= 32, "bit field must not exceed register size in bits"
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
  # Replaces width bits in regVal starting at the low bit position bitOffset,
  # with bitWidth bits from fieldVal starting at bit[0]. Other bits in regVal are unchanged.
  # Employs the ARMv7 Bit Field Insert instruction, BFI, when the target supports it.
  assert bitOffset >= 0, "bitOffset must not be negative"
  assert bitWidth > 0, "bitWidth must be greater than zero"
  assert (bitOffset + bitWidth) <= 32, "bit field must not exceed register size in bits"
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
  ## Declares read and write funcs for a register's bit field.
  ## The read and write funcs perform the necessary bit shifting and masking
  ## to ensure only the named fields are impacted.
  ##
  ## Field read-modify-writes must be terminated with the `.write()`
  ## More than one field-write funcs can be chained. `PERIPH.REG.FIELD1(11).FIELD2(42).write()`
  when readAccess:
    template `fieldName`*(
        regVal: `peripheralName _ registerName Val`
    ): `peripheralName _ registerName Val` =
      getField[`peripheralName _ registerName Val`](regVal, bitOffset, bitWidth)

  when writeAccess:
    template `fieldName`*(
        regVal: `peripheralName _ registerName Val`, fieldVal: uint32
    ): `peripheralName _ registerName Val` =
      setField[`peripheralName _ registerName Val`](
        regVal, fieldVal, bitOffset, bitWidth
      )

macro declareEnum(enumType: untyped, enumPairsStmtList: untyped) {.inject.} =
  # Declares a Nim enumerator with the given type that is bound to a specific register.
  # The enum names and values are from the SVD file.
  enumPairsStmtList.expectKind(nnkStmtList)
  var fields: seq[NimNode]
  for asgnNode in enumPairsStmtList:
    asgnNode.expectKind(nnkAsgn)
    var node = newNimNode(nnkEnumFieldDef)
    node.add(asgnNode[0])
    node.add(asgnNode[1])
    fields.add(node)
  newEnum(name = enumType, fields = fields, public = true, pure = true)  # TODO: are we sure we want pure?

macro declareFieldEnum*(
  peripheralName: untyped,
  registerName: untyped,
  fieldName: untyped,
  bitOffset: static int,
  bitWidth: static int,
  values: untyped
) {.inject.} =
  ## Declares enum values that are bound to a specific `PERIPH.REG`.
  ## Also declares a method to write the enum value to a register field: `PERIPH.REG.FIELD1(ENUMVAL).write()`
  let enumType = ident(peripheralName.strVal & '_' & registerName.strVal & '_' & fieldName.strVal & "Val")
  let regValType = ident(peripheralName.strVal & '_' & registerName.strVal & "Val")
  result = quote do:
    declareEnum(`enumType`, `values`)
    proc `fieldName`*(regVal: `regValType`, fieldVal: `enumType`): `regValType` {.inline.} =
      setField[`regValType`](regVal, fieldVal.uint32, `bitOffset`, `bitWidth`)
