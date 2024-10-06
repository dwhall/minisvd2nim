# Run `nimble test` from the project root directory
# to build the device file, stm32f446.nim

import stm32f429/[rcc, gpioa]

proc main() =
  # Enable GPIO A and set A5 as an output
  RCC.AHB1ENR.GPIOAEN(1'u32).write()
  GPIOA.MODER.MODER5(1'u32).write()

  # Use bit-banding to toggle A5
  # If A5 is connected to an LED it will glow dim
  # because of how fast it is blinking
  const gpioA5set = 1'u32 shl 5
  const gpioA5reset = 1'u32 shl (5 + 16)
  while true:
    GPIOA.BSRR = gpioA5set
    GPIOA.BSRR = gpioA5reset

when isMainModule:
  main()
