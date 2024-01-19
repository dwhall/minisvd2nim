import std/os
import std/tempfiles
import unittest

import minisvd2nimpkg/svdtypes
import minisvd2nimpkg/renderer

let device = SvdDevice()

test "there shall be a procedure to render nim source":
  check compiles(renderNimFromSvd(stdout, device))

test "the render procedure shall output to the given file":
  let (f,p) = createTempFile("tmp", "test_render.nim")
  renderNimFromSvd(f, device)

  f.setFilePos(0)
  check f.readChar() == '#'
  f.close()
  p.removeFile()
