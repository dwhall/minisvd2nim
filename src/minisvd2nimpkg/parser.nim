## Copyright 2024 Dean Hall, all rights reserved.  See LICENSE.txt for details.
##
## Parses an .svd file (which is XML format) into a matching hierarchy of structures
##
## Reference:
##    https://open-cmsis-pack.github.io/svd-spec/main/svd_Format_pg.html
##

import std/[paths, strformat, strtabs, strutils, tables, xmlparser, xmltree]

import svdtypes

type PeripheralCache = Table[string, SvdPeripheral]
type RegisterCache = Table[string, SvdRegister]

func parseSvdDevice(
  deviceNode: XmlNode,
  peripheralCache: var PeripheralCache,
  registerCache: var RegisterCache,
): SvdDevice
func parseSvdCpu(cpuNode: XmlNode): ref SvdCpu
func parseSvdPeripherals(
  peripheralsNode: XmlNode,
  peripherals: var seq[SvdPeripheral],
  peripheralCache: var PeripheralCache,
  registerCache: var RegisterCache,
)
func parseSvdDerivedPeripheral(
  peripheralNode: XmlNode, basePeripheral: SvdPeripheral
): SvdPeripheral
func parseSvdDistinctPeripheral(
  peripheralNode: XmlNode, registerCache: var RegisterCache
): SvdPeripheral
func parseSvdPeripheral(
  peripheralNode: XmlNode,
  peripheralCache: var PeripheralCache,
  registerCache: var RegisterCache,
): SvdPeripheral
func parseSvdInterrupts(peripheralNode: XmlNode, interrupts: var seq[SvdInterrupt])
func parseSvdInterrupt(interruptNode: XmlNode): SvdInterrupt
func parseSvdAddressBlock(addressBlockNode: XmlNode): ref SvdAddressBlock
func parseSvdRegisters(
  registersNode: XmlNode,
  registers: var seq[SvdRegister],
  registerCache: var RegisterCache,
)
func parseSvdRegister(
  registerNode: XmlNode, registerCache: var RegisterCache
): SvdRegister
func parseSvdDistinctRegister(registerNode: XmlNode): SvdRegister
func parseSvdDerivedRegister(
  registerNode: XmlNode, derivedFrom: SvdRegister
): SvdRegister
func parseSvdAccess(accessNode: XmlNode, access: var SvdAccess)
func parseSvdFields(fieldsNode: XmlNode, fields: var seq[SvdRegField])
func parseSvdFieldEnum(enumValsNode: XmlNode, enumeratedValues: var SvdFieldEnum)
func parseSvdEnumValue(enumValNode: XmlNode): SvdEnumVal
func parseSvdField(fieldNode: XmlNode): SvdRegField
func parseSvdFieldBitRange(fieldNode: XmlNode, regField: var SvdRegField)
func parseAnyInt(s: string): int
func parseBinaryInt(s: string): int
func removeWhitespace(s: string): string

proc parseSvdFile*(fn: Path): SvdDevice =
  var peripheralCache: PeripheralCache
  var registerCache: RegisterCache
  let xml = loadXml(fn.string)
  assert xml.tag == "device"
  result = parseSvdDevice(xml, peripheralCache, registerCache)

func parseSvdDevice(
    deviceNode: XmlNode,
    peripheralCache: var PeripheralCache,
    registerCache: var RegisterCache,
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
  parseSvdPeripherals(
    peripheralsNode, result.peripherals, peripheralCache, registerCache
  )
  let accessNode = deviceNode.child("access")
  let accessText = if isNil(accessNode): "read-only" else: accessNode.innerText
  result.access =
    case accessText
    of "write-only": SvdAccess.writeOnly
    of "read-write": SvdAccess.readWrite
    else: SvdAccess.readOnly

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
    registerCache: var RegisterCache,
) =
  if isNil(peripheralsNode):
    return
  for pnode in peripheralsNode.findAll("peripheral"):
    peripherals.add(parseSvdPeripheral(pnode, peripheralCache, registerCache))

