## Parses an .svd file (which is XML format) into a matching hierarchy of structures
##
## Reference:
##    https://www.keil.com/pack/doc/CMSIS/SVD/html/svd_Format_pg.html
##    https://www.keil.com/pack/doc/CMSIS/SVD/html/elem_registers.html#elem_fields
##

import std/[paths, strtabs, strutils, tables, xmlparser, xmltree]

import svdtypes

type PeripheralCache = Table[string, SvdPeripheral]

func parseSvdDevice(
  deviceNode: XmlNode, peripheralCache: var PeripheralCache
): SvdDevice
func parseSvdCpu(cpuNode: XmlNode): ref SvdCpu
func parseSvdPeripherals(
  peripheralsNode: XmlNode,
  peripherals: var seq[SvdPeripheral],
  peripheralCache: var PeripheralCache,
)
func parseDerivedSvdPeripheral(
  peripheralNode: XmlNode, basePeripheral: SvdPeripheral
): SvdPeripheral
func parseBaseSvdPeripheral(peripheralNode: XmlNode): SvdPeripheral
func parseSvdPeripheral(
  peripheralNode: XmlNode, peripheralCache: var PeripheralCache
): SvdPeripheral
func parseSvdInterrupts(peripheralNode: XmlNode, interrupts: var seq[SvdInterrupt])
func parseSvdInterrupt(interruptNode: XmlNode): SvdInterrupt
func parseSvdAddressBlock(addressBlockNode: XmlNode): ref SvdAddressBlock
func parseSvdRegisters(registersNode: XmlNode, registers: var seq[SvdRegister])
func parseSvdRegister(registerNode: XmlNode): SvdRegister
func parseSvdAccess(accessNode: XmlNode, access: var SvdAccess)
func parseSvdFields(fieldsNode: XmlNode, fields: var seq[SvdRegField])
func parseSvdEnumVals(enumValsNode: XmlNode, enumVals: var SvdEnumVals)
func parseSvdEnumVal(enumValNode: XmlNode): SvdEnumVal
func parseSvdField(fieldNode: XmlNode): SvdRegField
func parseSvdFieldBitRange(fieldNode: XmlNode, regField: var SvdRegField)
func parseAnyInt(s: string): int
func parseBinaryInt(s: string): int
func removeWhitespace(s: string): string

proc parseSvdFile*(fn: Path): SvdDevice =
  var peripheralCache: PeripheralCache
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
  result.resetValue = parseHexInt(deviceNode.child("resetValue").innerText).uint32
  result.resetMask = parseHexInt(deviceNode.child("resetMask").innerText).uint32
  let cpuNode = deviceNode.child("cpu")
  result.cpu = parseSvdCpu(cpuNode)
  let peripheralsNode = deviceNode.child("peripherals")
  parseSvdPeripherals(peripheralsNode, result.peripherals, peripheralCache)

func parseSvdCpu(cpuNode: XmlNode): ref SvdCpu =
  if isNil(cpuNode):
    return nil
  new(result)
  result.name = cpuNode.child("name").innerText
  result.revision = cpuNode.child("revision").innerText
  result.endian =
    if cpuNode.child("endian").innerText == "little": littleEndian else: bigEndian
  result.mpuPresent = cpuNode.child("mpuPresent").innerText == "true"
  result.fpuPresent = cpuNode.child("fpuPresent").innerText == "true"
  result.nvicPrioBits = parseAnyInt(cpuNode.child("nvicPrioBits").innerText)
  result.vendorSystickConfig = cpuNode.child("vendorSystickConfig").innerText == "true"

func parseSvdPeripherals(
    peripheralsNode: XmlNode,
    peripherals: var seq[SvdPeripheral],
    peripheralCache: var PeripheralCache,
) =
  if isNil(peripheralsNode):
    return
  for pnode in peripheralsNode.findAll("peripheral"):
    peripherals.add(parseSvdPeripheral(pnode, peripheralCache))

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
      # TODO: determine if derivedFrom can apply to an already-derived peripheral.  If so, unindent so derived peripherals go into the cache.

func parseDerivedSvdPeripheral(
    peripheralNode: XmlNode, basePeripheral: SvdPeripheral
): SvdPeripheral =
  result = basePeripheral # copy
  # The name and baseAddress fields MUST be differentiated from the base peripheral
  result.name = peripheralNode.child("name").innerText
  result.baseAddress = parseAnyInt(peripheralNode.child("baseAddress").innerText).uint32
  # The following fields are optionally differentiated from the base peripheral
  let descNode = peripheralNode.child("description")
  if not isNil(descNode):
    result.description = removeWhitespace(peripheralNode.child("description").innerText)
  let irqNode = peripheralNode.child("interrupt")
  if not isNil(irqNode):
    result.interrupts.setLen(0)
    parseSvdInterrupts(peripheralNode, result.interrupts)
  let addressBlockNode = peripheralNode.child("addressBlock")
  result.addressBlock = parseSvdAddressBlock(addressBlockNode)
  # Do not differentiate registers (that's the whole reason for SVD's "derivedFrom")

