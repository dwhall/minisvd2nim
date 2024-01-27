## Parses an .svd file (which is XML format) into a matching hierarchy of structures
##
## Reference:
##    https://www.keil.com/pack/doc/CMSIS/SVD/html/svd_Format_pg.html
##

import std/paths
import std/strtabs
import std/strutils
import std/tables
import std/xmlparser
import std/xmltree

import svdtypes

type PeripheralCache = TableRef[string, SvdPeripheral]

func parseSvdDevice(
  deviceNode: XmlNode, peripheralCache: var PeripheralCache
): SvdDevice
func parseSvdCpu(cpuNode: XmlNode): ref SvdCpu
func parseSvdPeripherals(
  peripheralsNode: XmlNode, peripheralCache: var PeripheralCache
): ref seq[SvdPeripheral]
func parseDerivedSvdPeripheral(
  peripheralNode: XmlNode, basePeripheral: SvdPeripheral
): SvdPeripheral
func parseBaseSvdPeripheral(peripheralNode: XmlNode): SvdPeripheral
func parseSvdPeripheral(
  peripheralNode: XmlNode, peripheralCache: var PeripheralCache
): SvdPeripheral
func parseSvdInterrupts(peripheralNode: XmlNode): ref seq[SvdInterrupt]
func parseSvdInterrupt(interruptNode: XmlNode): SvdInterrupt
func parseSvdAddressBlock(addressBlockNode: XmlNode): ref SvdAddressBlock
func parseSvdRegisters(registersNode: XmlNode): ref seq[SvdRegister]
func parseSvdRegister(registerNode: XmlNode): SvdRegister
func parseSvdFields(fieldsNode: XmlNode): ref seq[SvdRegField]
func parseSvdField(fieldNode: XmlNode): SvdRegField
func parseAnyInt(s: string): int
func parseAnyUInt(s: string): uint
func removeWhitespace(s: string): string

proc parseSvdFile*(fn: Path): SvdDevice =
  var peripheralCache: PeripheralCache = newTable[string, SvdPeripheral]()
  let xml = loadXml(fn.string)
  assert xml.tag == "device"
  result = parseSvdDevice(xml, peripheralCache)

func parseSvdDevice(
    deviceNode: XmlNode, peripheralCache: var PeripheralCache
): SvdDevice =
  result.name = deviceNode.child("name").innerText
  result.description = removeWhitespace(deviceNode.child("description").innerText)
  result.version = parseFloat(deviceNode.child("version").innerText)
  result.addressUnitBits = parseAnyInt(deviceNode.child("addressUnitBits").innerText)
  result.width = parseAnyInt(deviceNode.child("width").innerText)
  result.size = parseAnyInt(deviceNode.child("size").innerText)
  result.resetValue = parseHexInt(deviceNode.child("resetValue").innerText)
  result.resetMask = parseHexInt(deviceNode.child("resetMask").innerText)
  let cpuNode = deviceNode.child("cpu")
  result.cpu = parseSvdCpu(cpuNode)
  let peripheralsNode = deviceNode.child("peripherals")
  result.peripherals = parseSvdPeripherals(peripheralsNode, peripheralCache)

func parseSvdCpu(cpuNode: XmlNode): ref SvdCpu =
  if isNil(cpuNode):
    return nil
  new(result)
  result.name = cpuNode.child("name").innerText
  result.revision = cpuNode.child("revision").innerText
  result.endian =
    if cpuNode.child("endian").innerText == "little":
      SvdCpuEndian.littleEndian
    else:
      SvdCpuEndian.bigEndian
  result.mpuPresent = cpuNode.child("mpuPresent").innerText == "true"
  result.fpuPresent = cpuNode.child("fpuPresent").innerText == "true"
  result.nvicPrioBits = parseAnyInt(cpuNode.child("nvicPrioBits").innerText)
  result.vendorSystickConfig = cpuNode.child("vendorSystickConfig").innerText == "true"

func parseSvdPeripherals(
    peripheralsNode: XmlNode, peripheralCache: var PeripheralCache
): ref seq[SvdPeripheral] =
  if isNil(peripheralsNode):
    return nil
  new(result)
  for pnode in peripheralsNode.findAll("peripheral"):
    result[].add(parseSvdPeripheral(pnode, peripheralCache))

