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

  SvdFieldEnum* = object of SvdObject
    usage*: SvdAccess = readWrite
    headerEnumName*: string
    values*: seq[SvdEnumVal]

  SvdRegField* = object of SvdObject
    description*: string
    bitOffset*: int
    bitWidth*: int
    access*: SvdAccess
    fieldEnum*: SvdFieldEnum

  SvdRegister* = ref object of SvdObject
    description*: string
    addressOffset*: int
    size*: int
    resetValue*: uint32
    baseRegister*: SvdRegister # only used by derived registers
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
    baseAddress*: uint32
    interrupts*: seq[SvdInterrupt]
    addressBlock*: ref SvdAddressBlock
    registers*: seq[SvdRegister]

  SvdDevice* = object of SvdObject
    description*: string
    version*: float
    addressUnitBits*: int
    width*: int
    size*: int
    resetValue*: uint32
    resetMask*: uint32
    cpu*: ref SvdCpu
    peripherals*: seq[SvdPeripheral]
    access*: SvdAccess # default access rights for all registers