func parseSvdPeripheral(
    peripheralNode: XmlNode,
    peripheralCache: var PeripheralCache,
    registerCache: var RegisterCache,
): SvdPeripheral =
  let pattrs = peripheralNode.attrs()
  if not isNil(pattrs) and "derivedFrom" in pattrs:
    let basePeripheral = peripheralCache[pattrs["derivedFrom"]]
    result = parseSvdDerivedPeripheral(peripheralNode, basePeripheral)
  else:
    result = parseSvdDistinctPeripheral(peripheralNode, registerCache)
    peripheralCache[result.name] = result
      # TODO: determine if derivedFrom can apply to an already-derived peripheral.  If so, unindent so derived peripherals go into the cache.

func parseSvdDerivedPeripheral(
    peripheralNode: XmlNode, basePeripheral: SvdPeripheral
): SvdPeripheral =
  result = basePeripheral # copy
  # The name and baseAddress fields MUST be differentiated from the base peripheral
  result.name = peripheralNode.child("name").innerText
  result.baseAddress = parseAnyInt(peripheralNode.child("baseAddress").innerText).uint32
  # The following fields are optionally differentiated from the base peripheral
  let descNode = peripheralNode.child("description")
  if not isNil(descNode):
    result.description = removeWhitespace(descNode.innerText)
  let irqNode = peripheralNode.child("interrupt")
  if not isNil(irqNode):
    result.interrupt.setLen(0)
    parseSvdInterrupts(peripheralNode, result.interrupt)
  let addressBlockNode = peripheralNode.child("addressBlock")
  result.addressBlock = parseSvdAddressBlock(addressBlockNode)
  # Do not differentiate registers (that's the whole reason for SVD's "derivedFrom" peripherals)

func parseSvdDistinctPeripheral(
    peripheralNode: XmlNode, registerCache: var RegisterCache
): SvdPeripheral =
  result.name = peripheralNode.child("name").innerText
  result.baseAddress = parseAnyInt(peripheralNode.child("baseAddress").innerText).uint32
  let descNode = peripheralNode.child("description")
  if not isNil(descNode):
    result.description = removeWhitespace(descNode.innerText)
  parseSvdInterrupts(peripheralNode, result.interrupt)
  let addressBlockNode = peripheralNode.child("addressBlock")
  result.addressBlock = parseSvdAddressBlock(addressBlockNode)
  let registersNode = peripheralNode.child("registers")
  parseSvdRegisters(registersNode, result.registers, registerCache)

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

iterator parseSvdRegisterGroup(registerNode: XmlNode, reg: SvdRegister): SvdRegister =
  assert len(reg.name) > len("[%s]")
  let dim = registerNode.child("dim")
  let dimIncrement = registerNode.child("dimIncrement")
  if not isNil(dim) and not isNil(dimIncrement):
    let dimIndex = registerNode.child("dimIndex")
    let regRootName = reg.name[0 ..< ^len("[%s]")]
    let dimVal = dim.innerText.parseAnyInt
    let dimIncrementVal = dimIncrement.innerText.parseAnyInt
    var nameIndex: int = if isNil dimIndex: 0 else: dimIndex.innerText.parseAnyInt
    var offset = 0
    for i in 0 ..< dimVal:
      var r = reg # copy
      r.name = fmt"{regRootName}{nameIndex}"
      inc nameIndex
      r.addressOffset = reg.addressOffset + offset
      offset += dimIncrementVal
      yield r

func parseSvdRegisters(
    registersNode: XmlNode,
    registers: var seq[SvdRegister],
    registerCache: var RegisterCache,
) =
  if isNil(registersNode):
    return
  for rnode in registersNode.findAll("register"):
    let reg = parseSvdRegister(rnode, registerCache)
    if reg.name.endsWith("[%s]"):
      for r in parseSvdRegisterGroup(rnode, reg):
        registers.add(r)
    else:
      registers.add(reg)

func parseSvdRegister(
    registerNode: XmlNode, registerCache: var RegisterCache
): SvdRegister =
  let pattrs = registerNode.attrs()
  if not isNil(pattrs) and "derivedFrom" in pattrs:
    let derivedFrom = registerCache[pattrs["derivedFrom"]]
    result = parseSvdDerivedRegister(registerNode, derivedFrom)
  else:
    result = parseSvdDistinctRegister(registerNode)
    registerCache[result.name] = result
      # TODO: determine if derivedFrom can apply to an already-derived peripheral.  If so, unindent so derived registers go into the cache.

