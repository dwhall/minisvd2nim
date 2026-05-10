import std/[files, os, osproc, paths]
import unittest2

proc quoteWrap(s: string): string =
  "\"" & s & "\""

# Check that the project has been built
let exe = when defined(windows): "minisvd2nim.exe" else: "minisvd2nim"
let fullExe = paths.getCurrentDir() / Path(exe)
let exeStr = quoteWrap(fullExe.string)
doAssert fileExists(fullExe), "Build the project before running this test"

test "the CLI should run with no input":
  let cmd = exeStr
  check 0 == execShellCmd(cmd)

test "the CLI should process the example .svd file":
  os.removeDir("test_small")
  let cmd = exeStr & " tests" / "test_small.svd"
  check 0 == execShellCmd(cmd)
  # remove the directory that was just created by the test
  os.removeDir("test_small")

test "the CLI should compile 32-bit ARM without 32/64-bit conflicts":
  let cmd =
    "nim compileToC --compileOnly:on --path:../src/minisvd2nimpkg " &
    "--define:useMalloc " & "--cpu:arm --os:any --mm:arc " &
    "--arm.any.gcc.exe:arm-none-eabi-gcc " & "--arm.any.gcc.linkerexe:arm-none-eabi-gcc " &
    currentSourcePath().parentDir() / "arm32b.nim"
  let (output, exitCode) = execCmdEx(cmd)
  if exitCode != 0:
    echo "Compile failure output: ", output
  check exitCode == 0
