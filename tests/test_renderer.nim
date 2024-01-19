import std/paths
import unittest

import minisvd2nimpkg/parser
import minisvd2nimpkg/renderer

let fn = getCurrentDir() / Path("tests") / Path("test.svd")

test "there shall be a procedure to render nim source:":
  let device = parseSvdFile(fn)
  check compiles(renderNimFromSvd(device, stdout))
