import std/os
import std/paths
import std/strutils
import std/tempfiles
import unittest

import minisvd2nimpkg/parser
import minisvd2nimpkg/renderer

let fn = paths.getCurrentDir() / Path("tests") / Path("test.svd")
let device = parseSvdFile(fn)

test "there shall be a procedure to render nim source":
  check compiles(renderNimFromSvd(stdout, device))

test "DEBUG: generates a file to examine by hand":
  var f = open("tests" / "dwh_test_render.nim", fmWrite)
  renderNimFromSvd(f, device)

test "the render procedure shall output a header comment":
  let (f,p) = createTempFile("tmp", "test_render.nim")
  renderNimFromSvd(f, device)
  f.setFilePos(0)
  let line = f.readLine()
  check line[0] == '#'
  check "auto-generated" in line
  f.close()
  p.removeFile()
