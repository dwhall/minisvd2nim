## main() is a command line tool that
## parses the given .svd input file and outputs nim source to stdout.
##

import std/[files, parseopt, paths, strformat, strutils]

import minisvd2nimpkg/parser
import minisvd2nimpkg/renderer
import minisvd2nimpkg/versions

const version = &"version: {getVersion()}\p"
const usage = "minisvd2nim [option] [<input.svd>]\p"
const help =
  &"""
minisvd2nim - Generate Nim source from System View Description XML

Copyright 2024 Dean Hall.  See LICENSE.txt for details.

Usage:
  {usage}

Options:
  -p / --path=<path>    set the path where the device package is written
  --version             show the version
  --help                show this help
"""

proc parseArgs(): tuple[svdFn: Path, outPath: Path]
proc validateArgs(svdFn: Path, outPath: Path)
proc writeMsgAndQuit(msg: string, errorCode: int = QuitFailure)

proc main() =
  let (svdFn, outPath) = parseArgs()
  validateArgs(svdFn, outPath)
  let svd = parseSvdFile(fn = svdFn)
  renderNimPackageFromSvd(outPath = outPath, device = svd)

proc parseArgs(): tuple[svdFn: Path, outPath: Path] =
  ## Returns only if a proper combination of arguments are given;
  ## otherwise it prints a message and exits
  var svdFn: Path
  var outPath = getCurrentDir()
  for kind, key, val in getopt():
    case kind
    of cmdLongOption, cmdShortOption:
      case normalize(key)
      of "version", "v":
        writeMsgAndQuit(version)
      of "path", "p":
        outPath = absolutePath(Path(val))
      else:
        writeMsgAndQuit(help)
    of cmdArgument:
      svdFn = absolutePath(Path(key))
    of cmdEnd:
      break
  return (svdFn, outPath)

proc writeMsgAndQuit(msg: string, errorCode: int = QuitFailure) =
  stdout.write(msg)
  stdout.flushFile()
  quit(errorCode)

proc validateArgs(svdFn: Path, outPath: Path) =
  # If no file was given, quit successfully
  if svdFn.string == "":
    writeMsgAndQuit(usage, QuitSuccess)

  # If the given file cannot be found, quit with error
  if not fileExists(svdFn):
    writeMsgAndQuit(usage)

if isMainModule:
  main()
