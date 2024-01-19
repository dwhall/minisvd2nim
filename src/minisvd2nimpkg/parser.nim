## Parses an .svd file (which is XML format) into a matching hierarchy of structures
##
## Reference:
##    https://www.keil.com/pack/doc/CMSIS/SVD/html/svd_Format_pg.html
##

import std/paths
import std/strutils
import std/xmlparser
import std/xmltree

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
    bitOffset*: uint
    bitWidth*: uint
    access*: SvdRegFieldAccess

  SvdRegister* = object of SvdObject
    description*: string
    address*: uint64
    resetVal*: uint64
    fields*: ref seq[SvdRegField]

  SvdPeripheral* = object of SvdObject
    interrupt*: int
    addressBlockOffset*: uint
    addressBlockSize*: uint
    registers*: ref seq[SvdRegister]

  SvdDevice* = object of SvdObject
    description*: string
    version*: float
    addressUnitBits*: int
    width*: int
    size*: int
    resetValue*: int
    resetMask*: int
    cpu*: ref SvdCpu
    peripherals*: ref seq[SvdPeripheral]

proc parseSvdDevice(deviceNode: XmlNode): SvdDevice
proc parseCpu(cpuNode: XmlNode): ref SvdCpu
proc parseSvdPeripherals(peripheralsNode: XmlNode): ref seq[SvdPeripheral]
proc parseSvdPeripheral(peripheralNode: XmlNode): SvdPeripheral
proc parseSvdRegisters(registersNode: XmlNode): ref seq[SvdRegister]
proc parseSvdRegister(registerNode: XmlNode): SvdRegister
proc parseSvdFields(fieldsNode: XmlNode): ref seq[SvdRegField]
proc parseSvdField(fieldNode: XmlNode): SvdRegField

proc parseSvdFile*(fn: Path): SvdDevice =
  let xml = loadXml(fn.string)
  assert xml.tag == "device"
  result = parseSvdDevice(xml)

proc parseSvdDevice(deviceNode: XmlNode): SvdDevice =
  result.name = deviceNode.child("name").innerText
  result.description = deviceNode.child("description").innerText
  result.version = parseFloat(deviceNode.child("version").innerText)
  result.addressUnitBits = parseInt(deviceNode.child("addressUnitBits").innerText)
  result.width = parseInt(deviceNode.child("width").innerText)
  result.size = parseInt(deviceNode.child("size").innerText)
  result.resetValue = parseHexInt(deviceNode.child("resetValue").innerText)
  result.resetMask = parseHexInt(deviceNode.child("resetMask").innerText)
  let cpuNode = deviceNode.child("cpu")
  result.cpu = parseCpu(cpuNode)
  let peripheralsNode = deviceNode.child("peripherals")
  result.peripherals = parseSvdPeripherals(peripheralsNode)

proc parseCpu(cpuNode: XmlNode): ref SvdCpu =
  if isNil(cpuNode): return nil
  new(result)
  result.name = cpuNode.child("name").innerText
  result.revision = cpuNode.child("revision").innerText
  result.endian = if cpuNode.child("endian").innerText == "little": SvdCpuEndian.littleEndian
                  else: SvdCpuEndian.bigEndian
  result.mpuPresent = cpuNode.child("mpuPresent").innerText == "true"
  result.fpuPresent = cpuNode.child("fpuPresent").innerText == "true"
  result.nvicPrioBits = parseInt(cpuNode.child("nvicPrioBits").innerText)
  result.vendorSystickConfig = cpuNode.child("vendorSystickConfig").innerText == "true"

proc parseSvdPeripherals(peripheralsNode: XmlNode): ref seq[SvdPeripheral] =
  if isNil(peripheralsNode): return nil
  for pnode in peripheralsNode.findAll("peripheral"):
    result[].add(parseSvdPeripheral(pnode))

proc parseSvdPeripheral(peripheralNode: XmlNode): SvdPeripheral =
  result.name = peripheralNode.child("name").innerText
  result.interrupt = parseInt(peripheralNode.child("interrupt").innerText)
  result.addressBlockOffset = parseUInt(peripheralNode.child("addressBlockOffset").innerText)
  result.addressBlockSize = parseUInt(peripheralNode.child("addressBlockSize").innerText)
  let registersNode = peripheralNode.child("registers")
  result.registers = parseSvdRegisters(registersNode)

proc parseSvdRegisters(registersNode: XmlNode): ref seq[SvdRegister] =
  if isNil(registersNode): return nil
  for rnode in registersNode.findAll("peripheral"):
    result[].add(parseSvdRegister(rnode))

proc parseSvdRegister(registerNode: XmlNode): SvdRegister =
  result.name = registerNode.child("name").innerText
  result.description = registerNode.child("description").innerText
  result.address = parseBiggestUInt(registerNode.child("address").innerText)
  result.resetVal = parseBiggestUInt(registerNode.child("resetVal").innerText)
  let fieldsNode = registerNode.child("fields")
  result.fields = parseSvdFields(fieldsNode)

proc parseSvdFields(fieldsNode: XmlNode): ref seq[SvdRegField] =
  if isNil(fieldsNode): return nil
  for fnode in fieldsNode.findAll("field"):
    result[].add(parseSvdField(fnode))

proc parseSvdField(fieldNode: XmlNode): SvdRegField =
  result.name = fieldNode.child("name").innerText
  result.description = fieldNode.child("description").innerText
  result.bitOffset = parseUInt(fieldNode.child("bitOffset").innerText)
  result.bitWidth = parseUInt(fieldNode.child("bitWidth").innerText)
  result.access = case fieldNode.child("access").innerText
    of "read-only": SvdRegFieldAccess.readOnly
    of "read-write": SvdRegFieldAccess.readWrite
    else: SvdRegFieldAccess.writeOnly
