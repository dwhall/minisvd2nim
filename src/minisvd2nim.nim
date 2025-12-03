## main() is a command line tool that
## parses the given .svd input file and outputs nim source to stdout.
##

import std/[files, os, parseopt, paths, strformat, strutils, syncio]

import minisvd2nimpkg/[parser, renderer, versions]

const
  version = &"version: {getVersion()}\p"
  usage = "minisvd2nim [option] [<input.svd>]\p"
  copyright = "Copyright 2024 Dean Hall. See LICENSE.txt for details.\p"
  help =
    &"""
minisvd2nim - Generate Nim source from System View Description XML

{copyright}
Usage:
  {usage}
Options:
  -p / --path=<path>    set the path where the device package is written
  -s / --segger         parse Segger non-compliant .svd-like format
  -v / --version        show the version
  --help                show this help
"""

proc parseArgs(): tuple[fn: Path, outPath: Path, isSegger: bool]
proc validateArgs(fn: Path, outPath: Path)
proc processPeripheralPackage(fn: Path, outPath: Path)
proc processCpuPackage(fn: Path, outPath: Path)
proc writeMsgAndQuit(outFile: File, msg: string, errorCode: int = QuitFailure)
proc copyMetageneratorFileToPackage(pkgPath: Path)

proc main() =
  try:
    let (fn, outPath, isSegger) = parseArgs()
    validateArgs(fn, outPath)
    if isSegger:
      processCpuPackage(fn, outPath)
    else:
      processPeripheralPackage(fn, outPath)
  except IOError as e:
    writeMsgAndQuit(stdout, "Error: " & e.msg & "\n" & usage)

proc parseArgs(): tuple[fn: Path, outPath: Path, isSegger: bool] =
  ## Returns only if a proper combination of arguments are given;
  ## otherwise it prints a message and exits
  var fn: Path
  var outPath = paths.getCurrentDir()
  var isSegger = false
  for kind, key, val in getopt():
    case kind
    of cmdLongOption, cmdShortOption:
      case normalize(key)
      of "version", "v":
        writeMsgAndQuit(stdout, version)
      of "path", "p":
        outPath = absolutePath(Path(val))
      of "segger", "s":
        isSegger = true
      else:
        writeMsgAndQuit(stdout, help)
    of cmdArgument:
      fn = absolutePath(Path(key))
    of cmdEnd:
      break
  return (fn, outPath, isSegger)

proc writeMsgAndQuit(outFile: File, msg: string, errorCode: int = QuitFailure) =
  outFile.write(msg)
  outFile.flushFile()
  outFile.close()
  quit(errorCode)

proc validateArgs(fn: Path, outPath: Path) =
  # If no file was given, quit successfully
  if fn.string == "":
    writeMsgAndQuit(stdout, usage, QuitSuccess)

  # If the given file cannot be found, quit with error
  if not fileExists(fn):
    writeMsgAndQuit(stdout, usage)

proc processCpuPackage(fn: Path, outPath: Path) =
  let (device, deviceName) = parseSeggerFile(fn)
  let pkgPath = renderNimPackageFromParsedSvd(outPath, device, deviceName)
  copyMetageneratorFileToPackage(pkgPath)

proc processPeripheralPackage(fn: Path, outPath: Path) =
  let (device, deviceName) = parseSvdFile(fn)
  let pkgPath = renderNimPackageFromParsedSvd(outPath, device, deviceName)
  copyMetageneratorFileToPackage(pkgPath)

proc copyMetageneratorFileToPackage(pkgPath: Path) =
  const
    thisSrcFileDir = currentSourcePath().parentDir
    metageneratorPath = joinPath(thisSrcFileDir, "minisvd2nimpkg", "metagenerator.nim")
    fileContents = readFile(metageneratorPath.string)
  let fn = pkgPath / Path("metagenerator.nim")
  writeFile(fn.string, fileContents)

if isMainModule:
  main()
