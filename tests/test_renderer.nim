# File under test:
include minisvd2nimpkg/renderer

import std/[dirs, files, osproc, tempfiles, unittest]
import minisvd2nimpkg/parser

proc quoteWrap(s: string): string =
  "\"" & s & "\""

suite "Test the renderer.":

  # setup:
  let tempDir = createTempDir(prefix = "minisvd2nim", suffix = "test_renderer")
  let tempPath = Path(tempDir)
  let fnTest = paths.getCurrentDir() / Path("tests") / Path("test.svd")
  let (device, deviceName) = parseSvdFile(fnTest)
  let pkgPath = tempPath / Path(deviceName.toLower())
  createDir(pkgPath)
  renderNimPackageFromParsedSvd(device, pkgPath, deviceName)
  let metagenPath = paths.getCurrentDir() / Path("src") / Path("minisvd2nimpkg") / Path("metagenerator.nim")
  copyFileToDir(metagenPath.string, pkgPath.string)

  test "there SHOULD be a procedure to render nim source":
    check compiles(renderNimPackageFromParsedSvd(device, pkgPath, deviceName))

  test "the renderer SHOULD output a package README":
    check fileExists(pkgPath / Path("README.txt"))

  test "the renderer SHOULD output a package LICENSE":
    check fileExists(pkgPath / Path("LICENSE.txt"))

# TODO: (see renderer.nim:283)
#  test "the renderer SHOULD declare a field that is derivedFrom another register":
#    # In test.svd DCMI.CR2 was instrumented with drivesFrom DCMI.CR which has a field CAPTURE
#    let modPath = pkgPath / Path("dcmi.nim")
#    let modFile = readFile(modPath.string)
#    check "declareField(peripheralName = DCMI, registerName = CR2, fieldName = CAPTURE" in modFile

  # TODO:
  # test "the renderer SHOULD declare a field that is derivedFrom another peripheral":
  # test "the renderer SHOULD declare a register that is derivedFrom another register":
  # test "the renderer SHOULD output enum values": # needs mods to .svd file


  test "the renderer SHOULD output peripheral modules":
    # check the first, last and a few other peripherals
    for periph in ["dcmi", "rtc", "can", "sdio"]:
      check fileExists(pkgPath / Path(periph & ".nim"))

  test "the renderer SHOULD NOT output non-existant peripheral modules":
    for periph in ["foo", "bar", "baz"]:
      check not fileExists(pkgPath / Path(periph & ".nim"))

  test "the renderer SHOULD NOT output enumerated peripheral modules":
    for periph in ["can1", "dma2"]:
      check not fileExists(pkgPath / Path(periph & ".nim"))

  test "the renderer SHOULD generate modules that compile":
    for periph in ["dcmi", "rtc", "can", "sdio"]:
      let modPath = pkgPath / Path(periph & ".nim")
      let cmd = "nim c " & quoteWrap(modPath.string)
      let (_, exitCode) = execCmdEx(cmd)
      check exitCode == 0

  test "the renderer SHOULD declare a peripheral's interrupts":
    let modPath = pkgPath / Path("sdio.nim")
    let modFile = readFile(modPath.string)
    check "declareInterrupt(peripheralName = SDIO" in modFile

  test "the renderer SHOULD declare registers that are derivedFrom another peripheral":
    # DMA1 derives its peripherals from DMA2
    let modPath = pkgPath / Path("dma.nim")
    let modFile = readFile(modPath.string)
    check "declareRegister(peripheralName = DMA1, registerName = LISR" in modFile

  test "the renderer SHOULD not overwrite derivedFrom fields when the current field is empty (regression test)":
    # CAN2 derives its peripherals from CAN1
    let modPath = pkgPath / Path("can.nim")
    let modFile = readFile(modPath.string)
    check "declarePeripheral(peripheralName = CAN2, baseAddress = 0x40006800'u32, peripheralDesc = \"Controller area network\")" in
      modFile

  test "the renderer SHOULD output field bit ranges when lsb and msb are given":
    # The SVD file is instrumented to have UART4.SR.OVERRUN with elements lsb = 0, msb = 0
    let modPath = pkgPath / Path("uart.nim")
    let modFile = readFile(modPath.string)
    check "declareField(peripheralName = UART4, registerName = SR, fieldName = OVERRUN, bitOffset = 0, bitWidth = 1" in
      modFile

  test "the renderer SHOULD output a dimensioned register declaration":
    # The SVD file is instrumented to have UART4.DEVICEID[%s] with dim = 0x2, dimIncrement = 0x4
    let modPath = pkgPath / Path("uart.nim")
    let modFile = readFile(modPath.string)
    check "declareDimRegister(peripheralName = UART4, registerName = DEVICEID, addressOffset = 0x00000060'u32, dim = 2, dimIncrement = 4, readAccess = true, writeAccess = false" in
      modFile

  test "the renderer SHOULD output fields of a dimensioned register":
    # The SVD file is instrumented to have UART4.DEVICEID[%s] with a field named DEVICETYPE
    let modPath = pkgPath / Path("uart.nim")
    let modFile = readFile(modPath.string)
    check "declareField(peripheralName = UART4, registerName = DEVICEID, fieldName = DEVICETYPE, bitOffset = 0, bitWidth = 32" in
      modFile

  test "the renderer SHOULD output fields of a register derived from a dimensioned register":
    # The SVD file is instrumented to have UART5.DEVICEID[%s] with a field named DEVICETYPE
    let modPath = pkgPath / Path("uart.nim")
    let modFile = readFile(modPath.string)
    check "declareField(peripheralName = UART5, registerName = DEVICEID, fieldName = DEVICETYPE, bitOffset = 0, bitWidth = 32" in
      modFile

  # Teardown:
  removeDir(tempPath.string)

suite "regression tests":
  # setup:
  let tempDir = createTempDir(prefix = "minisvd2nim", suffix = "test_render_regressions")
  let tempPath = Path(tempDir)
  let pkgPath = tempPath
  let fnTest = paths.getCurrentDir() / Path("tests") / Path("test_small.svd")
  let (device, _) = parseSvdFile(fnTest)

  test "renderPeripherals SHOULD NOT append to existing files":
    let modPath = pkgPath / Path("timer.nim")
    writeFile(modPath.string, "THIS_SHOULD_BE_REMOVED\n")

    # Render twice to see if it appends to the existing file
    renderPeripherals(pkgPath, device)
    renderPeripherals(pkgPath, device)

    let modFile = readFile(modPath.string)
    check "THIS_SHOULD_BE_REMOVED" notin modFile
    check fileExists(modPath)

  test "renderField SHOULD replace hyphens with underscores":
    let modPath = pkgPath / Path("timer.nim")
    let modFile = readFile(modPath.string)
    check "DASH-B-GONE" notin modFile
    check "DASH_B_GONE" in modFile

  # Teardown:
  removeDir(tempPath.string)
