# Run this build script via "nim build" at the command line from this directory

import std/os

task build, "Build the Nim package from the segger-style quasi-SVD file":
  let tool = getCurrentDir().parentDir().parentDir() / "minisvd2nim".toExe
  let args = " -s" # segger-style SVD
  assert fileExists(tool), "Use `nimble build` at the project root to build the minisvd2nim tool"
  rmDir("cm4f") # so that the package is always rebuilt
  exec tool & args & " Cortex-M4F.svd"
  exec "nim c main.nim"
  echo "Build complete.  Don't expect main.exe to run.  As long as it built, things are working."
