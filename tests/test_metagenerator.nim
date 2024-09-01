import std/paths
import std/unittest

import minisvd2nimpkg/parser
import minisvd2nimpkg/renderer

## example.svd comes from: https://www.keil.com/pack/doc/CMSIS/SVD/html/svd_Example_pg.html
## and is manually modified for specific tests using examples from:
## https://open-cmsis-pack.github.io/svd-spec/main/elem_registers.html

block:
  # Build a example.nim file from example.svd
  let fn_example = getCurrentDir() / Path("tests") / Path("example.svd")
  let svd = parseSvdFile(fn_example)
  let fn_example_nim = changeFileExt(fn_example, "nim")
  var outf = open(fn_example_nim.string, fmWrite)
  defer:
    outf.close()
  renderNimFromSvd(outf, svd)

# compiler error if example.nim doesn't exist before the block above
#import example #.nim

test "derived registers SHOULD have compatible register values and fields":
  discard # TODO

test "derived peripheral SHOULD have registers identical to the base peripherals":
  discard # TODO
