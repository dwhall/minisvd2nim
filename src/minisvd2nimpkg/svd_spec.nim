#!fmt: off
## Copyright 2025 Dean Hall, all rights reserved.  See LICENSE.txt for details.
##
## SVD specification declarations
## Open-CMSIS-SVD  Version 1.3.10-dev17
## https://open-cmsis-pack.github.io/svd-spec/main/svd_Format_pg.html
##

import std/tables
import svdtypes

const
  svdDerivedFromAttrSpec = SvdAttributeSpec(
    name: "derivedFrom",
    dataType: svdIdentifier,
    occurance: zeroOrOne
  )

  svdCpuSpec = SvdElementSpec(
    name: "cpu",
    dataType: svdElement,
    occurance: zeroOrOne,
    elements: @[
      SvdElementSpec(name: "name", dataType: svdString, occurance: exactlyOne),
      SvdElementSpec(name: "revision", dataType: svdRevision, occurance: exactlyOne),
      SvdElementSpec(name: "endian", dataType: svdEndian, occurance: exactlyOne),
      SvdElementSpec(name: "mpuPresent", dataType: svdBool, occurance: exactlyOne),
      SvdElementSpec(name: "fpuPresent", dataType: svdBool, occurance: exactlyOne),
      SvdElementSpec(name: "fpuDP", dataType: svdBool, occurance: zeroOrOne),
      SvdElementSpec(name: "dspPresent", dataType: svdBool, occurance: zeroOrOne),
      SvdElementSpec(name: "icachePresent", dataType: svdBool, occurance: zeroOrOne),
      SvdElementSpec(name: "dcachePresent", dataType: svdBool, occurance: zeroOrOne),
      SvdElementSpec(name: "itcmPresent", dataType: svdBool, occurance: zeroOrOne),
      SvdElementSpec(name: "dtcmPresent", dataType: svdBool, occurance: zeroOrOne),
      SvdElementSpec(name: "vtorPresent", dataType: svdBool, occurance: zeroOrOne),
      SvdElementSpec(name: "nvicPrioBits", dataType: svdNonNegativeInt, occurance: exactlyOne),
      SvdElementSpec(name: "vendorSystickConfig", dataType: svdBool, occurance: exactlyOne),
      SvdElementSpec(name: "deviceNumInterrupts", dataType: svdNonNegativeInt, occurance: zeroOrOne),
      SvdElementSpec(name: "sauNumRegions", dataType: svdNonNegativeInt, occurance: zeroOrOne),
      #SvdElementSpec(name: "sauRegionsConfig", dataType: svdSauRegionsConfig, occurance: zeroOrOne), # Not yet supported
    ],
  )

  svdAddressBlockSpec = SvdElementSpec(
    name: "addressBlock",
    dataType: svdElement,
    occurance: zeroOrMore,
    elements: @[
      SvdElementSpec(name: "offset", dataType: svdNonNegativeInt, occurance: exactlyOne),
      SvdElementSpec(name: "size", dataType: svdNonNegativeInt, occurance: exactlyOne),
      SvdElementSpec(name: "usage", dataType: svdAddressBlockUsage, occurance: exactlyOne),
      SvdElementSpec(name: "protection", dataType: svdString, occurance: zeroOrOne),
    ]
  )

  svdInterruptSpec = SvdElementSpec(
    name: "interrupt",
    dataType: svdElement,
    occurance: zeroOrMore,
    elements: @[
      SvdElementSpec(name: "name", dataType: svdString, occurance: exactlyOne),
      SvdElementSpec(name: "description", dataType: svdString, occurance: zeroOrOne),
      SvdElementSpec(name: "value", dataType: svdInt, occurance: exactlyOne),
    ]
  )

  svdFieldSpec = SvdElementSpec(
    name: "field",
    dataType: svdElement,
    occurance: oneOrMore,
    attributes: @[svdDerivedFromAttrSpec],
    elements: @[
      # BEGIN Dim element group
      SvdElementSpec(name: "dim", dataType: svdNonNegativeInt, occurance: exactlyOne),
      SvdElementSpec(name: "dimIncrement", dataType: svdNonNegativeInt, occurance: exactlyOne),
      SvdElementSpec(name: "dimIndex", dataType: svdDimIndexType, occurance: zeroOrOne),
      SvdElementSpec(name: "dimName", dataType: svdIdentifier, occurance: zeroOrOne),
      SvdElementSpec(name: "dimArrayIndex", dataType: svdDimArrayIndexType, occurance: zeroOrOne),
      # END
      SvdElementSpec(name: "name", dataType: svdIdentifier, occurance: exactlyOne),
      SvdElementSpec(name: "description", dataType: svdString, occurance: zeroOrOne),
      # BEGIN Choice of:
      # 1 of 3:
      SvdElementSpec(name: "bitOffset", dataType: svdNonNegativeInt, occurance: zeroOrOne), # spec says: exactlyOne),
      SvdElementSpec(name: "bitWidth", dataType: svdNonNegativeInt, occurance: zeroOrOne), # spec says: exactlyOne),
      # 2 of 3:
      SvdElementSpec(name: "lsb", dataType: svdNonNegativeInt, occurance: zeroOrOne), # spec says: exactlyOne),
      SvdElementSpec(name: "msb", dataType: svdNonNegativeInt, occurance: zeroOrOne), # spec says: exactlyOne),
      # 3 of 3:
      SvdElementSpec(name: "bitRange", dataType: svdBitRange, occurance: zeroOrOne), # spec says: exactlyOne),
      # END
      SvdElementSpec(name: "access", dataType: svdAccess, occurance: zeroOrOne),
      SvdElementSpec(name: "modifiedWriteValues", dataType: svdModifiedWriteValues, occurance: zeroOrOne),
      #SvdElementSpec(name: "writeConstraint", dataType: svdElement, occurance: zeroOrOne), # Not yet supported
      SvdElementSpec(name: "readAction", dataType: svdReadAction, occurance: zeroOrOne),
      #SvdElementSpec(name: "enumeratedValues", dataType: svdElement, occurance: zeroOneOrTwo), # Not yet supported
    ]
  )
  svdFieldsSpec = SvdElementSpec(
    name: "fields",
    dataType: svdElementGroup,
    occurance: zeroOrOne,
    elements: @[
      svdFieldSpec
    ]
  )

  svdRegisterSpec = SvdElementSpec(
    name: "register",
    dataType: svdElement,
    occurance: oneOrMore,
    attributes: @[svdDerivedFromAttrSpec],
    elements: @[
      # BEGIN Dim element group
      SvdElementSpec(name: "dim", dataType: svdNonNegativeInt, occurance: exactlyOne),
      SvdElementSpec(name: "dimIncrement", dataType: svdNonNegativeInt, occurance: exactlyOne),
      SvdElementSpec(name: "dimIndex", dataType: svdDimIndexType, occurance: zeroOrOne),
      SvdElementSpec(name: "dimName", dataType: svdIdentifier, occurance: zeroOrOne),
      SvdElementSpec(name: "dimArrayIndex", dataType: svdDimArrayIndexType, occurance: zeroOrOne),
      # END
      SvdElementSpec(name: "name", dataType: svdString, occurance: exactlyOne),
      SvdElementSpec(name: "displayName", dataType: svdString, occurance: zeroOrOne),
      SvdElementSpec(name: "description", dataType: svdString, occurance: zeroOrOne),
      SvdElementSpec(name: "alternateGroup", dataType: svdString, occurance: zeroOrOne), # type:xs:Name ?
      SvdElementSpec(name: "alternateRegister", dataType: svdIdentifier, occurance: zeroOrOne),
      SvdElementSpec(name: "addressOffset", dataType: svdNonNegativeInt, occurance: exactlyOne),
      # BEGIN Register properties group
      SvdElementSpec(name: "size", dataType: svdNonNegativeInt, occurance: zeroOrOne),
      SvdElementSpec(name: "access", dataType: svdAccess, occurance: zeroOrOne),
      SvdElementSpec(name: "protection", dataType: svdProtectionString, occurance: zeroOrOne),
      SvdElementSpec(name: "resetValue", dataType: svdNonNegativeInt, occurance: zeroOrOne),
      SvdElementSpec(name: "resetMask", dataType: svdNonNegativeInt, occurance: zeroOrOne),
      # END
      SvdElementSpec(name: "dataType", dataType: svdDataType, occurance: zeroOrOne),
      SvdElementSpec(name: "modifiedWriteValues", dataType: svdModifiedWriteValues, occurance: zeroOrOne),
      #SvdElementSpec(name: "writeConstraint", dataType: svdElement, occurance: zeroOrOne), # Not yet supported
      SvdElementSpec(name: "readAction", dataType: svdReadAction, occurance: zeroOrOne),
      svdFieldsSpec,
    ]
  )
  svdRegistersSpec = SvdElementSpec(
    name: "registers",
    dataType: svdElementGroup,
    occurance: zeroOrOne,
    elements: @[
      svdRegisterSpec,
    ]
  )

  svdPeripheralSpec = SvdElementSpec(
    name: "peripheral",
    dataType: svdElement,
    occurance: oneOrMore,
    attributes: @[svdDerivedFromAttrSpec],
    elements: @[
      SvdElementSpec(name: "dim", dataType: svdNonNegativeInt, occurance: zeroOrOne),
      SvdElementSpec(name: "dimIncrement", dataType: svdNonNegativeInt, occurance: zeroOrOne),
      SvdElementSpec(name: "dimIndex", dataType: svdNonNegativeInt, occurance: zeroOrOne),
      SvdElementSpec(name: "dimName", dataType: svdString, occurance: zeroOrOne),
      SvdElementSpec(name: "dimArrayIndex", dataType: svdNonNegativeInt, occurance: zeroOrOne),
      SvdElementSpec(name: "name", dataType: svdString, occurance: exactlyOne),
      SvdElementSpec(name: "version", dataType: svdString, occurance: zeroOrOne),
      SvdElementSpec(name: "description", dataType: svdString, occurance: zeroOrOne),
      SvdElementSpec(name: "alternatePeripheral", dataType: svdIdentifier, occurance: zeroOrOne),
      SvdElementSpec(name: "groupName", dataType: svdString, occurance: zeroOrOne),
      SvdElementSpec(name: "prependToName", dataType: svdIdentifier, occurance: zeroOrOne),
      SvdElementSpec(name: "appendToName", dataType: svdIdentifier, occurance: zeroOrOne),
      SvdElementSpec(name: "headerStructName", dataType: svdIdentifier, occurance: zeroOrOne),
      SvdElementSpec(name: "disableCondition", dataType: svdString, occurance: zeroOrOne),
      SvdElementSpec(name: "baseAddress", dataType: svdNonNegativeInt, occurance: exactlyOne),
      # BEGIN Register properties group
      SvdElementSpec(name: "size", dataType: svdNonNegativeInt, occurance: zeroOrOne),
      SvdElementSpec(name: "access", dataType: svdAccess, occurance: zeroOrOne),
      SvdElementSpec(name: "protection", dataType: svdString, occurance: zeroOrOne),
      SvdElementSpec(name: "resetValue", dataType: svdNonNegativeInt, occurance: zeroOrOne),
      SvdElementSpec(name: "resetMask", dataType: svdNonNegativeInt, occurance: zeroOrOne),
      # END
      svdAddressBlockSpec,
      svdInterruptSpec,
      svdRegistersSpec,
    ]
  )

  svdPeripheralsSpec = SvdElementSpec(
    name: "peripherals",
    dataType: svdElementGroup,
    occurance: exactlyOne,
    elements: @[
      svdPeripheralSpec,
    ],
  )

  svdDeviceSpec* = SvdElementSpec(
    name: "device",
    dataType: svdElement,
    occurance: exactlyOne,
    attributes: @[
      SvdAttributeSpec(name: "xmlns:xs", dataType: svdString, occurance: exactlyOne),
      SvdAttributeSpec(name: "xs:noNamespaceSchemaLocation", dataType: svdString, occurance: exactlyOne),
      SvdAttributeSpec(name: "schemaVersion", dataType: svdFloat, occurance: exactlyOne),
    ],
    elements: @[
      SvdElementSpec(name: "vendor", dataType: svdString, occurance: zeroOrOne),
      SvdElementSpec(name: "vendorID", dataType: svdString, occurance: zeroOrOne),
      SvdElementSpec(name: "name", dataType: svdString, occurance: exactlyOne),
      SvdElementSpec(name: "series", dataType: svdString, occurance: zeroOrOne),
      SvdElementSpec(name: "version", dataType: svdString, occurance: exactlyOne),
      SvdElementSpec(name: "description", dataType: svdString, occurance: exactlyOne),
      SvdElementSpec(name: "licenseText", dataType: svdString, occurance: zeroOrOne),
      svdCpuSpec,
      SvdElementSpec(name: "headerSystemFilename", dataType: svdString, occurance: zeroOrOne),
      SvdElementSpec(name: "headerDefinitionsPrefix", dataType: svdString, occurance: zeroOrOne),
      SvdElementSpec(name: "addressUnitBits", dataType: svdNonNegativeInt, occurance: exactlyOne),
      SvdElementSpec(name: "width", dataType: svdNonNegativeInt, occurance: exactlyOne),
      SvdElementSpec(name: "size", dataType: svdNonNegativeInt, occurance: zeroOrOne),
      SvdElementSpec(name: "access", dataType: svdAccess, occurance: zeroOrOne),
      SvdElementSpec(name: "protection", dataType: svdString, occurance: zeroOrOne),
      SvdElementSpec(name: "resetValue", dataType: svdNonNegativeInt, occurance: zeroOrOne),
      SvdElementSpec(name: "resetMask", dataType: svdNonNegativeInt, occurance: zeroOrOne),
      svdPeripheralsSpec,
      #SvdElementSpec(name: "vendorExtensions", dataType: svdElement, occurance: zeroOrOne), # Not yet supported
    ]
  )

