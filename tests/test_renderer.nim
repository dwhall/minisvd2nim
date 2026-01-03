import std/[files, dirs, os, osproc, paths, strutils, tempfiles, unittest]
import minisvd2nimpkg/parser

# File under test:
include minisvd2nimpkg/renderer

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

  test "the renderer SHOULD output registers from a dim element group":
    # The SVD file is instrumented to have UART4.DEVICEID[%s] with dim = 0x2, dimIncrement = 0x4
    let modPath = pkgPath / Path("uart.nim")
    let modFile = readFile(modPath.string)
    check "declareRegister(peripheralName = UART4, registerName = DEVICEID0, addressOffset = 0x00000060'u32, readAccess = true, writeAccess = false" in
      modFile
    check "declareField(peripheralName = UART4, registerName = DEVICEID0, fieldName = DEVICEID, bitOffset = 0, bitWidth = 32, readAccess = true, writeAccess = false" in
      modFile
    check "declareRegister(peripheralName = UART4, registerName = DEVICEID1, addressOffset = 0x00000064'u32, readAccess = true, writeAccess = false" in
      modFile
    check "declareField(peripheralName = UART4, registerName = DEVICEID1, fieldName = DEVICEID, bitOffset = 0, bitWidth = 32, readAccess = true, writeAccess = false" in
      modFile

  test "removeAbsolutePath SHOULD remove absolute path":
    var params = @["--force", "--segger", "D:\\code\\nim\\arm_cores\\src\\segger\\Cortex-M23.svd"]
    let cwd = "D:\\code\\nim\\arm_cores\\"
    params.removeAbsolutePath(cwd)
    check not ("D:\\code\\nim\\arm_cores\\src\\segger\\Cortex-M23.svd" in params)
    check "src\\segger\\Cortex-M23.svd" in params

  test "removeAbsolutePath SHOULD NOT modify a mismatched path":
    var params = @["--force", "--segger", "D:\\code\\nim\\arm_cores\\src\\segger\\Cortex-M23.svd"]
    params.removeAbsolutePath("C:\\code\\nim\\arm_cores\\")
    check "D:\\code\\nim\\arm_cores\\src\\segger\\Cortex-M23.svd" in params

  test "removeAbsolutePath SHOULD NOT modify a non-absolute path":
    var params = @["--force", "--segger", "D:\\code\\nim\\arm_cores\\src\\segger\\Cortex-M23.svd"]
    params.removeAbsolutePath("code\\nim\\arm_cores\\")
    check "D:\\code\\nim\\arm_cores\\src\\segger\\Cortex-M23.svd" in params

  # Teardown:
  removeDir(tempPath.string)
