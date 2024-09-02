# minisvd2nim

[minisvd2nim](github.com/dwhall/minisvd2nim) is a command line tool
that processes one SVD file as input and renders declarative nim
source to stdout.  The declarations invoke templates and macros which
generate the final nim code.  This way, a programmer can change the meta
code, and not the minisvd2nim binary, to fix or improve the final code.

                                           ┌──────────────────────┐
                                           │                      │
                                           │   minisvd2nimpkg/    │
                                           │  metagenerator.nim   │
                                           │                      │
                                           └─────────▲────────────┘
                                                     │
                                                     │ imports
                                                     │
    ┌──────────────────────┐               ┌─────────┴────────────┐
    │                      │  minisvd2nim  │                      │
    │   Device .svd file   │    renders    │   Device .nim file   │
    │                      ├───────────────►                      │
    └──────────────────────┘               └─────────▲────────────┘
                                                     │
                                                     │ imports
                                                     │
                                           ┌─────────┴────────────┐
                                           │                      │
                                           │   User application   │
                                           │     .nim source      │
                                           │                      │
                                           └──────────────────────┘

## Related projects

[svd2nim](github.com/EmbeddedNim/svd2nim) is more robust
and comprehensive in its support for SVD files
and manufacturers of ARM based microcontrollers.

## If svd2nim exists then why make minisvd2nim?

1) I wanted to alter the syntax used to read from and write to registers and fields.
2) The size reductions I discovered would require a re-write of svd2nim
   that was more work than starting from scratch.
3) I wanted to use metaprogramming to emit code so that the minisvd2nim
   executable would not need to be re-compiled to alter the final output.

## Okay, so tell us about minisvd2min

The first reason it is called "mini" is because the codebase is small.
The parser is under 500 lines of cleanish code.
The renderer is under 500 lines of cleanish code.
The templates and macros are under 500 lines of some mind-bending shit.

The second reason it is called "mini" is because the resulting code,
when compiled to a binary, is as small as I can make it.
I'm always open to readable PRs to make the resulting code smaller.
The best way to reduce code size is to do as much as possible at compile-time.
This means use hard-coded constants and static parameters wherever possible.

## How to use minisvd2nim

0) Install minisvd2nim via nimble
1) Google for the latest .svd for your ARM CortexM device
2) `$ minisvd2nim device.svd > device.nim`
3) Put `device.nim` in your project
4) In your project, `import device` wherever you access the device

## How to access the device

I will tell you how to read from and write to the device,
but I can't tell you how to make it sing and dance.
The following Nim code shows how to access a ficticious register (REG)
of a peripheral (PERIPH) and its fields (FIELD1 and FIELD2).

```nim
import device

# read the register (v is a distinct type)
var v = PERIPH.REG

# ERROR cannot modify the distinct type with normal integers
v = v + 1
v = v + 1'u32

# read the register as a uint32
var w = PERIPH.REG.uint32

# modify a uint32 with uint32 literals
w = w + 1'u32

# write to the register (accepts the register's distinct type)
PERIPH.REG = v

# write to the register (also accepts a uint32)
PERIPH.REG = w

# read a field from the register (f is a distinct type)
# the field is right-shifted to occupy bit 0,
# up to the field's width
var f = PERIPH.REG.FIELD1

# ERROR cannot modify the distinct type with normal integers
f = f + 1'u32

# read the field as a uint32
# the field is right-shifted to occupy bit 0,
# up to the field's width
var g = PERIPH.REG.FIELD1.uint32

# modify a uint32 with uint32 literals
g = g + 1'u32

# ERROR this is a compile-time error (for now).
# I'd like to make this work, but right now
# it would have an unexpected read.
PERIPH.REG.FIELD1 = g

# read-modify-write one field in the register.
# the uint32 value given in parentheses (42) will be
# left-shifted to the field's offset.
# The register's other bits are not affected.
PERIPH.REG.FIELD1(42).write()

# ERROR this by itself is a compile-time error
PERIPH.REG.FIELD1(42)

# read-modify-write more than one field in the register.
# the uint32 value given in parentheses will be
# left-shifted to the field's offset
PERIPH.REG
      .FIELD1(g)
      .FIELD2(42)
      .write()

# If the SVD file has enums declared for the registers' fields,
# the enum symbols may be used to set the field value:
PERIPH.REG.FIELD1(VAL1).write()

# or you may use the enums' value to compare against the register's value:
if PERIPH.REG.FIELD1 == VAL1:
  # do something
  discard
```

## The clever bits you don't see

The tricks I used to create small code is done by the output
of the templates and macros.  So you will never see that code.
However, I've approximated it here to help fellow
programmers understand what is going on under the hood.

