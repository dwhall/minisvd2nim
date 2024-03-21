type
  SvdObject* = object of RootObj
    name*: string

  SvdCpu* = object of SvdObject
    revision*: string
    endian*: Endianness
    mpuPresent*: bool
    fpuPresent*: bool
    nvicPrioBits*: int
    vendorSystickConfig*: bool

  SvdAccess* = enum
    readWrite
    readOnly
    writeOnly

  SvdEnumVal* = object of SvdObject
    description*: string
    isDefault*: bool
    value*: uint32

  SvdEnumVals* = object of SvdObject
    usage*: SvdAccess
    enumVals*: seq[SvdEnumVal]

  SvdRegField* = object of SvdObject
    description*: string
    bitOffset*: int
    bitWidth*: int
    access*: SvdAccess
    enumVals*: SvdEnumVals

  SvdRegister* = object of SvdObject
    description*: string
    addressOffset*: int
    size*: int
    resetValue*: int
    access*: SvdAccess
    fields*: seq[SvdRegField]

  SvdInterrupt* = object of SvdObject
    description*: string
    value*: int

  SvdAddressBlock* = object
    offset*: int
    size*: int
    usage*: string

  SvdPeripheral* = object of SvdObject
    description*: string
    groupName*: string
    baseAddress*: uint
    interrupts*: seq[SvdInterrupt]
    addressBlock*: ref SvdAddressBlock
    registers*: seq[SvdRegister]

  SvdDevice* = object of SvdObject
    description*: string
    version*: float
    addressUnitBits*: int
    width*: int
    size*: int
    resetValue*: int
    resetMask*: int
    cpu*: ref SvdCpu
    peripherals*: seq[SvdPeripheral]
