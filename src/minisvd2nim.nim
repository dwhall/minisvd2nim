## main() is a command line tool that
## parses the given .svd input file and outputs nim source to stdout.
##

import std/cmdline
import std/files
import std/paths
import std/strformat

import minisvd2nimpkg/parser

type SvdMainArgs = tuple[fn: Path]

proc parseArgs(params: seq[string], args: var SvdMainArgs): bool

proc main() =
  var args:SvdMainArgs
  let params = commandLineParams()
  if parseArgs(params, args):
    let svd = parseSvdFile(args.fn)
    echo "Device name: ", svd.name

proc parseArgs(params: seq[string], args: var SvdMainArgs): bool =
  ## Returns validity of the command line parameters.
  ## If they are valid, returns them by reference
  if len(params) == 1:
    let fn = absolutePath(Path(params[0]))
    if fileExists(fn):
      args.fn = fn
      return true
    else:
      stderr.write(fmt"File not found: {fn.string}{'\n'}")
  else:
    stderr.write("Usage: minisvd2nim <input.svd>\n")
  return false

if isMainModule:
  main()
