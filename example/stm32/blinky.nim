# Run `nim build` in this directory to build:
# 1) the device package, stm32f446/, from the SVD file and
# 2) this example program

import stm32f446/[rcc, gpioa]

proc main() =
  # Enable GPIO A and set pin A5 as an output
  RCC.AHB1ENR.read().GPIOAEN(1'u32).write()
  GPIOA.MODER.read().MODER5(1'u32).write()

  # Use bit-banding to toggle pin A5
  # If pin A5 is connected to an LED it will glow dim
  # because of how fast it is blinking
  while true:
    GPIOA.BSRR.BS5(1)
    GPIOA.BSRR.BR5(1)

when isMainModule:
  main()
