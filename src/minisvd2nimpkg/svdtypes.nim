## Copyright 2024 Dean Hall, all rights reserved.  See LICENSE.txt for details.
##
## Types used to hold data parsed from an SVD file.
## Each SvdObject's field names MUST match the SVD spec
## in order for the auto-parser to work.
##

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
    unspecified
    readWrite = "readWrite"
    readOnly = "read-only"
    writeOnly = "write-only"
    writeOnce = "writeOnce"
    readWriteOnce = "readWriteOnce"

  SvdFieldUsage* = enum
    unspecified
    read = "read"
    write = "write"
    readWrite = "read-write"

  SvdEnumVal* = object of SvdObject
    description*: string
    # TODO: choice of: value, isDefault
    isDefault*: bool
    value*: uint32

  SvdFieldEnum* = object of SvdObject
    usage*: SvdFieldUsage = readWrite
    headerEnumName*: string
    values*: seq[SvdEnumVal]

  SvdRegField* = object of SvdObject
    description*: string
    bitOffset*: int
    bitWidth*: int
    access*: SvdAccess
    enumeratedValues*: SvdFieldEnum

  SvdRegister* = object of SvdObject
    description*: string
    addressOffset*: int
    size*: int
    resetValue*: uint32
    derivedFrom*: string
    access*: SvdAccess
    fields*: seq[SvdRegField]
    dim: int
    dimIncrement: int
    dimIndex: int

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
    access*: SvdAccess
    interrupt*: seq[SvdInterrupt]
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
