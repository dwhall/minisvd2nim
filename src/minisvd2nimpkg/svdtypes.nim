## Copyright 2024 Dean Hall, all rights reserved.  See LICENSE.txt for details.
##
import std/sequtils

type
  # TODO: Use parseEnum[SvdEndianness] from std/strutils
  SvdEndianness* = enum
    little
    big
    selectable
    other

  SvdAddrBlockUsage* = enum
    registers
    buffer
    reserved

  SvdModifiedWriteValues* = enum
    oneToClear
    oneToSet
    oneToToggle
    zeroToClear
    zeroToSet
    zeroToToggle
    clear
    set
    modify

  SvdReadAction* = enum
    clear
    set
    modify
    modifyExternal

  SvdElementType* = enum
    svdElement
    svdElementGroup
    svdInt
    svdNonNegativeInt
    svdBool
    svdFloat
    svdString
    svdEndian # one of four strings
    svdIdentifier # string of an identifier
    svdRevision # a string of format: rNpM where N,M = [0 - 99]
    svdAccess
    svdUsage
    svdAddressBlock
    svdAddressBlockUsage
    svdDimIndexType
    svdDimArrayIndexType
    svdProtectionString
    svdDataType
    svdModifiedWriteValues
    svdReadAction
    svdBitRange

  SvdOccurance* = enum
    zeroOrMore
    zeroOrOne
    zeroOneOrTwo
    exactlyOne
    oneOrMore

  SvdAttributeSpec* = object
    name*: string
    dataType*: SvdElementType
    occurance*: SvdOccurance

  SvdElementSpec* {.acyclic.} = object
    name*: string
    attributes*: seq[SvdAttributeSpec]
    dataType*: SvdElementType
    occurance*: SvdOccurance
    defaultValue*: string
    elements*: seq[SvdElementSpec]

  # The parser uses the spec to turn the full SVD XML tree
  # into a tree of SvdElementValues, which is given to the renderer.
  SvdElementValue* {.acyclic.} = object
    name*: string
    value*: string
    dataType*: SvdElementType
    attributes*: seq[SvdElementValue]
    elements*: seq[SvdElementValue]

const nilElementValue* = SvdElementValue()

func `==`*(a, b: SvdElementValue): bool =
  ## Compare two SvdElementValues for equality
  return a.name == b.name and a.value == b.value and a.dataType == b.dataType

func hasAttr*(elVal: SvdElementValue, attrName: string): bool =
  elVal.attributes.anyIt(it.name == attrName)

func getAttr*(elVal: SvdElementValue, attrName: string): SvdElementValue =
  ## Get the attribute value by name
  for attr in elVal.attributes:
    if attr.name == attrName:
      return attr
  return nilElementValue