When you run minisvd2nim on an .svd file, the resulting file
that we've been calling `device.nim` has a bunch of lines
that begin with `declareDevice`, `declarePeripheral`,
`declareRegister`, `declareField`, etc.

All of those `declare` calls are processed by Nim templates and macros
from the `minisvd2nimpkg/metagenerator` module.  Below is what each of those
would output, with some actual and imagined values for example.
(These code examples may become out of date if I update
the `metagenerator` module and forget to update this doc)

### declareDevice

```nim
# Device details
const DEVICE* = "STM32F446"
const MPU_PRESET* = true
const FPU_PRESENT* = true
const NVIC_PRIO_BITS* = 4
```

### declarePeripheral

```nim
type PERIPHBase = distinct RegisterVal
const PERIPH* = PERIPHBase(0x40021000)
```

### declareInterrupt

```nim
const irqSPI1* = 35
```

### declareRegister

```nim
type PERIPH_REGVal* = distinct RegisterVal  # for distinct registers
type PERIPH_REGVal* = object of PERIPH_BASEREGVal  # for derived registers
type PERIPH_REGPtr = ptr PERIPH_REGVal

const PERIPH_REG = cast[PERIPH_REGPtr](PERIPH.uint32 + 16)
# where 16 is the register's offset from the peripheral's base address
```
Declaring these types and using the `distinct` keyword ensures
a given PERIPH_REG cannot be written with values meant for another register.
Wrong names will result in a compile time error.

Notice that `PERIPH_REGVal`, `PERIPH_REGPtr` and `PERIPH_REG` are types private
to the `device.nim` file and are only meant for internal use.

**Only the public constants `PERIPH` and `REG` are meant for end use
in the exact form: `PERIPH.REG`.**

When the register has read access, this becomes available:
```nim
template REG*(base: static PERIPHBase): PERIPH_REGVal =
  volatileLoad(PERIPH_REG)
```
Notice that the `declareRegister` template is emitting this template
and `volatileLoad` itself is a template.  I told you there was some
mind-bending shit.  An unfortunate side-effect of all this is that
any errors here will have messages that are difficult to understand.
In other words, only modify `metagenerator.nim` if you know what you are doing.
You have been warned.

When the register has write access, these become available:
```nim
template `REG=`*(base: static PERIPHBase, val: PERIPH_REGVal) =
  volatileStore(PERIPH_REG, val)

template `REG=`*(base: static PERIPHBase, val: uint32) =
  volatileStore(PERIPH_REG, val)

template write*(regVal: PERIPH_REGVal) =
  volatileStore(PERIPH_REG, regVal)
```

### declareField

When the field has read access, this becomes available:
```nim
template FIELD*(regVal: PERIPH_REGVal): PERIPH_REGVal =
  getField[PERIPH_REGVal](regVal, bitOffset, bitWidth)
```

When the field has write access, this becomes available:
```nim
template FIELD*(regVal: PERIPH_REGVal, fieldVal: uint32): PERIPH_REGVal =
  setField[PERIPH_REGVal](regVal, fieldVal, bitOffset, bitWidth)
```

You can look at [the source](https://github.com/dwhall/minisvd2nim/blob/main/src/minisvd2nimpkg/metagenerator.nim#L123)
if you want to see the implementations of `getField` and `setField`.

### declare declareFieldEnum

When the field has an enumeration declared, these become available:
```nim
declareEnum(`enumType`):
  VAL1
  VAL2
  VAL3
proc FIELD*(regVal: PERIPH_REGVal, fieldVal: `enumType`): PERIPH_REGVal {.inline.} =
  setField[PERIPH_REGVal](regVal, fieldVal.uint32, bitOffset, bitWidth)
```

The `enumType` is not available to the programmer.  It is distinct and only
used to constrain the values that can be passed to the `fieldName` proc.
The enum symbols are available to the programmer and can be used as an
argument to `FIELD()` and to use with values from PERIPH.REG.

## How to hack on minisvd2nim

There are two parts to `minisvd2nim` parsing and rendering the SVD (.xml) file;
and using templates and macros to create usable code from the device file.
Once we get ALL possible XML nodes parsed and rendered, then what remains is
meta programming for our applications' needs.

To experiment with the metaprogramming, you need to do these three things:
1) copy `metagenerator.nim` to your project and put it in the same place as
   your `device.nim`.
2) edit your `device.nim` to `import metagenerator.nim`.  Nim grabs the local
   copy instead of the one from the library.
3) edit the local `metagenerator.nim` to generate the output you want.

## Tests

This repository contains tests that should grow with the code.
Right now, there is one test that will fail the very first time the tests are run.
Just run the tests again: `nimble test`

## The author would like to thank

* @ElegantBeef and @Araq for answering my Nim questions on the [forum](https://forum.nim-lang.org/).
* https://asciiflow.com for making ASCII art easy
