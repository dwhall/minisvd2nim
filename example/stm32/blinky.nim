# Run `nim build` in this directory to build:
# 1) the device package, stm32f446/, from the SVD file and
# 2) this example program

import stm32f446/[rcc, gpioa]

proc main() =
  # Enable GPIO A and set pin A5 as an output
  RCC.AHB1ENR.GPIOAEN(1'u32).write()
  GPIOA.MODER.MODER5(1'u32).write()

  # Use bit-banding to toggle pin A5
  # If pin A5 is connected to an LED it will glow dim
  # because of how fast it is blinking
  const gpioA5set = 1'u32 shl 5
  const gpioA5reset = 1'u32 shl (5 + 16)
  while true:
    GPIOA.BSRR = gpioA5set
    GPIOA.BSRR = gpioA5reset

when isMainModule:
  main()
