## main() is a command line tool that
## parses the given .svd input file and outputs nim source to stdout.
##

import std/[files, parseopt, paths, strutils]

import minisvd2nimpkg/parser
import minisvd2nimpkg/renderer
import minisvd2nimpkg/versions

const Version = "version: " & getVersion() & "\p"
const Usage = "minisvd2nim [option] [<input.svd>]\p"
const Help = """
minisvd2nim - Generate Nim source from System View Description XML

Copyright 2024 Dean Hall.  See LICENSE.txt for details.

Usage:
""" & Usage & """

Options:
  --version             show the version
  --help                show this help
"""

proc parseArgs(): Path
proc writeMsgAndQuit(msg: string)

proc main() =
  let fn = parseArgs()
  let svd = parseSvdFile(fn)
  renderNimFromSvd(stdout, svd)

proc parseArgs(): Path =
  ## Returns only if a valid file is given
  ## otherwise it acts on any options and exits
  for kind, key, val in getopt():
    case kind
    of cmdLongOption, cmdShortOption:
      case normalize(key)
      of "version", "v": writeMsgAndQuit(Version)
      else: writeMsgAndQuit(Help)
    of cmdArgument:
      let fn = absolutePath(Path(key))
      if key.len > 0 and fileExists(fn):
        return Path(key)
      else:
        let error = "File does not exist: " & fn.string & "\p"
        writeMsgAndQuit(error)
    of cmdEnd:
      break
  writeMsgAndQuit(Usage)

proc writeMsgAndQuit(msg: string) =
  stdout.write(msg)
  stdout.flushFile()
  quit(0)

if isMainModule:
  main()
