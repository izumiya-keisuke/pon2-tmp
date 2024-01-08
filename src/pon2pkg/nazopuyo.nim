## This module implements [Nazo Puyo](https://vc.sega.jp/3ds/nazopuyo/).
## With `import pon2pkg/nazopuyo`, you can use all features provided by this
## module.
## Also, you can write such as `import pon2pkg/nazopuyopkg/nazopuyo` to import
## submodules individually.
##
## Submodule Documentations:
## - [generate](./nazopuyopkg/generate.html)
## - [nazopuyo](./nazopuyopkg/nazopuyo.html)
## - [mark](./nazopuyopkg/mark.html)
## - [permute](./nazopuyopkg/permute.html)
## - [solve](./nazopuyopkg/solve.html)
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ./nazopuyopkg/[generate, mark, nazopuyo, permute, solve]

export generate.GenerateError, generate.GenerateRequirementColor,
  generate.GenerateRequirement, generate.generate, generate.generates
export mark.MarkResult, mark.mark
export nazopuyo.RequirementKind, nazopuyo.RequirementColor,
  nazopuyo.RequirementNumber, nazopuyo.Requirement, nazopuyo.NazoPuyo,
  nazopuyo.NazoPuyos, nazopuyo.NoColorKinds, nazopuyo.NoNumberKinds,
  nazopuyo.ColorKinds, nazopuyo.NumberKinds, nazopuyo.initNazoPuyo,
  nazopuyo.initTsuNazoPuyo, nazopuyo.initWaterNazoPuyo,
  nazopuyo.toTsuNazoPuyo, nazopuyo.toWaterNazoPuyo, nazopuyo.moveCount,
  nazopuyo.isSupported, nazopuyo.flattenAnd, nazopuyo.`$`,
  nazopuyo.parseRequirement, nazopuyo.toString, nazopuyo.parseNazoPuyo,
  nazopuyo.parseTsuNazoPuyo, nazopuyo.parseWaterNazoPuyo, nazopuyo.toUriQuery,
  nazopuyo.toUri, nazopuyo.parseNazoPuyos
export permute.permute
export solve.solve