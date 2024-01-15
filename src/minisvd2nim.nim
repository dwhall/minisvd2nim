import std/cmdline
import std/files
import std/paths
import std/strformat

import minisvd2nimpkg/svdparser

type SvdMainArgs = tuple[fn: Path]

# Declarations
proc parseArgs(): SvdMainArgs

proc main() =
  let args = parseArgs()
  let svd = parseSvdDevice(args.fn)

proc parseArgs(): SvdMainArgs =
  ## Returns validated command line args or prints usage to stderr
  ## if the given filename does not exist
  let args = commandLineParams()
  if len(args) == 1:
    let fn = absolutePath(Path(args[0]))
    if fileExists(fn):
      result.fn = fn
    else:
      stderr.write(fmt"File not found: {fn.string}\n")
  stderr.write("Usage: minisvd2nim <input.svd>\n")

if isMainModule:
  main()
