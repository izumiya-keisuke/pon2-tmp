## This module implements marathon mode.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[algorithm, critbits, math, os, sequtils, strutils, sugar, random]
import ./[key, simulator]
import ../core/[cell, field, puyopuyo]
import ../private/[misc]
import ../private/app/marathon/[common]

type
  MarathonMatchResult* = object ## Matching result.
    strings*: seq[string]
    pageCount*: Natural
    pageIndex*: Natural

  Marathon* = object ## Marathon manager.
    simulator: ref Simulator

    allPairsStrs: tuple[`seq`: seq[string], tree: CritBitTree[void]]
    matchResult: MarathonMatchResult

    focusSimulator: bool

    rng: Rand

const RawPairsTxt = staticRead currentSourcePath().parentDir.parentDir.parentDir.parentDir /
  "assets" / "pairs" / "swap.txt"

using
  self: Marathon
  mSelf: var Marathon
  rSelf: ref Marathon

# ------------------------------------------------
# Constructor
# ------------------------------------------------

proc initMarathon*(): Marathon {.inline.} =
  ## Returns a new marathon manager.
  result.simulator.new
  result.simulator[] = initPuyoPuyo[TsuField]().initSimulator(Play, false)

  result.allPairsStrs.seq = RawPairsTxt.splitLines
  result.allPairsStrs.tree = result.allPairsStrs.seq.toCritBitTree
  assert result.allPairsStrs.seq.len == AllPairsCount

  result.matchResult.strings = @[]
  result.matchResult.pageCount = 0
  result.matchResult.pageIndex = 0

  result.focusSimulator = false

  result.rng = initRand()

# ------------------------------------------------
# Property
# ------------------------------------------------

func simulator*(self): Simulator {.inline.} =
  ## Returns the simulator.
  self.simulator[].copy

func simulatorRef*(mSelf): ref Simulator {.inline.} =
  ## Returns the reference to the simulator.
  mSelf.simulator

func matchResult*(self): MarathonMatchResult {.inline.} =
  ## Returns the matching result.
  self.matchResult

func focusSimulator*(self): bool {.inline.} =
  ## Returns `true` if the simulator is focused.
  self.focusSimulator

# ------------------------------------------------
# Edit - Other
# ------------------------------------------------

func toggleFocus*(mSelf) {.inline.} = ## Toggles focusing to the simulator or not.
  mSelf.focusSimulator.toggle

# ------------------------------------------------
# Table Page
# ------------------------------------------------

func nextResultPage*(mSelf) {.inline.} =
  ## Shows the next result page.
  if mSelf.matchResult.pageCount == 0:
    return

  if mSelf.matchResult.pageIndex == mSelf.matchResult.pageCount.pred:
    mSelf.matchResult.pageIndex = 0
  else:
    mSelf.matchResult.pageIndex.inc

func prevResultPage*(mSelf) {.inline.} =
  ## Shows the previous result page.
  if mSelf.matchResult.pageCount == 0:
    return

  if mSelf.matchResult.pageIndex == 0:
    mSelf.matchResult.pageIndex = mSelf.matchResult.pageCount.pred
  else:
    mSelf.matchResult.pageIndex.dec

# ------------------------------------------------
# Match
# ------------------------------------------------

func swappedPrefixes(prefix: string): seq[string] {.inline.} =
  ## Returns all prefixes with all pairs swapped.
  ## `prefix` need to be capital.
  assert prefix.len mod 2 == 0

  # If a non-double pair (AB) exists and cells in the pair (A and B) do not
  # appear in the others pairs, A and B are symmetric; no need to swap in this
  # function.
  # This process is applied to only one of all AB (fixing the concrete colors of
  # A and B).
  var
    pairIdx = [0, 0, 0, 0, 0, 0] # AB, AC, AD, BC, BD, CD
    pairCounts = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] # AB, ..., CD, AA, BB, CC, DD
  for i in countup(0, prefix.len.pred, 2):
    case prefix[i .. i.succ]
    of "AA":
      pairCounts[6].inc
    of "BB":
      pairCounts[7].inc
    of "CC":
      pairCounts[8].inc
    of "DD":
      pairCounts[9].inc
    of "AB", "BA":
      pairCounts[0].inc
      pairIdx[0] = i
    of "AC", "CA":
      pairCounts[1].inc
      pairIdx[1] = i
    of "AD", "DA":
      pairCounts[2].inc
      pairIdx[2] = i
    of "BC", "CB":
      pairCounts[3].inc
      pairIdx[3] = i
    of "BD", "DB":
      pairCounts[4].inc
      pairIdx[4] = i
    of "CD", "DC":
      pairCounts[5].inc
      pairIdx[5] = i

  let
    notDoublePairCount = pairCounts[0 ..< 6].sum2
    fixIdx =
      if pairCounts[0] > 0 and notDoublePairCount == pairCounts[0] and
          pairCounts[6] + pairCounts[7] == 0:
        pairIdx[0]
      elif pairCounts[1] > 0 and notDoublePairCount == pairCounts[1] and
        pairCounts[6] + pairCounts[8] == 0:
        pairIdx[1]
      elif pairCounts[2] > 0 and notDoublePairCount == pairCounts[2] and
        pairCounts[6] + pairCounts[9] == 0:
        pairIdx[2]
      elif pairCounts[3] > 0 and notDoublePairCount == pairCounts[3] and
        pairCounts[7] + pairCounts[8] == 0:
        pairIdx[3]
      elif pairCounts[4] > 0 and notDoublePairCount == pairCounts[4] and
        pairCounts[7] + pairCounts[9] == 0:
        pairIdx[4]
      elif pairCounts[5] > 0 and notDoublePairCount == pairCounts[5] and
        pairCounts[8] + pairCounts[9] == 0:
        pairIdx[5]
      else:
        -1

    pairsSeq = collect:
      for i in countup(0, prefix.len.pred, 2):
        let
          c1 = prefix[i]
          c2 = prefix[i.succ]

        if c1 == c2 or i == fixIdx:
          @[c1 & c2]
        else:
          @[c1 & c2, c2 & c1]

  result = pairsSeq.product2.mapIt it.join

