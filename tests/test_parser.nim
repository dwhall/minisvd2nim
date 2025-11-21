import std/[tables, unittest, xmlparser]

import minisvd2nimpkg/[parser, svd_spec, svd_types]

test "parseSvdElement SHOULD parse an empty tag":
  let xml = parseXml("<device></device>")
  const svdDeviceSpec = getSpec("device")
  let el = parseSvdElement(xml, svdDeviceSpec)
  check el.name == "device"

test "parseSvdElement SHOULD parse attrs":
  let xml = parseXml("<device schemaVersion=\"3.14\"></device>")
  const svdDeviceSpec = getSpec("device")
  let el = parseSvdElement(xml, svdDeviceSpec)
  check el.attributes.len == 1
  check el.getAttr("schemaVersion").value == "3.14"

test "parseSvdElement SHOULD parse /device element":
  let xml =
    parseXml("<device><vendor>ARM Ltd.</vendor><vendorID>ARM</vendorID></device>")
  const svdDeviceSpec = getSpec("device")
  let el = parseSvdElement(xml, svdDeviceSpec)
  check el.name == "device"
  check el.elements.len == 2
  # This test is fragile, the order of elements is not guaranteed
  check "vendor" in el.elements
  check "vendorID" in el.elements

test "parseSvdElement SHOULD parse /device/cpu element":
  let xml = parseXml("<device><cpu><name>TestCPU</name></cpu></device>")
  const svdDeviceSpec = getSpec("device")
  let el = parseSvdElement(xml, svdDeviceSpec)
  check el.elements.len == 1
  #  check "cpu"
  check "name" in el.getElement("cpu").elements

test "parseSvdElement SHOULD parse peripherals element":
  let xml = parseXml(
    """<peripherals>
      <peripheral>
        <name>Timer1</name>
        <version>1.0</version>
        <description>Timer 1 is a standard timer ... </description>
        <baseAddress>0x40002000</baseAddress>
        <interrupt><name>TIM0_INT</name><value>34</value></interrupt>
      </peripheral>
    </peripherals>
    """
  )
  const spec = getSpec("peripherals")
  let el = parseSvdElement(xml, spec)
  check el.name == "peripherals"
  check el.elements.len == 1
  let periphElements = el.getElement("Timer1").elements
  check periphElements.len == 5
  for name in ["name", "version", "description", "baseAddress", "TIM0_INT"]:
    check name in periphElements

test "parseSvdElement SHOULD parse derivedFrom attribute with value":
  let xml = parseXml(
    """
  <peripherals>
    <peripheral derivedFrom="TIMER0">
      <name>TIMER1</name>
      <baseAddress>0x40010100</baseAddress>
      <interrupt>
        <name>TIMER1</name>
        <description>Timer 1 interrupt</description>
        <value>4</value>
      </interrupt>
    </peripheral>
    </peripherals>
    """
  )
  const spec = getSpec("peripherals")
  let el = parseSvdElement(xml, spec)
  check el.name == "peripherals"
  let periph = el.getElement("TIMER1")
  check periph.hasAttr("derivedFrom")
  check periph.getAttr("derivedFrom").value == "TIMER0"

test "parseSvdElement SHOULD parse registers":
  let xml = parseXml(
    """
    <registers>
      <register>
          <name>CR1</name>
          <description>Control register 1</description>
          <addressOffset>0xC</addressOffset>
          <access>read-write</access>
          <resetValue>0x0000</resetValue>
      </register>
      <register>
        <name>CR2</name>
        <description>Control register 2</description>
        <addressOffset>0x10</addressOffset>
        <access>read-write</access>
        <resetValue>0x0000</resetValue>
      </register>
    </registers>
    """
  )
  const spec = getSpec("registers")
  let el = parseSvdElement(xml, spec)
  check el.name == "registers"
  check el.elements.len == 2
  check "CR1" in el.elements
  check "CR2" in el.elements
  for key in ["CR1", "CR2"]:
    for name in ["name", "description", "addressOffset"]:
      check name in el.elements[key].elements

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
  const spec = getSpec("fields")
  let el = parseSvdElement(xml, spec)
  check el.name == "fields"
  for fieldNm in ["EN", "RST"]:
    check fieldNm in el.elements
  #check "field" in el.elements
  let field = el.getElement("RST")
  for elNm in ["name", "description", "bitRange", "access"]:
    check elNm in field.elements
