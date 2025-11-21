import std/[dirs, files, os, osproc, paths, strutils, tempfiles, unittest]

import minisvd2nimpkg/[parser, renderer]

proc quoteWrap(s: string): string =
  "\"" & s & "\""

suite "Test the renderer.":
  let tempDir = createTempDir(prefix = "minisvd2nim", suffix = "test_renderer")
  let tempPath = Path(tempDir)
  let fnTest = paths.getCurrentDir() / Path("tests") / Path("test.svd")
  let devTest = parseSvdFile(fnTest)
  discard renderNimPackageFromParsedSvd(tempPath, devTest)
  let devicePath = tempPath / Path("ARMCM4".toLower)

  test "there SHOULD be a procedure to render nim source":
    check compiles(renderNimPackageFromParsedSvd(tempPath, devTest))

  test "the renderer SHOULD output a package README":
    check fileExists(devicePath / Path("README.txt"))

  test "the renderer SHOULD output a package LICENSE":
    check fileExists(devicePath / Path("LICENSE.txt"))

  # test "the renderer SHOULD declare a field that is derivedFrom another register":
  #   # REGX.BYTE1 derivesFrom REGX.BYTE0
  #   let modPath = devicePath / Path("periphx.nim")
  #   let modFile = readFile(modPath.string)
  #   check "declareField(peripheralName = PERIPHX, registerName = REGX, fieldName = BYTE1" in
  #     modFile

  # TODO:
  # test "the renderer SHOULD declare a field that is derivedFrom another peripheral":
  # test "the renderer SHOULD declare a register that is derivedFrom another register":
  # test "the renderer SHOULD output enum values": # needs mods to .svd file

  # Suite teardown
  removeDir(tempPath)

suite "Test the renderer on a big SVD file.":
  let tempDir = createTempDir(prefix = "minisvd2nim", suffix = "test_renderer")
  var tempPath = Path(tempDir)
  let fnStm32 = paths.getCurrentDir() / Path("tests") / Path("STM32F446_v1_7.svd")
  let devStm32 = parseSvdFile(fnStm32)
  discard renderNimPackageFromParsedSvd(tempPath, devStm32)
  let devicePath = tempPath / Path("STM32F446".toLower)
  let metagenPath =
    paths.getCurrentDir() / Path("src") / Path("minisvd2nimpkg") /
    Path("metagenerator.nim")
  copyFileToDir(metagenPath.string, devicePath.string)

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
      let cmd = "nim c " & quoteWrap(modPath.string)
      let (_, exitCode) = execCmdEx(cmd)
      check exitCode == 0

  test "the renderer SHOULD declare a peripheral's interrupts":
    let modPath = devicePath / Path("sdio.nim")
    let modFile = readFile(modPath.string)
    check "declareInterrupt(peripheralName = SDIO" in modFile

  test "the renderer SHOULD declare registers that are derivedFrom another peripheral":
    # DMA1 derives its peripherals from DMA2
    let modPath = devicePath / Path("dma.nim")
    let modFile = readFile(modPath.string)
    check "declareRegister(peripheralName = DMA1, registerName = LISR" in modFile

  test "the renderer SHOULD not overwrite derivedFrom fields when the current field is empty (regression test)":
    # CAN2 derives its peripherals from CAN1
    let modPath = devicePath / Path("can.nim")
    let modFile = readFile(modPath.string)
    check "declarePeripheral(peripheralName = CAN2, baseAddress = 0x40006800'u32, peripheralDesc = \"Controller area network\")" in
      modFile

  test "the renderer SHOULD output field bit ranges when lsb and msb are given":
    # The SVD file is instrumented to have UART4.SR.OVERRUN with elements lsb = 0, msb = 0
    let modPath = devicePath / Path("uart.nim")
    let modFile = readFile(modPath.string)
    check "declareField(peripheralName = UART4, registerName = SR, fieldName = OVERRUN, bitOffset = 0, bitWidth = 1" in
      modFile

  # Suite teardown
  removeDir(tempPath)
