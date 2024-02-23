import std/files
import std/os
import std/paths
import unittest

# Check that the project has been built
let exe = when defined(windows): "minisvd2nim.exe" else: "minisvd2nim"
let fullExe = paths.getCurrentDir() / Path(exe)
doAssert fileExists(fullExe), "Build the project before running this test"

test "the CLI should run with no input":
  let cmd = fullExe.string
  check 0 == execShellCmd(cmd)

test "the CLI should process the example STM32 .svd file":
  let cmd = fullExe.string & " tests" / "STM32F446_v1_7.svd > example" / "stm32f446.nim"
  check 0 == execShellCmd(cmd)
