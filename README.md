# minisvd2nim

[minisvd2nim](github.com/dwhall/minisvd2nim) is a command line tool
that processes one
[SVD file](https://arm-software.github.io/CMSIS_5/SVD/html/index.html)
as input and renders declarative nim source to a nimble package.
The declarations invoke templates and macros during compilation of
the application.  This way, a programmer can change metagenerator to
improve the resulting code instead of changing and recompiling
the minisvd2nim binary.

                                           ┌──────────────────────┐
                                           │                      │
                                           │  metagenerator.nim   │
                                           │                      │
                                           └─────────▲────────────┘
                                                     │
                                                     │ imports
                                                     │
    ┌──────────────────────┐               ┌─────────┴────────────┐
    │                      │  minisvd2nim  │                      │┐
    │   device .svd file   │    renders    │    device package    ││
    │                      ├───────────────►                      ││
    └──────────────────────┘               └┬────────▲────────────┘│
                                            └────────┼─────────────┘
                                                     │ imports
                                                     │
                                           ┌─────────┴────────────┐
                                           │                      │
                                           │   user application   │
                                           │     .nim source      │
                                           │                      │
                                           └──────────────────────┘

## HOW TO Get Started

```
$ nimble build
$ nimble test
$ cd example/stm32
$ nim build
```
Take a look at `example/stm32/blinky.nim`.  It is not set to cross-compile to ARM,
but it should give you a starting point.

[c2lora](https://github.com/dwhall/c2lora) is a project that build a package for
a Nordic nRF52840.  The SVD stuff is in `deps/svd`.

## Related projects

[svd2nim](github.com/EmbeddedNim/svd2nim) is more robust
and comprehensive in its support for SVD files
and manufacturers of ARM based microcontrollers.

## If svd2nim exists then why make minisvd2nim?

0) I wanted to alter the syntax used to read from and write to registers and fields.
1) The size reductions I discovered would require a re-write of svd2nim
   that was more work than starting from scratch.
2) I wanted to use metaprogramming to emit code so that the minisvd2nim
   executable would not need to be re-compiled to alter the final output.

## Okay, so tell us about minisvd2min

The first reason it is called "mini" is because the codebase is small.
The parser is under 70 lines of cleanish code.
The renderer is under 400 lines of cleanish code.
The templates and macros are around 300 lines of some truly mind-bending shit.

The second reason it is called "mini" is because the resulting code,
when compiled to a binary, is as small as I can make it.
I'm always open to readable PRs to make the resulting code smaller.
The best way to reduce code size is to do as much as possible at compile-time.
This means use hard-coded constants and static parameters wherever possible.

## How to use minisvd2nim

0) `$ nimble install minisvd2nim`
1) Search the internet for the latest .svd for your device (not all devices have SVD files)
2) `$ minisvd2nim yourDeviceSvdFile.svd`
3) Have your application depend on the generated nimble package:
    `import <yourDevice>/[device, periph]`

The generated output depends on `metagenerator`, which should be copied
to the generated package directory.

Also note that when you import `periph` you are importing a Nim module
named lowercase `periph`.  You will then have access to that peripheral via the
symbols defined by the SVD file, which may be upper or lowercase.

## How to access the device

The following Nim code shows how to import a device and its peripherals,
access a ficticious register (REG) of a peripheral (PER) and its fields
(FIELD1 and FIELD2).  The import statement uses lowercase `periph` to access
the Nim module representing that peripheral.  But in your code you use the
uppercase `PER` to access the constant value representing the peripheral.
If your peripherals and registers were specified by an SVD file, you use
the names found therein, matching the capitalization.

```nim
import somedevice/[periph, spi, etc]

# read the register (v is a distinct type)
var v = PER.REG.read

# ERRORS: you cannot modify the distinct type with signed or unsigned integers
v = v + 1
v = v + 1'u32

# read the register as a uint32
var w = PER.REG.read().uint32

# modify a uint32 with uint32 literals
w = w + 1'u32

# write to the register (accepts the register's distinct type)
PER.REG.write(v)

# write to the register (also accepts a uint32)
PER.REG.write(w)

# read a field from the register (f is a distinct type)
# the field value is right-shifted if necessary to occupy bit 0, up to the field's width
var f = PER.REG.read().FIELD1

# ERRORS: you cannot modify the distinct type with signed or unsigned integers
f = f + 1
f = f + 1'u32

# read the field as a uint32
# the field value is right-shifted if necessary to occupy bit 0,
# up to the field's width
var g = PER.REG.read().FIELD1.uint32

# modify a uint32 with uint32 literals
g = g + 1'u32

# read-modify-write one field in the register.
# the uint32 value given in parentheses (42'u32) will be
# left-shifted to the field's offset if necessary.
# The register's other bits are not affected.
PER.REG.read().FIELD1(42'u32).write()

# This by itself is a write-only operation.
# The bits in REG outside FIELD1 are written to 0.
PER.REG.FIELD1(42'u32)

# read-modify-write more than one field in the register.
# the uint32 value given in parentheses will be
# left-shifted to the field's offset if necessary
PER.REG.read()
       .FIELD1(g)
       .FIELD2(42'u32)
       .write()

# If the SVD file has enums declared for the field values,
# the enum symbols (VAL1 in this example) may be used to set the field value:
PER.REG..read().FIELD1(VAL1).write()

# you may also use the enums to compare against the register's value:
if PER.REG.read().FIELD1 == VAL1:
  # do something
  discard
```

## Tests

This repository contains tests that should grow with the code.  Right now,
there is one test that will fail if the minisvd2nim binary is not built.
And there is one test that will fail the very first time the tests are run.
Just run the tests again: `nimble test`

## The author would like to thank

* @ElegantBeef, @Araq, @Isofruit and @janAkali for answering my Nim questions
  on the [forum](https://forum.nim-lang.org/).
* https://asciiflow.com for making ASCII art easy
