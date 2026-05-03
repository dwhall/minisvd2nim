#!fmt: off

task build, "Build the project":
  exec "nim c --outdir:. src/minisvd2nim.nim"

task test, "Run desktop tests":
  let desktopTests = [
    "test_cli.nim",
    "test_parser.nim",
    "test_renderer.nim",
    "test_metagenerator.nim",
    "test_metagenerator_dim_field.nim",
    "test_metagenerator_dim_reg.nim",
    "test_metagenerator_enum.nim",
    "test_regression.nim",
  ]
  for t in desktopTests:
    exec "nim r tests/" & t

task testarm, "Compile ARM target tests":
  # Compile only — cannot run ARM binary on host
  let targetTests = [
    "tests/test_arm32b.nim",
  ]
  for t in targetTests:
    exec "nim compileToC --compileOnly:on --path:src/minisvd2nimpkg " &
        "--cpu:arm --os:any " &
         "--arm.any.gcc.exe:arm-none-eabi-gcc " &
         "--arm.any.gcc.linkerexe:arm-none-eabi-gcc " &
         t
