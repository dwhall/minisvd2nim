#!fmt: off

# Package

version       = "0.2.0"
author        = "!!Dean"
description   = "A smaller SVD to nim generator tool"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["minisvd2nim"]


# Dependencies

requires "nim >= 2.0.0"

# Tasks

after build:
  ## Runs minisvd2nim to generate files for use by the example
  echo "after build"
  when defined(windows):
    const tool = "minisvd2nim.exe"
    const dirSep = "\\"
  else:
    const tool = "minisvd2nim"
    const dirSep = "/"
  assert fileExists(tool)
  let currDir = getCurrentDir()
  let minisvd2nim = currDir & dirSep & tool
  let examplesDir = currDir & dirSep & "example"
  let svdFile = currDir & dirSep & "tests" & dirSep & "STM32F446_v1_7.svd"
  assert fileExists(svdFile)
  cd(examplesDir)
  exec(minisvd2nim & " " & svdFile)