func parseSvdPeripheral(
    peripheralNode: XmlNode, peripheralCache: var PeripheralCache
): SvdPeripheral =
  let pattrs = peripheralNode.attrs()
  if not isNil(pattrs) and "derivedFrom" in pattrs:
    let basePeripheral = peripheralCache[pattrs["derivedFrom"]]
    result = parseDerivedSvdPeripheral(peripheralNode, basePeripheral)
  else:
    result = parseBaseSvdPeripheral(peripheralNode)
    peripheralCache[result.name] = result

func parseDerivedSvdPeripheral(
    peripheralNode: XmlNode, basePeripheral: SvdPeripheral
): SvdPeripheral =
  result = basePeripheral # copy
  # FIXME: parse all children of the derived peripheral
  result.name = peripheralNode.child("name").innerText
  result.baseAddress = parseAnyUInt(peripheralNode.child("baseAddress").innerText)

func parseBaseSvdPeripheral(peripheralNode: XmlNode): SvdPeripheral =
  result.name = peripheralNode.child("name").innerText
  result.baseAddress = parseAnyUInt(peripheralNode.child("baseAddress").innerText)
  result.description = removeWhitespace(peripheralNode.child("description").innerText)
  result.interrupts = parseSvdInterrupts(peripheralNode)
  let addressBlockNode = peripheralNode.child("addressBlock")
  result.addressBlock = parseSvdAddressBlock(addressBlockNode)
  let registersNode = peripheralNode.child("registers")
  result.registers = parseSvdRegisters(registersNode)

func parseSvdInterrupts(peripheralNode: XmlNode): ref seq[SvdInterrupt] =
  new(result)
  for irqNode in peripheralNode.findAll("interrupt"):
    result[].add(parseSvdInterrupt(irqNode))

func parseSvdInterrupt(interruptNode: XmlNode): SvdInterrupt =
  result.name = interruptNode.child("name").innerText
  result.description = removeWhitespace(interruptNode.child("description").innerText)
  result.value = parseAnyInt(interruptNode.child("value").innerText)

func parseSvdAddressBlock(addressBlockNode: XmlNode): ref SvdAddressBlock =
  if isNil(addressBlockNode):
    return nil
  new(result)
  result.offset = parseAnyInt(addressBlockNode.child("offset").innerText)
  result.size = parseAnyInt(addressBlockNode.child("size").innerText)
  result.usage = addressBlockNode.child("usage").innerText

func parseSvdRegisters(registersNode: XmlNode): ref seq[SvdRegister] =
  if isNil(registersNode):
    return nil
  new(result)
  for rnode in registersNode.findAll("register"):
    result[].add(parseSvdRegister(rnode))

func parseSvdRegister(registerNode: XmlNode): SvdRegister =
  result.name = registerNode.child("name").innerText
  result.description = removeWhitespace(registerNode.child("description").innerText)
  result.addressOffset = parseAnyInt(registerNode.child("addressOffset").innerText)
  result.resetValue = parseAnyInt(registerNode.child("resetValue").innerText)
  let fieldsNode = registerNode.child("fields")
  result.fields = parseSvdFields(fieldsNode)

func parseSvdFields(fieldsNode: XmlNode): ref seq[SvdRegField] =
  if isNil(fieldsNode):
    return nil
  new(result)
  for fnode in fieldsNode.findAll("field"):
    result[].add(parseSvdField(fnode))

func parseSvdField(fieldNode: XmlNode): SvdRegField =
  result.name = fieldNode.child("name").innerText
  result.description = removeWhitespace(fieldNode.child("description").innerText)
  result.bitOffset = parseInt(fieldNode.child("bitOffset").innerText)
  result.bitWidth = parseInt(fieldNode.child("bitWidth").innerText)
  let
    accessText =
      if isNil(fieldNode.child("access")):
        "read-only"
      else:
        fieldNode.child("access").innerText
  result.access =
    case accessText
    of "read-only":
      SvdRegFieldAccess.readOnly
    of "read-write":
      SvdRegFieldAccess.readWrite
    else:
      SvdRegFieldAccess.writeOnly

func parseAnyInt(s: string): int =
  let lowercase = s.toLower()
  if lowercase.startsWith("0x"):
    result = parseHexInt(lowercase)
  else:
    result = parseInt(lowercase)

func parseAnyUInt(s: string): uint =
  let lowercase = s.toLower()
  if lowercase.startsWith("0x"):
    result = cast[uint](parseHexInt(lowercase))
  else:
    result = parseUInt(s)

func removeWhitespace(s: string): string =
  result = join(s.splitWhitespace(), " ")