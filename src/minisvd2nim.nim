## main() is a command line tool that
## parses the given .svd input file and outputs nim source to stdout.
##

import std/[dirs, files, os, parseopt, paths, strformat, strutils, syncio]

import minisvd2nimpkg/[parser, renderer, svd_types, versions]

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
proc processPackage(device: SvdElementValue, outPath: Path, deviceName: string)
proc preparePackageDir(pkgPath: Path)
proc writeMsgAndQuit(outFile: File, msg: string, errorCode: int = QuitFailure)
proc copyMetageneratorFileToPackage(pkgPath: Path)

proc main() =
  try:
    let (fn, outPath, isSegger) = parseArgs()
    validateArgs(fn, outPath)
    let (device, deviceName) =
      if isSegger: parseSeggerFile(fn)
      else: parseSvdFile(fn)
    processPackage(device, outPath, deviceName)
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
  if fn.string == "":
    writeMsgAndQuit(stdout, usage, QuitSuccess)
  if not fileExists(fn):
    writeMsgAndQuit(stdout, usage)
  if not dirExists(outPath):
    writeMsgAndQuit(stdout, &"Output path does not exist: {outPath.string}")

proc processPackage(device: SvdElementValue, outPath: Path, deviceName: string) =
  let pkgPath = outPath / Path(deviceName.toLower())
  preparePackageDir(pkgPath)
  renderNimPackageFromParsedSvd(device, pkgPath, deviceName)
  copyMetageneratorFileToPackage(pkgPath)

proc preparePackageDir(pkgPath: Path) =
  if dirExists(pkgPath):
    stderr.write(&"Exiting.  Target path already exists: {pkgPath.string}")
    quit(QuitFailure)
  createDir(pkgPath)

proc copyMetageneratorFileToPackage(pkgPath: Path) =
  const
    thisSrcFileDir = currentSourcePath().parentDir
    metageneratorPath = joinPath(thisSrcFileDir, "minisvd2nimpkg", "metagenerator.nim")
    fileContents = readFile(metageneratorPath.string)
  let fn = pkgPath / Path("metagenerator.nim")
  writeFile(fn.string, fileContents)

if isMainModule:
  main()
