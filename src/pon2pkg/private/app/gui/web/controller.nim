## This module implements the editor controller node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import karax/[karax, karaxdsl, kbase, vdom]
import ./[settings]
import ../../../../app/[gui, nazopuyo, simulator]
import ../../../../core/[nazopuyo]

proc initEditorControllerNode*(
    guiApplication: var GuiApplication, id = ""
): VNode {.inline.} =
  ## Returns the editor controller node.
  ## `id` is shared with other node-creating procedures and need to be unique.
  let
    workerRunning = guiApplication.solving or guiApplication.permuting
    workerDisable =
      workerRunning or guiApplication.simulator[].nazoPuyoWrap.pairsPositions.len == 0

    focusButtonClass =
      if guiApplication.focusEditor:
        kstring"button"
      else:
        kstring"button is-selected is-primary"
    solveButtonClass =
      if guiApplication.solving:
        kstring"button is-loading"
      else:
        kstring"button"
    permuteButtonClass =
      if guiApplication.permuting:
        kstring"button is-loading"
      else:
        kstring"button"

  proc permuteHandler() =
    guiApplication.simulator[].nazoPuyoWrap.flattenAnd:
      let (_, fixMoves, allowDouble, allowLastDouble) =
        getSettings(id, nazoPuyo.moveCount)
      guiApplication.permute fixMoves, allowDouble, allowLastDouble

  result = buildHtml(tdiv(class = "buttons")):
    button(
      class = solveButtonClass,
      disabled = workerDisable,
      onclick = () => (guiApplication.solve getSettings(id, 1).parallelCount),
    ):
      text "解探索"
    button(
      class = permuteButtonClass, disabled = workerDisable, onclick = permuteHandler
    ):
      text "ツモ並べ替え"
    button(class = focusButtonClass, onclick = () => guiApplication.toggleFocus):
      text "シミュを操作"