# Run this build script via "nim build" at the command line from this directory

import std/os

proc doExec(cmd: string) =
  let prefix = when defined(windows): "cmd /C " else: ""
  let (output, exitCode) = gorgeEx(prefix & cmd)
  if exitCode != QuitSuccess: quit(output, exitCode)

task build, "Build the STM32F446 Nim package from the SVD file":
  let tool = getCurrentDir().parentDir().parentDir() / "minisvd2nim".toExe
  assert fileExists(tool), "Use `nimble build` at the project root to build the minisvd2nim tool"
  doExec tool & " --force STM32F446.svd"
  exec "nim c blinky.nim"
  echo "Build complete.  Don't expect blinky.exe to run.  As long as it built, things are working."
