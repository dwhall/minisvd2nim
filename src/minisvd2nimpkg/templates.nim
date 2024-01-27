## These templates are not used by the minisvd2nim program.
## Instead, these templates are used by the generated output of minisvd2nim.
## This allows the programmer to change the final form of the Nim source
## without changing and recompiling minisvd2nim.

template declareDevice(deviceName: string, mpuPresent: bool, fpuPresent: bool, nvicPrioBits: int): untyped =
  # CPU details
  const DEVICE* = "{device.name}"
  const MPU_PRESET* = {device.cpu.mpuPresent}
  const FPU_PRESENT* = {device.cpu.fpuPresent}
  const NVIC_PRIO_BITS* = {device.cpu.nvicPrioBits}
