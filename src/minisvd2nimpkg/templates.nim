## These templates are not used by the minisvd2nim program.
## Instead, these templates are used by the generated output of minisvd2nim.
## This allows the programmer to change the final form of the Nim source
## without changing and recompiling minisvd2nim.

# First some types that the templates will need
import svdtypes

template declareDevice*(
    deviceName: untyped, mpuPresent: bool, fpuPresent: bool, nvicPrioBits: int
): untyped =
  # Device details
  const DEVICE* = "`deviceName`"
  const MPU_PRESET* = mpuPresent
  const FPU_PRESENT* = fpuPresent
  const NVIC_PRIO_BITS* = nvicPrioBits

template declarePeripheral*(
    peripheralName: untyped, baseAddress: uint, peripheralDesc: string
): untyped =
  # TODO: figure out a good datatype for a peripheral
  const `peripheralName BaseAddress`* {.inject.} = baseAddress

template declareInterrupt*(
    peripheralName: untyped,
    interruptName: untyped,
    interruptValue: int,
    interruptDesc: string,
): untyped =
  const `irq interruptName`* = interruptValue # `interruptDesc`

template declareRegister*(
    peripheralName: untyped,
    registerName: untyped,
    addressOffset: uint,
    registerDesc: string,
): untyped =
  # TODO figure out a good datatype for a register
  const `registerName Reg`* = `peripheralName BaseAddress` + addressOffset

template declareField*(
    peripheralName: untyped,
    registerName: untyped,
    fieldName: untyped,
    bitOffset: int,
    bitWidth: int,
    access: untyped,
    fieldDesc: string,
) =
  const `fieldName`* = 0
