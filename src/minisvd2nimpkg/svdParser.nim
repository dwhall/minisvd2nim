import std/paths

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
    vendorSysteckConfig*: bool

  SvdRegFieldAccess* = enum
    readWrite
    readOnly
    writeOnly

  SvdRegField* = object of SvdObject
    bitOffset*: uint
    bitWidth*: uint
    access*: SvdRegFieldAccess

  SvdRegister* = object of SvdObject
    description*: string
    address*: uint64
    resetVal*: uint64
    fields*: seq[SvdRegField]

  SvdPeripheral* = object of SvdObject
    interrupt*: int
    addressBlockOffset*: uint
    addressBlockSize*: uint
    registers*: seq[SvdRegister]

  SvdDevice* = object of SvdObject
    description*: string
    version*: float
    addressUnitBits*: int
    width*: int
    size*: int
    resetValue*: uint
    resetMask*: uint
    cpu*: SvdCpu
    peripherals*: seq[SvdPeripheral]

func parseSvdDevice*(fn: Path): SvdDevice =
  result
