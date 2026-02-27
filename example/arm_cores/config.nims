# Run this build script via "nim build" at the command line from this directory

import std/os

proc doExec(cmd: string) =
  let prefix = when defined(windows): "cmd /C " else: ""
  let (output, exitCode) = gorgeEx(prefix & cmd)
  if exitCode != QuitSuccess: quit(output, exitCode)

task prep, "Convert the SVD file to a Nim package":
  let tool = getCurrentDir().parentDir().parentDir() / "minisvd2nim".toExe
  assert fileExists(tool), "Use `nimble build` at the project root to build the minisvd2nim tool"
  doExec tool & " --force Cortex-M4F.svd"

task build, "Build the cm4f Nim package from the SVD file":
  let tool = getCurrentDir().parentDir().parentDir() / "minisvd2nim".toExe
  assert fileExists(tool), "Use `nimble build` at the project root to build the minisvd2nim tool"
  doExec tool & " --force Cortex-M4F.svd"
  exec "nim c main.nim"
  echo "Build complete.  Don't expect main.exe to run.  As long as it built, things are working."
