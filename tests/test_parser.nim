import std/[paths, sequtils, strutils, tables, unittest, xmlparser, xmltree]

import minisvd2nimpkg/[parser, svd_spec, svdtypes]

let fn_test = getCurrentDir() / Path("tests") / Path("test.svd")

var unusedPeripheralCache = PeripheralCache()
var unusedRegisterCache = RegisterCache()

test "parseSvdElement SHOULD parse an empty tag":
  let xml = parseXml("<device></device>")
  let el =
    parseSvdElement(xml, svdDeviceSpec, unusedPeripheralCache, unusedRegisterCache)
  check el.name == "device"

test "parseSvdElement SHOULD parse attrs":
  let xml = parseXml("<device schemaVersion=\"3.14\"></device>")
  let el =
    parseSvdElement(xml, svdDeviceSpec, unusedPeripheralCache, unusedRegisterCache)
  check el.attributes.len == 1
  check el.attributes[0].name == "schemaVersion"
  check el.attributes[0].value == "3.14"

test "parseSvdElement SHOULD parse /device element":
  let xml =
    parseXml("<device><vendor>ARM Ltd.</vendor><vendorID>ARM</vendorID></device>")
  let el =
    parseSvdElement(xml, svdDeviceSpec, unusedPeripheralCache, unusedRegisterCache)
  check el.name == "device"
  check el.elements.len == 2
  # This test is fragile, the order of elements is not guaranteed
  check el.elements[0].name == "vendor"
  check el.elements[1].name == "vendorID"

test "parseSvdElement SHOULD parse /device/cpu element":
  let xml = parseXml("<device><cpu><name>TestCPU</name></cpu></device>")
  let el =
    parseSvdElement(xml, svdDeviceSpec, unusedPeripheralCache, unusedRegisterCache)
  check el.elements.len == 1
  check el.elements[0].name == "cpu"
  check el.elements[0].elements[0].name == "name"

test "parseSvdElement SHOULD parse peripherals element":
  let xml = parseXml(
    """<peripherals>
      <peripheral>
        <name>Timer1</name>
        <version>1.0</version>
        <description>Timer 1 is a standard timer ... </description>
        <baseAddress>0x40002000</baseAddress>
        <addressBlock>skip</addressBlock>
        <interrupt><name>TIM0_INT</name><value>34</value></interrupt>
      </peripheral>
    </peripherals>
    """
  )
  let spec = getSpec("peripherals")
  let el = parseSvdElement(xml, spec, unusedPeripheralCache, unusedRegisterCache)
  check el.name == "peripherals"
  check el.elements.len == 1
  check el.elements[0].name == "peripheral"
  let periphFields = el.elements[0].elements
  check periphFields.len == 6
  for name in [
    "name", "version", "description", "baseAddress", "addressBlock", "interrupt"
  ]:
    check periphFields.anyIt(it.name == name)

test "parseSvdElement SHOULD parse registers":
  let xml = parseXml(
    """<registers>
      <register>
          <name>TIM_MODEA</name>
          <description>In mode A this register acts as a reload value</description>
          <addressOffset>0xC</addressOffset>
      </register>
    </registers>
    """
  )
  let spec = getSpec("registers")
  let el = parseSvdElement(xml, spec, unusedPeripheralCache, unusedRegisterCache)
  check el.name == "registers"
  check el.elements.len == 1
  check el.elements[0].name == "register"
  let registerFields = el.elements[0].elements
  check registerFields.len == 3
  for name in ["name", "description", "addressOffset"]:
    check registerFields.anyIt(it.name == name)

test "parseSvdElement SHOULD parse fields":
  let xml = parseXml(
    """<fields>
      <field>
        <name>EN</name>
        <description>Enable</description>
        <bitRange>[0:0]</bitRange>
        <access>read-write</access>
      </field>
      <field>
        <name>RST</name>
        <description>Reset Timer</description>
        <bitRange>[1:1]</bitRange>
        <access>write-only</access>
      </field>
    </fields>
    """
  )
  let spec = getSpec("fields")
  let el = parseSvdElement(xml, spec, unusedPeripheralCache, unusedRegisterCache)
  check el.name == "fields"
  check el.elements.len == 2
  check el.elements[0].name == "field"
  let fieldFields = el.elements[0].elements
  check fieldFields.len == 4
  for name in ["name", "description", "bitRange", "access"]:
    check fieldFields.anyIt(it.name == name)
