import std/paths
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

test "the .svd parse procedure on a STM32 .svd file":
  let device = parseSvdFile(fn_stm32)
  check device.name == "STM32F446"

test "the .svd parse procedure should parse an interrupt":
  let device = parseSvdFile(fn_stm32)
  let irq = device.peripherals[0].interrupt
  check irq.name == "DCMI"
  check irq.value == 78
