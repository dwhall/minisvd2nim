## Parses an .svd file (which is XML format) into a matching hierarchy of structures
##
## Reference:
##    https://www.keil.com/pack/doc/CMSIS/SVD/html/svd_Format_pg.html
##

import std/paths
import std/strutils
import std/xmlparser
import std/xmltree

import svdtypes

func parseSvdDevice(deviceNode: XmlNode): SvdDevice
func parseCpu(cpuNode: XmlNode): ref SvdCpu
func parseSvdPeripherals(peripheralsNode: XmlNode): ref seq[SvdPeripheral]
func parseSvdPeripheral(peripheralNode: XmlNode): SvdPeripheral
func parseSvdRegisters(registersNode: XmlNode): ref seq[SvdRegister]
func parseSvdRegister(registerNode: XmlNode): SvdRegister
func parseSvdFields(fieldsNode: XmlNode): ref seq[SvdRegField]
func parseSvdField(fieldNode: XmlNode): SvdRegField

proc parseSvdFile*(fn: Path): SvdDevice =
  let xml = loadXml(fn.string)
  assert xml.tag == "device"
  result = parseSvdDevice(xml)

func parseSvdDevice(deviceNode: XmlNode): SvdDevice =
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

func parseCpu(cpuNode: XmlNode): ref SvdCpu =
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

func parseSvdPeripherals(peripheralsNode: XmlNode): ref seq[SvdPeripheral] =
  if isNil(peripheralsNode): return nil
  for pnode in peripheralsNode.findAll("peripheral"):
    result[].add(parseSvdPeripheral(pnode))

func parseSvdPeripheral(peripheralNode: XmlNode): SvdPeripheral =
  result.name = peripheralNode.child("name").innerText
  result.interrupt = parseInt(peripheralNode.child("interrupt").innerText)
  result.addressBlockOffset = parseUInt(peripheralNode.child("addressBlockOffset").innerText)
  result.addressBlockSize = parseUInt(peripheralNode.child("addressBlockSize").innerText)
  let registersNode = peripheralNode.child("registers")
  result.registers = parseSvdRegisters(registersNode)

func parseSvdRegisters(registersNode: XmlNode): ref seq[SvdRegister] =
  if isNil(registersNode): return nil
  for rnode in registersNode.findAll("peripheral"):
    result[].add(parseSvdRegister(rnode))

func parseSvdRegister(registerNode: XmlNode): SvdRegister =
  result.name = registerNode.child("name").innerText
  result.description = registerNode.child("description").innerText
  result.address = parseBiggestUInt(registerNode.child("address").innerText)
  result.resetVal = parseBiggestUInt(registerNode.child("resetVal").innerText)
  let fieldsNode = registerNode.child("fields")
  result.fields = parseSvdFields(fieldsNode)

func parseSvdFields(fieldsNode: XmlNode): ref seq[SvdRegField] =
  if isNil(fieldsNode): return nil
  for fnode in fieldsNode.findAll("field"):
    result[].add(parseSvdField(fnode))

func parseSvdField(fieldNode: XmlNode): SvdRegField =
  result.name = fieldNode.child("name").innerText
  result.description = fieldNode.child("description").innerText
  result.bitOffset = parseUInt(fieldNode.child("bitOffset").innerText)
  result.bitWidth = parseUInt(fieldNode.child("bitWidth").innerText)
  result.access = case fieldNode.child("access").innerText
    of "read-only": SvdRegFieldAccess.readOnly
    of "read-write": SvdRegFieldAccess.readWrite
    else: SvdRegFieldAccess.writeOnly
