## This module implements the search result for pairs DB.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import karax/[karax, karaxdsl, vdom]
import ../../[misc]
import ../../../../apppkg/[marathon]
import ../../../../corepkg/[pair]

const ShowPairCount = 8

proc initPlayHandler(marathon: var Marathon, pairsIdx: Natural): () -> void =
  ## Returns a new click handler for play buttons.
  # NOTE: inlining does not work due to lazy evaluation
  () => (marathon.play pairsIdx)

proc initMarathonSearchResultNode*(marathon: var Marathon): VNode {.inline.} =
  ## Returns the search result node for pairs DB.
  result = buildHtml(table(class = "table")):
    tbody:
      let
        beginPairIdx =
          marathon.matchResultPageIdx * MatchResultPairsCountPerPage
        endPairIdx = min(
          marathon.matchResultPageIdx.succ * MatchResultPairsCountPerPage,
          marathon.matchPairsStrsSeq.len)

      for pairsIdx in beginPairIdx..<endPairIdx:
        tr:
          td:
            button(class = "button is-size-7",
                   onclick = marathon.initPlayHandler pairsIdx):
              span(class = "icon"):
                italic(class = "fa-solid fa-gamepad")

          let pairs = marathon.matchPairsStrsSeq[pairsIdx][
            0 ..< ShowPairCount * 2].toPairs
          for pairIdx in 0..<ShowPairCount:
            let pair = pairs[pairIdx]

            td:
              figure(class = "image is-16x16"):
                img(src = pair.child.cellImageSrc)
              figure(class = "image is-16x16"):
                img(src = pair.axis.cellImageSrc)