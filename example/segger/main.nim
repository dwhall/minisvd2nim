# Run `nim build` in this directory to build:
# 1) the device package, exampleCM4F/, from the SVD file and
# 2) this example program

import cm4f/[nvic, scb]

proc main() =
  let i0 = NVIC.NVIC_ISER_0
  discard i0

  let s = SCB.SCR.SLEEPDEEP
  discard s

when isMainModule:
  main()
