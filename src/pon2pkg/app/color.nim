## This module implements colors.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

type Color* = object ## Color.
  red*: byte
  green*: byte
  blue*: byte
  alpha*: byte = 255

const
  SelectColor* = Color(red: 0, green: 209, blue: 178)
  GhostColor* = Color(red: 230, green: 230, blue: 230)
  WaterColor* = Color(red: 135, green: 206, blue: 250)
  DefaultColor* = Color(red: 255, green: 255, blue: 255)

