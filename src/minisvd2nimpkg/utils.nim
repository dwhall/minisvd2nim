import std/strutils

func parseBinaryInt(s: string): int32

func parseAnyInt*(s: string): int32 =
  let lowercase = s.toLower()
  if lowercase.startsWith("0x"):
    result = parseHexInt(lowercase).int32
  elif lowercase.startsWith("0b"):
    result = parseBinaryInt(lowercase[2 ..^ 1])
  elif lowercase.startsWith("#"):
    result = parseBinaryInt(lowercase[1 ..^ 1])
  else:
    result = parseInt(lowercase).int32

func parseBinaryInt(s: string): int32 =
  ## Argument, s, must have any prefix removed so that s[0] is '0' or '1'
  if 'x' in s:
    # side effect: stderr.write("Don't care bits in enum value strings are not yet supported.\n")
    result = -1
  else:
    result = parseBinInt(s).int32