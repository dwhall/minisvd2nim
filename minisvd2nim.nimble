#!fmt: off

# Package

version       = "0.7.8"
author        = "!!Dean"
description   = "A smaller SVD to nim generator tool"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["minisvd2nim"]

# Dependencies

requires "nim >= 2.0"
requires "unittest2 >= 0.2.4"
