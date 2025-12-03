#!fmt: off
## Copyright 2025 Dean Hall, all rights reserved.  See LICENSE.txt for details.
##
## SVD specification declarations
## Open-CMSIS-SVD  Version 1.3.10-dev17
## https://open-cmsis-pack.github.io/svd-spec/main/svd_Format_pg.html
##

import std/tables
import svd_spec, svd_types

const
  svdFieldSpec = getSpec("field")
  svdFieldsSpec = getSpec("fields")
  svdRegisterSpec = getSpec("register")
  svdRegistersSpec = getSpec("registers")
  svdPeripheralSpec = getSpec("peripheral")
  svdPeripheralsSpec = getSpec("peripherals")

  groupSpec = SvdElementSpec(
    name: "group",
    dataType: svdElementGroup,
    occurance: oneOrMore,
    elements: @[
      SvdElementSpec(name: "name", dataType: svdString, occurance: exactlyOne),
      SvdElementSpec(name: "description", dataType: svdString, occurance: exactlyOne),
      SvdElementSpec(name: "size", dataType: svdNonNegativeInt, occurance: exactlyOne),
      SvdElementSpec(name: "access", dataType: svdAccess, occurance: exactlyOne),
      svdPeripheralsSpec,
    ]
  )

  groupsSpec = SvdElementSpec(
    name: "groups",
    dataType: svdElementGroup,
    occurance: zeroOrOne,
    elements: @[
      groupSpec
    ]
  )

  cpuSpec = SvdElementSpec(
    name: "cpu",
    dataType: svdElement,
    occurance: zeroOrOne,
    elements: @[
      SvdElementSpec(name: "name", dataType: svdString, occurance: exactlyOne),
      SvdElementSpec(name: "displayName", dataType: svdString, occurance: exactlyOne),
      groupsSpec,
    ],
  )

  deviceSpec = SvdElementSpec(
    name: "device",
    dataType: svdElement,
    occurance: exactlyOne,
    elements: @[
      cpuSpec,
    ]
  )

func getSeggerSpec*(name: static string): SvdElementSpec =
  const nameToSpec = {
    "device": deviceSpec,
    "cpu": cpuSpec,
    "groups": groupsSpec,
    "group": groupSpec,
  }.toTable
  result = nameToSpec.getOrDefault(name, getSpec(name))
