# minisvd2nim

[minisvd2nim](github.com/dwhall/minisvd2nim) is a command line tool
that processes one SVD file as input and renders declarative nim
source to stdout.  The declarations invoke templates which produce
the final nim code.  This way, a programmer can change the templates, and
not the minisvd2nim binary, to fix or improve the final code.

                                           ┌──────────────────────┐
                                           │                      │
                                           │    minisvd2nimpkg/   │
                                           │    templates.nim     │
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

1) I wanted to alter the syntax used to read and write the registers and fields.
2) The size reductions I discovered would require a re-write of svd2nim
   that was more work than starting from scratch.
3) I wanted to use templates to emit code so that the minisvd2nim executable
   would not need to be compiled to experiment with altering the output syntax.

## Okay, so tell us about minisvd2min

The first reason it is called "mini" is because the codebase is small.
The parser is around 100 lines of cleanish code.
The renderer is around 200 lines of cleanish code.
The templates are around 120 lines of some mind-bending shit.

The second reason it is called "mini" is because the resulting code,
when compiled to a binary, is as small as I can make it.
I'm always open to readable PRs to make the resulting code smaller.
The best way to reduce code size is to do as much at compile-time as possible.
This means use hard-coded constants and static parameters wherever possible.

## How to use minisvd2nim

0) Install minisvd2nim via nimble
1) Google for the latest .svd for your ARM CortexM device
2) `$ minisvd2nim device.svd > device.nim`
3) Put `device.nim` in your project
4) In your project, `import device` wherever you access the device

## How to access the microcontroller

I will tell you how to read and write from/to the micro,
but I can't tell you how to make it sing and dance.
The following Nim code shows how to read and write
a ficticious register (REG) and its fields (FIELD1 and FIELD2)
of a peripheral (PERIPH).

```nim
import device

# read the register (v is a distinct type)
var v = PERIPH.REG

# these will fail compilation because of the distinct type
v = v + 1
v = v + 1'u32

# read the register as a uint32
var w = PERIPH.REG.uint32

# when you do math with a uint32, be sure
# to specify the literals as uint32 as well.
w = w + 1'u32

# write to the register (accepts a uint32)
PERIPH.REG = w

# read a field from the register
# the field is right-shifted to occupy bit 0, up to the field's width
var f = PERIPH.REG.FIELD1

# this will fail compilation because of the distinct type
f = f + 1'u32

# read the field as a uint32
# the field is right-shifted to occupy bit 0,
# up to the field's width
var g = PERIPH.REG.FIELD1.uint32
g = g + 1'u32

# this is a compile-time error (for now).
# I'd like to make this work, but right now
# it would have an unexpected read.
PERIPH.REG.FIELD1 = g

# read-modify-write one field in the register
# the value given in parentheses (42) will be
# left-shifted up to the field's offset.
# The bits not in the field are unaffected.
PERIPH.REG.FIELD1(42).write()

# this by itself is a compile-time error
PERIPH.REG.FIELD1(42)

# read-modify-write more than one field in the register.
# the value given in parentheses will be
# left-shifted up to the field's offset
PERIPH.REG
      .FIELD1(g)
      .FIELD2(42)
      .write()
```

## The clever bits you don't see

The tricks I used to create small code is done by the code
that is output from the templates.  So you will never see
that code.  However, I've reproduced it here to help fellow
programmers understand what is going on under the hood.

When you run minisvd2nim on an .svd file, the resulting file
that we've been calling `device.nim` has a bunch of lines
that begin with `declareDevice`, `declarePeripheral`,
`declareRegister`, `declareField`, etc.

All of those `declare` calls are processed by Nim templates from the
`minisvd2nimpkg/templates` module.  So here is what each of those
templates would output, with some actual and imagined values for example.
(These code examples may become out of date if I update
the templates module and forget to update this doc)

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
type PERIPH_REGVal* = distinct RegisterVal
type PERIPH_REGPtr = ptr PERIPH_REGVal

const PERIPH_REG = cast[PERIPH_REGPtr](PERIPH.uint32 + 16)
# where 16 is the register's offset from the peripheral's base address
```
Declaring these types and using the `distinct` keyword ensures
that we use PERIPH and REG names meant to work together.
Wrong names will result in a compile time error.

Notice that `PERIPH_REG` (with an underscore) is private;
you won't use it directly.  It is used as an argument to
`volatileLoad` and `volatileStore` by other templates below.

When the register has read access permissions, this becomes available:
```nim
template REG*(base: static PERIPHBase): PERIPH_REGVal =
  volatileLoad(PERIPH_REG)
```
Notice that the `declareRegister` template is emitting this template
and `volatileLoad` itself is a template.  I told you there was some
mind-bending shit.  But this also means that any errors here will have
near-useless error messages.

When the register has write access permissions, these become available:
```nim
template `REG=`*(base: static PERIPHBase, val: PERIPH_REGVal) =
  volatileStore(PERIPH_REG, val)

template `REG=`*(base: static PERIPHBase, val: uint32) =
  volatileStore(PERIPH_REG, val)

template write*(regVal: PERIPH_REGVal) =
  volatileStore(PERIPH_REG, regVal)
```

### declareField

When the field has read access permissions, this becomes available:
```nim
template FIELD*(regVal: PERIPH_REGVal): PERIPH_REGVal =
  getField[PERIPH_REGVal](regVal, bitOffset, bitWidth)
```

When the field has write access permissions, this becomes available:
```nim
template FIELD*(regVal: PERIPH_REGVal, fieldVal: uint32): PERIPH_REGVal =
  setField[PERIPH_REGVal](regVal, bitOffset, bitWidth, fieldVal)
```

You can look at the source if you want to see the implementations
of `getField` and `setField`.

## How to hack on minisvd2nim

There are two parts to `minisvd2nim` parsing and rendering the SVD (.xml) file;
and using templates to create usable code from the .nim file full of declarations.
Once we get ALL possible XML nodes parsed and rendered, then what remains is
creating templates for our applications' needs.

To experiment with the templates, you need to do these three things:
1) copy `templates.nim` to your project and put it in the same place as
   your `device.nim`
2) edit your `device.nim` to `import templates` so Nim grabs the local copy
   instead of the one from the library.
3) edit the local `templates.nim` to generate the output you want.

## The author would like to thank

* @ElegantBeef and @Araq for answering my Nim questions on the [forum](https://forum.nim-lang.org/).
* https://asciiflow.com for making ASCII art easy
