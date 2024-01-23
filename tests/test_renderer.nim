import std/os
import std/paths
import std/strutils
import std/tempfiles
import unittest

import minisvd2nimpkg/parser
import minisvd2nimpkg/renderer

let fn_test = paths.getCurrentDir() / Path("tests") / Path("test.svd")
let dev_test = parseSvdFile(fn_test)

test "there shall be a procedure to render nim source":
  check compiles(renderNimFromSvd(stdout, dev_test))

test "DEBUG: generates a file to examine by hand":
  var f = open("tests" / "dwh_test_render.nim", fmWrite)
  renderNimFromSvd(f, dev_test)

test "the render procedure shall output a header comment":
  let (f, p) = createTempFile("tmp", "test_render.nim")
  renderNimFromSvd(f, dev_test)
  f.setFilePos(0)
  let line = f.readLine()
  check line[0] == '#'
  check "auto-generated" in line
  f.close()
  p.removeFile()

let fn_stm32 = paths.getCurrentDir() / Path("tests") / Path("STM32F446_v1_7.svd")
let dev_stm32 = parseSvdFile(fn_stm32)

test "the render procedure shall output peripheral registers":
  let (f, p) = createTempFile("tmp", "stm32_render.nim")
  renderNimFromSvd(f, dev_stm32)
  f.setFilePos(0)
  let fileContents = f.readAll()
  check "TSTR" in fileContents
  f.close()
  p.removeFile()
