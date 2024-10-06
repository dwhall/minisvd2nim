import std/[dirs, files, paths, strutils, tempfiles, unittest]

import minisvd2nimpkg/[parser, renderer]

var tempPath: Path

suite "Test the renderer.":
  # made a suite in order to have setup/teardown

  setup:
    let tempDir = createTempDir(prefix = "minisvd2nim", suffix = "test_renderer")
    tempPath = Path(tempDir)

  teardown:
    removeDir(tempPath)

  let fnTest = paths.getCurrentDir() / Path("tests") / Path("test.svd")
  let devTest = parseSvdFile(fnTest)

  test "there SHOULD be a procedure to render nim source":
    check compiles(renderNimPackageFromSvd(tempPath, devTest))

  # test "DEBUG: generates a file to examine by hand":
  #   renderNimPackageFromSvd(tempPath, devTest)

  test "the render procedure SHOULD output a package README":
    renderNimPackageFromSvd(tempPath, devTest)
    check fileExists(tempPath / Path("ARMCM4".toLower) / Path("README.txt"))

  let fnStm32 = paths.getCurrentDir() / Path("tests") / Path("STM32F446_v1_7.svd")
  let devStm32 = parseSvdFile(fnStm32)

  test "the render procedure SHOULD output peripheral registers":
    renderNimPackageFromSvd(tempPath, devStm32)
    check fileExists(tempPath / Path("STM32F446".toLower) / Path("rtc.nim"))

# FIXME:
#
# let fnExample = paths.getCurrentDir() / Path("tests") / Path("example.svd")
# let devExample = parseSvdFile(fnExample)
#
# test "the render procedure SHOULD output enum arrays if they exist":
#   renderNimPackageFromSvd(tempPath, devExample)
#   f.setFilePos(0)
#   let fileContents = f.readAll()
#   f.close()
#   check "Reset_Timer" in fileContents
