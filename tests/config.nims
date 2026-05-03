switch("path", "$projectDir/../src")
switch("hint", "XDeclaredButNotUsed:off")

when defined(arm):
  # Nim-compiler options for 32-bit ARM
  switch("os", "any")
  switch("cpu", "arm")
  switch("cc", "gcc")
  switch("mm", "arc")
  switch("panics", "on") # requires local panicoverride.nim
  switch("threads", "off")
  switch("profiler", "off")
  switch("checks", "off")
  switch("assertions", "off")
  switch("stackTrace", "off")
  switch("lineTrace", "off")
  switch("exceptions", "goto")

  switch("define", "useMalloc")
  switch("define", "noSignalHandler")
  switch("define", "nimAllocPagesViaMalloc") # requires mm:arc or mm:orc
  switch("define", "nimPage512")
  switch("define", "nimMemAlignTiny")
else:
  patchFile("stdlib", "volatile", "volatile_mock")
