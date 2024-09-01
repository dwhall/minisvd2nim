import std/paths
import std/strutils
import unittest

import minisvd2nimpkg/parser
import minisvd2nimpkg/svdtypes

let fn_test = getCurrentDir() / Path("tests") / Path("test.svd")

test "there SHALL be a procedure to parse .svd files":
  check compiles(parseSvdFile(fn_test))

test "the .svd parse procedure SHOULD return an SvdDevice":
  let obj = parseSvdFile(fn_test)
  check typeof(obj) is SvdDevice

test "the .svd parse procedure SHOULD return an expected value":
  let device = parseSvdFile(fn_test)
  check device.name == "ARMCM4"

let fn_stm32 = getCurrentDir() / Path("tests") / Path("STM32F446_v1_7.svd")
let device = parseSvdFile(fn_stm32)

test "the .svd parse procedure SHOULD return the device name when it is present in the .svd file":
  check device.name == "STM32F446"

test "the .svd parse procedure SHOULD parse an interrupt":
  let irqs = device.peripherals[0].interrupt
  check irqs.len > 0
  check irqs[0].name == "DCMI"
  check irqs[0].value == 78

test "the .svd parse procedure SHOULD remove disruptive whitespace from descriptions":
  # DCMI_CR.ESS
  let description = device.peripherals[0].registers[0].fields[4].description
  check description == "Embedded synchronization select"

test "derived peripherals SHOULD overwrite their parent's fields with their own":
  # The problem was DMA1 was derived from DMA2 and ended up with this:
  # declareInterrupt(peripheralName = DMA1, interruptName = DMA2_Stream0, interruptValue = 56, interruptDesc = "DMA2 Stream0 global interrupt")
  for p in device.peripherals:
    if p.name == "DMA1":
      for irq in p.interrupt:
        check irq.name.startsWith("DMA1")
      break

## example.svd comes from: https://www.keil.com/pack/doc/CMSIS/SVD/html/svd_Example_pg.html
## and is manually modified for specific tests using examples from:
## https://open-cmsis-pack.github.io/svd-spec/main/elem_registers.html
let fn_example = getCurrentDir() / Path("tests") / Path("example.svd")
let example = parseSvdFile(fn_example)

test "the .svd parse procedure SHOULD parse register field enumerated values":
  for p in example.peripherals:
    for r in p.registers:
      for f in r.fields:
        if p.name == "TIMER0" and r.name == "INT" and f.name == "MODE":
          check len(f.enumeratedValues.values) == 3
          check f.enumeratedValues.values[0].name == "Match"
          check f.enumeratedValues.values[0].value == 0'u32

test "the .svd parse procedure SHOULD be able to parse registers having the derivedFrom attribute":
  for p in example.peripherals:
    for r in p.registers:
      if p.name == "TIMER1" and r.name == "TimerCtrl1":
        check r.derivedFrom == "TimerCtrl0"
        check r.description == "Derived Timer"
        check r.addressOffset == 4
