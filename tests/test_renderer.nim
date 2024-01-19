import std/os
import std/paths
import std/tempfiles
import unittest

import minisvd2nimpkg/parser
import minisvd2nimpkg/renderer

let fn = paths.getCurrentDir() / Path("tests") / Path("test.svd")

test "there shall be a procedure to render nim source":
  let device = parseSvdFile(fn)
  check compiles(renderNimFromSvd(stdout, device))

test "the render procedure shall output to the given file":
  let device = parseSvdFile(fn)
  let (f,p) = createTempFile("tmp", "test_render.nim")
  renderNimFromSvd(f, device)

  f.setFilePos(0)
  check f.readChar() == '#'
  f.close()
  p.removeFile()
