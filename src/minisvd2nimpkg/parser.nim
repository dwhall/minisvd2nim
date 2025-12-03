## Copyright 2024 Dean Hall, all rights reserved.  See LICENSE.txt for details.
##
## Parses an .svd file (which is XML format) by following the SVD specification
## declared in svd_spec.nim.
##
## Reference:
##    https://open-cmsis-pack.github.io/svd-spec/main/svd_Format_pg.html
##

import std/[paths, strformat, tables, xmlparser, xmltree]

import svd_types, svd_spec, segger_spec

func addIfNotNil(elVals: var OrderedTable[string, SvdElementValue], el: SvdElementValue) =
  if el != nilElementValue:
    elVals[el.name] = el

func addByNameIfNotNil(elVals: var OrderedTable[string, SvdElementValue], el: SvdElementValue) =
  if el != nilElementValue:
    let nameEl = el.getElement("name")
    if nameEl != nilElementValue:
      elVals[nameEl.value] = el

func parseSvdAttributes(
    xml: XmlNode, specAttributes: seq[SvdAttributeSpec]
): OrderedTable[string, SvdElementValue] =
  for attrSpec in specAttributes:
    let attrVal = xml.attr(attrSpec.name)
    if attrSpec.isRequired and attrVal == "":
      discard # Log: required attribute is missing
    else:
      if attrVal != "":
        result[attrSpec.name] = SvdElementValue(
          name: attrSpec.name, value: attrVal, dataType: attrSpec.dataType
        )

func parseSvdElement(xml: XmlNode, spec: SvdElementSpec): SvdElementValue =
  if xml.isNil:
    return nilElementValue
  assert xml.tag == spec.name, fmt"Expected tag '{spec.name}', got '{xml.tag}'"
  result.name = xml.tag
  result.dataType = spec.dataType
  if spec.dataType == svdElement:
    result.attributes = parseSvdAttributes(xml, spec.attributes)
  else:
    if spec.isLeaf:
      result.value = xml.innerText
  for elSpec in spec.elements:
    if elSpec.isPossiblyMoreThanOne:
      for el in xml.findAll(elSpec.name):
        let elVal = parseSvdElement(el, elSpec)
        result.elements.addByNameIfNotNil(elVal)
    else:
      let el = xml.child(elSpec.name)
      if elSpec.isRequired and el.isNil:
        discard # Log: required element is missing
      else:
        let elVal = parseSvdElement(el, elSpec)
        result.elements.addIfNotNil(elVal)

proc parseSvdFile*(fn: Path): tuple[device: SvdElementValue, deviceName: string] =
  const fileSpec = getSpec("device")
  let xml = loadXml(fn.string)
  assert xml.tag == "device"
  let device = parseSvdElement(xml, fileSpec)
  let deviceName = device.getElement("name").value
  result = (device, deviceName)

func parseSeggerElement(xml: XmlNode, spec: SvdElementSpec): SvdElementValue =
  result = parseSvdElement(xml, spec)
  result.isSeggerVariant = true

proc parseSeggerFile*(fn: Path): tuple[device: SvdElementValue, deviceName: string] =
  const fileSpec = getSeggerSpec("device")
  let xml = loadXml(fn.string)
  assert xml.tag == "device"
  let device = parseSeggerElement(xml, fileSpec)
  let deviceName = device.getElement("cpu").getElement("name").value
  result = (device, deviceName)