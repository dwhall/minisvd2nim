#!fmt: off

# Package

version       = "0.5.0"
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
    const dirSep = "\\"
  else:
    const dirSep = "/"
  const tool = toExe("minisvd2nim")
  assert fileExists(tool)
  let cwd = getCurrentDir()
  let minisvd2nim = cwd & dirSep & tool
  let exampleDir = cwd & dirSep & "example"
  let svdFile = cwd & dirSep & "tests" & dirSep & "STM32F446_v1_7.svd"
  assert fileExists(svdFile)
  if not dirExists(exampleDir & dirSep & "stm32f446"):
    cd(exampleDir)
    exec(quoteWrap(minisvd2nim) & " " & quoteWrap(svdFile))
