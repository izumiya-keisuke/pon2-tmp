## This module implements keyboard events.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

type KeyEvent* = object ## Keyboard Event.
  code: string
  shift: bool
  control: bool
  alt: bool
  meta: bool

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func initKeyEvent*(
    code: string, shift = false, control = false, alt = false, meta = false
): KeyEvent {.inline.} =
  ## Returns a new `KeyEvent`.
  result.code = code
  result.shift = shift
  result.control = control
  result.alt = alt
  result.meta = meta

