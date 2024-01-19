## Renders Nim source to represent a device
## according to the given SVD data
##
## Reference:
##    https://www.keil.com/pack/doc/CMSIS/SVD/html/svd_Format_pg.html
##

import svdtypes

func renderCommentHeader(outf: File, device: SvdDevice)

func renderNimFromSvd*(outf: File, device: SvdDevice) =
  renderCommentHeader(outf, device)

func renderCommentHeader(outf: File, device: SvdDevice) =
  write(outf, "#\n")