func parseBaseSvdPeripheral(peripheralNode: XmlNode): SvdPeripheral =
  result.name = peripheralNode.child("name").innerText
  result.baseAddress = parseAnyInt(peripheralNode.child("baseAddress").innerText).uint32
  result.description = removeWhitespace(peripheralNode.child("description").innerText)
  parseSvdInterrupts(peripheralNode, result.interrupts)
  let addressBlockNode = peripheralNode.child("addressBlock")
  result.addressBlock = parseSvdAddressBlock(addressBlockNode)
  let registersNode = peripheralNode.child("registers")
  parseSvdRegisters(registersNode, result.registers)

func parseSvdInterrupts(peripheralNode: XmlNode, interrupts: var seq[SvdInterrupt]) =
  for irqNode in peripheralNode.findAll("interrupt"):
    interrupts.add(parseSvdInterrupt(irqNode))

func parseSvdInterrupt(interruptNode: XmlNode): SvdInterrupt =
  if isNil(interruptNode):
    return
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

func parseSvdRegisters(registersNode: XmlNode, registers: var seq[SvdRegister]) =
  if isNil(registersNode):
    return
  for rnode in registersNode.findAll("register"):
    registers.add(parseSvdRegister(rnode))

func parseSvdRegister(registerNode: XmlNode): SvdRegister =
  result.name = registerNode.child("name").innerText
  result.description = removeWhitespace(registerNode.child("description").innerText)
  result.addressOffset = parseAnyInt(registerNode.child("addressOffset").innerText)
  result.resetValue = parseAnyInt(registerNode.child("resetValue").innerText).uint32
  let accessNode = registerNode.child("access")
  parseSvdAccess(accessNode, result.access)
  let fieldsNode = registerNode.child("fields")
  parseSvdFields(fieldsNode, result.fields)

func parseSvdAccess(accessNode: XmlNode, access: var SvdAccess) =
  let accessText = if isNil(accessNode): "read-only" else: accessNode.innerText
  access =
    case accessText
    of "write-only": SvdAccess.writeOnly
    of "read-write": SvdAccess.readWrite
    else: SvdAccess.readOnly

func parseSvdFields(fieldsNode: XmlNode, fields: var seq[SvdRegField]) =
  if isNil(fieldsNode):
    return
  for fnode in fieldsNode.findAll("field"):
    fields.add(parseSvdField(fnode))

func parseSvdField(fieldNode: XmlNode): SvdRegField =
  result.name = fieldNode.child("name").innerText
  result.description = removeWhitespace(fieldNode.child("description").innerText)
  parseSvdFieldBitRange(fieldNode, result)
  let accessNode = fieldNode.child("access")
  parseSvdAccess(accessNode, result.access)
  let enumNode = fieldNode.child("enumeratedValues")
  parseSvdEnumVals(enumNode, result.enumVals)

func parseSvdFieldBitRange(fieldNode: XmlNode, regField: var SvdRegField) =
  let offsetNode = fieldNode.child("bitOffset")
  let lsbNode = fieldNode.child("lsb")
  let bitRangeNode = fieldNode.child("bitRange")
  if not isNil(offsetNode):
    regField.bitOffset = parseInt(offsetNode.innerText)
    regField.bitWidth = parseInt(fieldNode.child("bitWidth").innerText)
  elif not isNil(lsbNode):
    let msb = parseInt(fieldNode.child("msb").innerText)
    let lsb = parseInt(lsbNode.innerText)
    regField.bitOffset = lsb
    regField.bitWidth = msb - lsb + 1
  elif not isNil(bitRangeNode):
    let rangeText = bitRangeNode.innerText
    let colonIndex = rangeText.find(':')
    let msb = parseInt(removeWhitespace(rangeText[1 ..< colonIndex]))
    let lsb = parseInt(removeWhitespace(rangeText[(colonIndex + 1) ..< (rangeText.len - 1)]))
    regField.bitOffset = lsb
    regField.bitWidth = msb - lsb + 1

func parseSvdEnumVals(enumValsNode: XmlNode, enumVals: var SvdEnumVals) =
  if isNil(enumValsNode):
    return
  let name = enumValsNode.child("name")
  if not isNil(name):
    enumVals.name = name.innerText
  let accessNode = enumValsNode.child("access")
  parseSvdAccess(accessNode, enumVals.usage)
  for enode in enumValsNode.findAll("enumeratedValue"):
    enumVals.enumVals.add(parseSvdEnumVal(enode))

func parseSvdEnumVal(enumValNode: XmlNode): SvdEnumVal =
  result.name = enumValNode.child("name").innerText
  result.description = removeWhitespace(enumValNode.child("description").innerText)
  let isDefault = enumValNode.child("isDefault")
  if not isNil(isDefault):
    result.isDefault = isDefault.innerText.toLower == "true"
  else:
    result.value = parseInt(enumValNode.child("value").innerText).uint32

func parseAnyInt(s: string): int =
  let lowercase = s.toLower()
  if lowercase.startsWith("0x"):
    result = parseHexInt(lowercase).int
  elif lowercase.startsWith("0b"):
    result = parseBinaryInt(lowercase[2..^1])
  elif lowercase.startsWith("#"):
    result = parseBinaryInt(lowercase[1..^1])
  else:
    result = parseInt(lowercase).int

func parseBinaryInt(s: string): int =
  ## Argument, s, must have any prefix removed so that s[0] is '0' or '1'
  if 'x' in s:
    # side effect: stderr.write("Don't care bits in enum values are not yet supported.\n")
    result = -1
  else:
    result = parseBinInt(s)

func removeWhitespace(s: string): string =
  result = join(s.splitWhitespace(), " ")
