# Run `nim build` in this directory to build:
# 1) the device package, exampleCM4F/, from the SVD file and
# 2) this example program

import cm4f/[nvic, scb]

proc main() =
  let i0 = NVIC.NVIC_ISER[0]
  NVIC.NVIC_ISER[1] = i0
  var idx = 2
  var i2 = NVIC.NVIC_ISER[idx]
  NVIC.NVIC_ISER[idx] = i2.uint32 + 0x42'u32

  let pri3 = NVIC.NVIC_IPR[90].PRI_N3
  NVIC.NVIC_IPR[123]
      .PRI_N3(3'u32)
      .PRI_N2(2'u32)
      .PRI_N1(1'u32)
      .PRI_N0(0'u32)
      .write()

  let s = SCB.SCR.SLEEPDEEP
  discard s

when isMainModule:
  main()
