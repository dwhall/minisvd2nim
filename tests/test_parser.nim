import std/paths
import std/strutils
import unittest

import minisvd2nimpkg/parser
import minisvd2nimpkg/svdtypes

let fn_test = getCurrentDir() / Path("tests") / Path("test.svd")

test "there shall be a procedure to parse .svd files":
  check compiles(parseSvdFile(fn_test))

test "the .svd parse procedure shall return an SvdDevice":
  let obj = parseSvdFile(fn_test)
  check typeof(obj) is SvdDevice

test "the .svd parse procedure should return an expected value":
  let device = parseSvdFile(fn_test)
  check device.name == "ARMCM4"

let fn_stm32 = getCurrentDir() / Path("tests") / Path("STM32F446_v1_7.svd")
let device = parseSvdFile(fn_stm32)

test "the .svd parse procedure on a STM32 .svd file":
  check device.name == "STM32F446"

test "the .svd parse procedure should parse an interrupt":
  let irqs = device.peripherals[0].interrupts
  check irqs.len > 0
  check irqs[0].name == "DCMI"
  check irqs[0].value == 78

test "the .svd parse procedure removes disruptive whitespace from descriptions":
  let description = device.peripherals[0].registers[0].fields[4].description  # DCMI_CR.ESS
  check description == "Embedded synchronization select"

test "derived peripherals should overwrite their parent's fields with their own":
  # The problem was DMA1 was derived from DMA2 and ended up with this:
  # declareInterrupt(peripheralName = DMA1, interruptName = DMA2_Stream0, interruptValue = 56, interruptDesc = "DMA2 Stream0 global interrupt")
  for p in device.peripherals:
    if p.name == "DMA1":
      for irq in p.interrupts:
        check irq.name.startsWith("DMA1")
      break

## example.svd comes from: https://www.keil.com/pack/doc/CMSIS/SVD/html/svd_Example_pg.html
let fn_example = getCurrentDir() / Path("tests") / Path("example.svd")
let example = parseSvdFile(fn_example)

test "Register field enumerated values are parsed":
  for p in example.peripherals:
    for r in p.registers:
      for f in r.fields:
        if p.name == "TIMER0" and r.name == "INT" and f.name == "MODE":
          check len(f.fieldEnum.values) == 3
          check f.fieldEnum.values[0].name == "Match"
          check f.fieldEnum.values[0].value == 0'u32

