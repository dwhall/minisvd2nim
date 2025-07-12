## Copyright 2024 Dean Hall, all rights reserved.  See LICENSE.txt for details.
##
## Parses an .svd file (which is XML format) by following the SVD specification
## declared in svd_spec.nim.
##
## Reference:
##    https://open-cmsis-pack.github.io/svd-spec/main/svd_Format_pg.html
##

import std/[paths, strformat, xmlparser, xmltree]

import svdtypes, svd_spec

func addIfNotNil(elVals: var seq[SvdElementValue], el: SvdElementValue) =
  if el != nilElementValue:
    elVals.add(el)

func parseSvdAttributes(
    xml: XmlNode, specAttributes: seq[SvdAttributeSpec]
): seq[SvdElementValue] =
  for attrSpec in specAttributes:
    let attrVal = xml.attr(attrSpec.name)
    if attrSpec.isRequired and attrVal == "":
      discard # Log: required attribute is missing
    else:
      if attrVal != "":
        result.add(
          SvdElementValue(
            name: attrSpec.name, value: attrVal, dataType: attrSpec.dataType
          )
        )

func parseSvdElement*(xml: XmlNode, spec: SvdElementSpec): SvdElementValue =
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
        result.elements.addIfNotNil(elVal)
    else:
      let el = xml.child(elSpec.name)
      if elSpec.isRequired and el.isNil:
        discard # Log: required element is missing
      else:
        let elVal = parseSvdElement(el, elSpec)
        result.elements.addIfNotNil(elVal)

proc parseSvdFile*(fn: Path): SvdElementValue =
  let xml = loadXml(fn.string)
  assert xml.tag == "device"
  result = parseSvdElement(xml, svdDeviceSpec)
