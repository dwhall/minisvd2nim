## Renders Nim source to represend a device
## according to the given SVD data
##
## Reference:
##    https://www.keil.com/pack/doc/CMSIS/SVD/html/svd_Format_pg.html
##

import parser

func renderNimFromSvd*(device: SvdDevice, outf: File) =
  outf.write(device.name)
