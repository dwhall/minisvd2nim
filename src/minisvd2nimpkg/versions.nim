import std/strutils
import std/strscans

proc getNimbleVersion(): string {.compileTime.} =
  ## Returns the version string from this project's nimble file
  let dump = staticExec "nimble dump ../.."
  for ln in dump.splitLines:
    if scanf(ln, "version: \"$*\"", result): return

proc getVersion*(): string {.compileTime.} =
  ## Returns the version string which is either
  ## prerelease: major.minor[.build-dev-<git info>]
  ## or release: major.minor[.build string]
  ## A release version is when a git tag exists
  ## that matches the Nimble version.
  let
    baseVersion = getNimbleVersion()
    gitTags: seq[string] = staticExec("git tag -l --points-at HEAD").split()
    prerelease = gitTags.find(baseVersion) < 0

  result =
    if prerelease:
      let shortHash = staticExec "git rev-parse --short HEAD"
      baseVersion & "-dev-" & shortHash
    else:
      baseVersion