func parseSvdDerivedRegister(
    registerNode: XmlNode, derivedFrom: SvdRegister
): SvdRegister =
  result = derivedFrom # copy
  result.derivedFrom = derivedFrom.name
  # The name, baseAddress and fields MUST be differentiated from the base register
  result.name = registerNode.child("name").innerText
  result.addressOffset = parseAnyInt(registerNode.child("addressOffset").innerText)
  let fieldsNode = registerNode.child("fields")
  parseSvdFields(fieldsNode, result.fields)
  # TODO: The following fields are optionally differentiated from the base register

func parseSvdDistinctRegister(registerNode: XmlNode): SvdRegister =
  result = SvdRegister()
  result.name = registerNode.child("name").innerText
  result.addressOffset = parseAnyInt(registerNode.child("addressOffset").innerText)
  let descriptionNode = registerNode.child("description")
  if not isNil(descriptionNode):
    result.description = removeWhitespace(descriptionNode.innerText)
  let resetValueNode = registerNode.child("resetValue")
  if not isNil(resetValueNode):
    result.resetValue = parseAnyInt(resetValueNode.innerText).uint32
  let accessNode = registerNode.child("access")
  parseSvdAccess(accessNode, result.access)
  let fieldsNode = registerNode.child("fields")
  parseSvdFields(fieldsNode, result.fields)
  let dimNode = registerNode.child("dim")

func parseSvdAccess(accessNode: XmlNode, access: var SvdAccess) =
  # TODO: change "read-only" to parse-context's device.access
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
  let descriptionNode = fieldNode.child("description")
  if not isNil(descriptionNode):
    result.description = removeWhitespace(descriptionNode.innerText)
  parseSvdFieldBitRange(fieldNode, result)
  let accessNode = fieldNode.child("access")
  parseSvdAccess(accessNode, result.access)
  let enumNode = fieldNode.child("enumeratedValues")
  parseSvdFieldEnum(enumNode, result.enumeratedValues)

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
    let lsb =
      parseInt(removeWhitespace(rangeText[(colonIndex + 1) ..< (rangeText.len - 1)]))
    regField.bitOffset = lsb
    regField.bitWidth = msb - lsb + 1

func parseSvdFieldEnum(enumValsNode: XmlNode, enumeratedValues: var SvdFieldEnum) =
  if isNil(enumValsNode):
    return
  let name = enumValsNode.child("name")
  if not isNil(name):
    enumeratedValues.name = name.innerText
  let accessNode = enumValsNode.child("access")
  parseSvdAccess(accessNode, enumeratedValues.access)
  for enode in enumValsNode.findAll("enumeratedValue"):
    enumeratedValues.values.add(parseSvdEnumValue(enode))

func parseSvdEnumValue(enumValNode: XmlNode): SvdEnumVal =
  result.name = enumValNode.child("name").innerText
  let descNode = enumValNode.child("description")
  if not isNil(descNode):
    result.description = removeWhitespace(descNode.innerText)
  let isDefault = enumValNode.child("isDefault")
  if not isNil(isDefault):
    result.isDefault = isDefault.innerText.toLower() == "true"
  else:
    result.value = parseInt(enumValNode.child("value").innerText).uint32

func parseAnyInt(s: string): int =
  let lowercase = s.toLower()
  if lowercase.startsWith("0x"):
    result = parseHexInt(lowercase)
  elif lowercase.startsWith("0b"):
    result = parseBinaryInt(lowercase[2 ..^ 1])
  elif lowercase.startsWith("#"):
    result = parseBinaryInt(lowercase[1 ..^ 1])
  else:
    result = parseInt(lowercase)

func parseBinaryInt(s: string): int =
  ## Argument, s, must have any prefix removed so that s[0] is '0' or '1'
  if 'x' in s:
    # side effect: stderr.write("Don't care bits in enum value strings are not yet supported.\n")
    result = -1
  else:
    result = parseBinInt(s)

func removeWhitespace(s: string): string =
  result = join(s.splitWhitespace(), " ")
