import std/paths
import unittest

import minisvd2nimpkg/parser
import minisvd2nimpkg/svdtypes

let fn = getCurrentDir() / Path("tests") / Path("test.svd")

test "there shall be a procedure to parse .svd files":
  check compiles(parseSvdFile(fn))

test "the .svd parse procedure shall return an SvdDevice":
  let obj = parseSvdFile(fn)
  check typeof(obj) is SvdDevice

test "the .svd parse procedure should return an expected value":
  let device = parseSvdFile(fn)
  check device.name == "ARMCM4"
