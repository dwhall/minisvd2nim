## main() is a command line tool that
## parses the given .svd input file and outputs nim source to stdout.
##

import std/files
import std/parseopt
import std/paths
import std/strutils

import minisvd2nimpkg/parser
import minisvd2nimpkg/renderer
import minisvd2nimpkg/versions

const Usage = """
minisvd2nim - Generate Nim source from System View Description XML

Copyright 2024 Dean Hall.  See LICENSE.txt for details.

Usage:
  minisvd2nim [option] [<input.svd>]

Options:
  --version             show the version
  --help                show this help
"""

proc parseArgs(): tuple[fn: Path]
proc writeHelp()
proc writeVersion()
proc writeArgumentError(fn: string)

proc main() =
  var args:tuple[fn: Path]
  args = parseArgs()
  let svd = parseSvdFile(args.fn)
  renderNimFromSvd(stdout, svd)

proc parseArgs(): tuple[fn: Path] =
  ## Acts on any options
  ## Returns
  for kind, key, val in getopt():
    case kind
    of cmdLongOption, cmdShortOption:
      case normalize(key)
      of "help", "h": writeHelp()
      of "version", "v": writeVersion()
    of cmdArgument:
      let fn = absolutePath(Path(key))
      if fileExists(fn):
        result.fn = Path(key)
        break
      else:
        writeArgumentError(key)
    else:
      writeHelp()

proc writeHelp() =
  stdout.write(Usage)
  stdout.flushFile()
  quit(0)

proc writeVersion() =
  stdout.write("version: " & getVersion() & "\n")
  stdout.flushFile()
  quit(0)

proc writeArgumentError(fn: string) =
  stderr.write("File does not exist: " & fn & "\n")
  stderr.flushFile()
  quit(0)



if isMainModule:
  main()
