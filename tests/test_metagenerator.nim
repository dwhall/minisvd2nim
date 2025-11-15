import std/[os, paths, strutils, unittest]

import minisvd2nimpkg/[parser, renderer]

## example.svd comes from: https://www.keil.com/pack/doc/CMSIS/SVD/html/svd_Example_pg.html
## and is manually modified for specific tests using examples from:
## https://open-cmsis-pack.github.io/svd-spec/main/elem_registers.html

block:
  # Build a example.nim file from example.svd
  let fn_example = paths.getCurrentDir() / Path("tests") / Path("example.svd")
  let svd = parseSvdFile(fn_example)
  let fn_example_nim = changeFileExt(fn_example, "nim")
  var outf = open(fn_example_nim.string, fmWrite)
  defer:
    outf.close()
  discard renderNimPackageFromParsedSvd(paths.getCurrentDir(), svd)
  # remove the directory that was just created by the test
  os.removeDir(toLower("ARM_Example"))

# If you got an error running the unit tests it is because of this.
# Run the tests again and example.nim should exist because of the block above.
#import example

test "derived registers SHOULD have compatible register values and fields":
  discard # TODO

test "derived peripheral SHOULD have registers identical to the base peripherals":
  discard # TODO
