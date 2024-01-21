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
func parseSvdCpu(cpuNode: XmlNode): ref SvdCpu
func parseSvdPeripherals(peripheralsNode: XmlNode): ref seq[SvdPeripheral]
func parseSvdPeripheral(peripheralNode: XmlNode): SvdPeripheral
func parseSvdInterrupt(interruptNode: XmlNode): ref SvdInterrupt
func parseSvdAddressBlock(addressBlockNode: XmlNode): ref SvdAddressBlock
func parseSvdRegisters(registersNode: XmlNode): ref seq[SvdRegister]
func parseSvdRegister(registerNode: XmlNode): SvdRegister
func parseSvdFields(fieldsNode: XmlNode): ref seq[SvdRegField]
func parseSvdField(fieldNode: XmlNode): SvdRegField
func parseAnyInt(s: string): int

proc parseSvdFile*(fn: Path): SvdDevice =
  let xml = loadXml(fn.string)
  assert xml.tag == "device"
  result = parseSvdDevice(xml)

func parseSvdDevice(deviceNode: XmlNode): SvdDevice =
  result.name = deviceNode.child("name").innerText
  result.description = deviceNode.child("description").innerText
  result.version = parseFloat(deviceNode.child("version").innerText)
  result.addressUnitBits = parseAnyInt(deviceNode.child("addressUnitBits").innerText)
  result.width = parseAnyInt(deviceNode.child("width").innerText)
  result.size = parseAnyInt(deviceNode.child("size").innerText)
  result.resetValue = parseHexInt(deviceNode.child("resetValue").innerText)
  result.resetMask = parseHexInt(deviceNode.child("resetMask").innerText)
  let cpuNode = deviceNode.child("cpu")
  result.cpu = parseSvdCpu(cpuNode)
  let peripheralsNode = deviceNode.child("peripherals")
  result.peripherals = parseSvdPeripherals(peripheralsNode)

func parseSvdCpu(cpuNode: XmlNode): ref SvdCpu =
  if isNil(cpuNode): return nil
  new(result)
  result.name = cpuNode.child("name").innerText
  result.revision = cpuNode.child("revision").innerText
  result.endian = if cpuNode.child("endian").innerText == "little": SvdCpuEndian.littleEndian
                  else: SvdCpuEndian.bigEndian
  result.mpuPresent = cpuNode.child("mpuPresent").innerText == "true"
  result.fpuPresent = cpuNode.child("fpuPresent").innerText == "true"
  result.nvicPrioBits = parseAnyInt(cpuNode.child("nvicPrioBits").innerText)
  result.vendorSystickConfig = cpuNode.child("vendorSystickConfig").innerText == "true"

func parseSvdPeripherals(peripheralsNode: XmlNode): ref seq[SvdPeripheral] =
  if isNil(peripheralsNode): return nil
  new(result)
  for pnode in peripheralsNode.findAll("peripheral"):
    result[].add(parseSvdPeripheral(pnode))

func parseSvdPeripheral(peripheralNode: XmlNode): SvdPeripheral =
  result.name = peripheralNode.child("name").innerText
  let interruptNode = peripheralNode.child("interrupt")
  result.interrupt = parseSvdInterrupt(interruptNode)
  let addressBlockNode = peripheralNode.child("addressBlock")
  result.addressBlock = parseSvdAddressBlock(addressBlockNode)
  let registersNode = peripheralNode.child("registers")
  result.registers = parseSvdRegisters(registersNode)

func parseSvdInterrupt(interruptNode: XmlNode): ref SvdInterrupt =
  if isNil(interruptNode): return nil
  new(result)
  result.name = interruptNode.child("name").innerText
  result.description = interruptNode.child("description").innerText
  result.value = parseAnyInt(interruptNode.child("value").innerText)

func parseSvdAddressBlock(addressBlockNode: XmlNode): ref SvdAddressBlock =
  if isNil(addressBlockNode): return nil
  new(result)
  result.offset = parseAnyInt(addressBlockNode.child("offset").innerText)
  result.size = parseAnyInt(addressBlockNode.child("size").innerText)
  result.usage = addressBlockNode.child("usage").innerText

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

func parseAnyInt(s: string): int =
  if s.startsWith("0x"):
    result = parseHexInt(s)
  else:
    result = parseInt(s)