func getSoloName*(groupName: string): string =
  const groupToSoloName = {
    "peripherals": "peripheral",
    "registers": "register",
    "fields": "field",
  }.toTable
  groupToSoloName[groupName]

func getSpec*(name: string): SvdElementSpec =
  const nameToSpec = {
    "cpu": svdCpuSpec,
    "addressBlock": svdAddressBlockSpec,
    "interrupt": svdInterruptSpec,
    "field": svdFieldSpec,
    "fields": svdFieldsSpec,
    "register": svdRegisterSpec,
    "registers": svdRegistersSpec,
    "peripheral": svdPeripheralSpec,
    "peripherals": svdPeripheralsSpec,
    "device": svdDeviceSpec,
  }.toTable
  nameToSpec[name]

type SomeSvdSpec = SvdElementSpec | SvdAttributeSpec

func isRequired*[T: SomeSvdSpec](elSpec: T): bool =
  ## Is the element or attribute required per the specification?
  elSpec.occurance == exactlyOne or elSpec.occurance == oneOrMore

func isPossiblyMoreThanOne*[T: SomeSvdSpec](elSpec: T): bool =
  elSpec.occurance == oneOrMore or elSpec.occurance == zeroOrMore

func isLeaf*[T: SomeSvdSpec](elSpec: T): bool =
  elSpec.dataType != svdElement and
  elSpec.dataType != svdElementGroup and
  elSpec.dataType != svdAddressBlock
