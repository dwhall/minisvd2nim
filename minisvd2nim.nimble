#!fmt: off

# Package

version       = "0.4.1"
author        = "!!Dean"
description   = "A smaller SVD to nim generator tool"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["minisvd2nim"]


# Dependencies

requires "nim >= 2.0"

# Tasks

proc quoteWrap(s: string): string = "\"" & s & "\""

after build:
  ## Runs minisvd2nim to generate files for use by the example
  when defined(windows):
    const tool = "minisvd2nim.exe"
    const dirSep = "\\"
  else:
    const tool = "minisvd2nim"
    const dirSep = "/"
  assert fileExists(tool)
  let cwd = getCurrentDir()
  let minisvd2nim = cwd & dirSep & tool
  let exampleDir = cwd & dirSep & "example"
  let svdFile = cwd & dirSep & "tests" & dirSep & "STM32F446_v1_7.svd"
  assert fileExists(svdFile)
  if not dirExists(exampleDir & dirSep & "stm32f446"):
    cd(exampleDir)
    exec(quoteWrap(minisvd2nim) & " " & quoteWrap(svdFile))
