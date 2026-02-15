import std/strutils

proc getDotVersion*(): string {.compileTime.} =
  ## Returns the dot numbers from the .nimble file, e.g. "0.1.0"
  result = ""
  for line in staticRead("../../minisvd2nim.nimble").splitLines():
    if line.startsWith("version "):
      result = line.split("=")[1].replace("\"", "").replace(" ", "")
  assert result != ""

proc getVersion*(): string {.compileTime.} =
  ## Returns the full version string, e.g. "minisvd2nim version: 0.1.0 (commit: abcdef12)"
  const
    commit = staticExec("git log -n 1 --format=%H")
    modified = staticExec("git diff HEAD").len > 0
    modifiedSuffix = if modified: " +Δ" else: ""
  result = "minisvd2nim version: " & getDotVersion() & " (commit: " & commit[0..<8] & modifiedSuffix & ")"