func initReplaceData(keys: string): seq[seq[(string, string)]] {.inline.} =
  ## Returns arguments for prefix replacing.
  case keys.len
  of 1:
    result = collect:
      for p0 in ColorPuyo.low .. ColorPuyo.high:
        @[($keys[0], $p0)]
  of 2:
    result = collect:
      for p0 in ColorPuyo.low .. ColorPuyo.high:
        for p1 in ColorPuyo.low .. ColorPuyo.high:
          if p0 != p1:
            @[($keys[0], $p0), ($keys[1], $p1)]
  of 3:
    result = collect:
      for p0 in ColorPuyo.low .. ColorPuyo.high:
        for p1 in ColorPuyo.low .. ColorPuyo.high:
          for p2 in ColorPuyo.low .. ColorPuyo.high:
            if {p0, p1, p2}.card == 3:
              @[($keys[0], $p0), ($keys[1], $p1), ($keys[2], $p2)]
  of 4:
    result = collect:
      for p0 in ColorPuyo.low .. ColorPuyo.high:
        for p1 in ColorPuyo.low .. ColorPuyo.high:
          for p2 in ColorPuyo.low .. ColorPuyo.high:
            for p3 in ColorPuyo.low .. ColorPuyo.high:
              if {p0, p1, p2, p3}.card == 4:
                @[($keys[0], $p0), ($keys[1], $p1), ($keys[2], $p2), ($keys[3], $p3)]
  else:
    result = @[] # HACK: dummy to suppress warning
    assert false

const
  ReplaceDataSeq = [
    "A".initReplaceData, "AB".initReplaceData, "ABC".initReplaceData,
    "ABCD".initReplaceData,
  ]
  NeedReplaceKeysSeq = ["a".toSet2, "ab".toSet2, "abc".toSet2, "abcd".toSet2]

{.push warning[Uninit]: off.}
func match*(mSelf; prefix: string) {.inline.} =
  if prefix == "":
    mSelf.matchResult.strings = @[]
  else:
    var keys = prefix.toSet2
    if keys in NeedReplaceKeysSeq:
      if prefix.len mod 2 == 1:
        return

      let prefix2 = prefix.toUpperAscii # HACK: prevent to confuse 'b' with Blue

      mSelf.matchResult.strings = newSeqOfCap[string](45000)
      for replaceData in ReplaceDataSeq[keys.card.pred]:
        for prefix3 in prefix2.swappedPrefixes:
          {.push warning[ProveInit]: off.}
          mSelf.matchResult.strings &=
            mSelf.allPairsStrs.tree.itemsWithPrefix(prefix3.multiReplace replaceData).toSeq
          {.pop.}
    else:
      {.push warning[ProveInit]: off.}
      mSelf.matchResult.strings = mSelf.allPairsStrs.tree.itemsWithPrefix(prefix).toSeq
      {.pop.}

  mSelf.matchResult.pageCount =
    ceil(mSelf.matchResult.strings.len / MatchResultPairsCountPerPage).Natural
  mSelf.matchResult.pageIndex = 0

  if mSelf.matchResult.strings.len > 0:
    mSelf.focusSimulator = false
{.pop.}

# ------------------------------------------------
# Play
# ------------------------------------------------

proc play(mSelf; pairsStr: string) {.inline.} =
  ## Plays a marathon mode with the given pairs.
  mSelf.simulator[].reset
  mSelf.simulator[].pairsPositions = pairsStr.toPairsPositions

  mSelf.focusSimulator = true

proc play*(mSelf; pairsIdx: Natural) {.inline.} =
  ## Plays a marathon mode with the given pairs.
  mSelf.play mSelf.matchResult.strings[pairsIdx]

proc play*(mSelf; onlyMatched = true) {.inline.} =
  ## Plays a marathon mode with the random mathced pairs.
  ## If `onlyMatched` is true, the pairs are chosen from the matched result;
  ## otherwise, chosen from all pairs.
  if not onlyMatched:
    mSelf.play mSelf.rng.sample mSelf.allPairsStrs.seq
    return

  if mSelf.matchResult.strings.len == 0:
    return

  mSelf.play mSelf.rng.sample mSelf.matchResult.strings

# ------------------------------------------------
# Keyboard Operation
# ------------------------------------------------

proc operate*(mSelf; event: KeyEvent): bool {.inline.} =
  ## Does operation specified by the keyboard input.
  ## Returns `true` if any action is executed.
  if event == initKeyEvent("Tab", shift = true):
    mSelf.toggleFocus
    return true

  if mSelf.focusSimulator:
    return mSelf.simulator[].operate event

  result = false

