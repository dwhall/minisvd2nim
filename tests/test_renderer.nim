import std/[dirs, files, osproc, paths, strutils, tempfiles, unittest]

import minisvd2nimpkg/[parser, renderer]

suite "Test the renderer.":
  # made a suite in order to have setup/teardown

  let fnTest = paths.getCurrentDir() / Path("tests") / Path("test.svd")
  let devTest = parseSvdFile(fnTest)
  var tempPath: Path

  setup:
    let tempDir = createTempDir(prefix = "minisvd2nim", suffix = "test_renderer")
    tempPath = Path(tempDir)
    renderNimPackageFromParsedSvd(tempPath, devTest)
    let devicePath = tempPath / Path("ARMCM4".toLower)

  teardown:
    removeDir(tempPath)

  test "there SHOULD be a procedure to render nim source":
    check compiles(renderNimPackageFromParsedSvd(tempPath, devTest))

  test "the renderer SHOULD output a package README":
    check fileExists(devicePath / Path("README.txt"))

  test "the renderer SHOULD output a package LICENSE":
    check fileExists(devicePath / Path("LICENSE.txt"))

suite "Test the renderer on a big SVD file.":
  let fnStm32 = paths.getCurrentDir() / Path("tests") / Path("STM32F446_v1_7.svd")
  let devStm32 = parseSvdFile(fnStm32)
  var tempPath: Path

  setup:
    let tempDir = createTempDir(prefix = "minisvd2nim", suffix = "test_renderer")
    tempPath = Path(tempDir)
    renderNimPackageFromParsedSvd(tempPath, devStm32)
    let devicePath = tempPath / Path("STM32F446".toLower)

  # teardown:
  #   removeDir(tempPath)

  test "the renderer SHOULD output peripheral modules":
    # check the first, last and a few other peripherals
    for periph in ["dcmi", "rtc", "can", "sdio"]:
      check fileExists(devicePath / Path(periph & ".nim"))

  test "the renderer SHOULD NOT output non-existant peripheral modules":
    for periph in ["foo", "bar", "baz"]:
      check not fileExists(devicePath / Path(periph & ".nim"))

  test "the renderer SHOULD NOT output enumerated peripheral modules":
    for periph in ["can1", "dma2"]:
      check not fileExists(devicePath / Path(periph & ".nim"))

  test "the renderer SHOULD generate modules that compile":
    for periph in ["dcmi", "rtc", "can", "sdio"]:
      let modPath = devicePath / Path(periph & ".nim")
      let (_, exitCode) = execCmdEx("nim c " & modPath.string)
      check exitCode == 0

# TODO:
# test "the renderer SHOULD output derivedFrom fields":
# test "the renderer SHOULD output derivedFrom registers":
# test "the renderer SHOULD output derivedFrom peripherals":
# test "the renderer SHOULD output enum values":
