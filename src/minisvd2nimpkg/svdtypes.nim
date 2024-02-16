type
  SvdObject* = object of RootObj
    name*: string

  SvdCpuEndian* = enum
    littleEndian
    bigEndian

  SvdCpu* = object of SvdObject
    revision*: string
    endian*: SvdCpuEndian
    mpuPresent*: bool
    fpuPresent*: bool
    nvicPrioBits*: int
    vendorSystickConfig*: bool

  SvdRegFieldAccess* = enum
    readWrite
    readOnly
    writeOnly

  SvdRegField* = object of SvdObject
    description*: string
    bitOffset*: int
    bitWidth*: int
    access*: SvdRegFieldAccess

  SvdRegister* = object of SvdObject
    description*: string
    addressOffset*: int
    size*: int
    resetValue*: int
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
