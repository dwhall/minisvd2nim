# minisvd2nim

[minisvd2nim](github.com/dwhall/minisvd2nim) is a command line tool
that processes one SVD file as input and renders declarative nim
source to stdout.  The declarations are calls to templates which render
the final nim code.  This way, a programmer can change the templates, and
not the minisvd2nim binary, if changes are needed or improvements are found
to the final code.

                                           ┌──────────────────────┐
                                           │                      │
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

[svd2nim](github.com/EmbeddedNim/svd2nim) works well and
is more comprehensive in its support for SVD files
and manufacturers of ARM based microcontrollers.

## Thanks

go to:

* https://asciiflow.com for making ASCII art easy
