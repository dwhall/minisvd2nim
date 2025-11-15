import std/[files, os, paths, strutils, unittest]

# Check that the project has been built
let exe = when defined(windows): "minisvd2nim.exe" else: "minisvd2nim"
let fullExe = paths.getCurrentDir() / Path(exe)
let quotedExeStr = "\"" & fullExe.string & "\""
doAssert fileExists(fullExe), "Build the project before running this test"

test "the CLI should run with no input":
  let cmd = quotedExeStr
  check 0 == execShellCmd(cmd)

test "the CLI should process the example STM32 .svd file":
  let cmd = quotedExeStr & " tests" / "STM32F446_v1_7.svd"
  check 0 == execShellCmd(cmd)
  # remove the directory that was just created by the test
  os.removeDir("stm32f446")
