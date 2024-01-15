import std/paths
import unittest

import minisvd2nimpkg/svdparser

test "there shall be a procedure to parse .svd files":
  let fn = Path("test.svd")
  check compiles(parseSvdDevice(fn))

test "the .svd parse procedure shall return an SvdDevice":
  let fn = Path("test.svd")
  let obj = parseSvdDevice(fn)
  check typeof(obj) is SvdDevice
