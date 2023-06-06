## This module implements the window view.
##

import deques

import nazopuyo_core
import nigui
import puyo_core
import tiny_sqlite

import ./field
import ./firstPair
import ./messages
import ./pairs
import ./requirement
import ./root
import ../config
import ../resource
import ../state

type AppWindow* = ref object of WindowImpl
  ## Application Window.
  nazo*: ref Nazo
  positions*: ref Positions
  mode*: ref Mode
  state*: ref SimulatorState
  focus*: ref Focus
  inserted*: ref bool
  nextIdx*: ref Natural
  nextPos*: ref Position
  cfg*: ref Config
  resource*: ref Resource
  db*: ref DbConn

  fieldControl*: FieldControl
  firstPairControl*: FirstPairControl
  messagesControl*: MessagesControl
  pairsControl*: PairsControl
  requirementControl*: RequirementControl

  originalNazo*: Nazo # nazo puyo before move
  stableNazo*: Nazo # latest stable (will not fall or disappear) nazo puyo

  undoDeque*: Deque[Nazo]
  redoDeque*: Deque[Nazo]

  recordState*: RecordState
  records*: seq[tuple[nazo: Nazo, positions: Positions]]
  recordIdx*: Natural

# ------------------------------------------------
# Constructor
# ------------------------------------------------

proc newWindowView(
  nazo: Nazo,
  positions: Positions,

  mode: Mode,
  state: SimulatorState,
  focus: Focus,
  inserted: bool,
  nextIdx: Natural,
  nextPos: Position,

  cfg: ref Config,
  resource: ref Resource,
  db: ref DbConn,
): AppWindow {.inline.} =
  ## Returns a new window view.
  result = new AppWindow
  result.init

  result.nazo = new Nazo
  result.nazo[] = nazo

  result.positions = new Positions
  result.positions[] = positions

  result.mode = new Mode
  result.mode[] = mode

  result.state = new SimulatorState
  result.state[] = state

  result.focus = new Focus
  result.focus[] = focus

  result.inserted = new bool
  result.inserted[] = inserted

  result.nextIdx = new Natural
  result.nextIdx[] = nextIdx

  result.nextPos = new Position
  result.nextPos[] = nextPos

  result.cfg = cfg
  result.resource = resource
  result.db = db

  let rootControl = newRootControl(
    result.nazo,
    result.positions,
    result.mode,
    result.state,
    result.focus,
    result.inserted,
    result.nextIdx,
    result.nextPos,
    result.cfg,
    result.resource)
  result.add rootControl

  result.fieldControl = rootControl.fieldControl
  result.firstPairControl = rootControl.firstPairControl
  result.messagesControl = rootControl.messagesControl
  result.pairsControl = rootControl.pairsControl
  result.requirementControl = rootControl.requirementControl

  result.originalNazo = nazo
  result.stableNazo = nazo

  result.title = "Pon!通"
  result.width = rootControl.naturalWidth
  result.height = rootControl.naturalHeight
  result.resizable = false

proc newWindowView*(
  nazo: Nazo, positions: Positions, mode: Mode, cfg: ref Config, resource: ref Resource, db: ref DbConn
): AppWindow {.inline.} =
  ## Returns a new window view.
  newWindowView(
    nazo,
    positions,
    mode,
    MOVING,
    Focus.FIELD,
    false,
    0.Natural,
    POS_3U,
    cfg,
    resource,
    db)

# ------------------------------------------------
# Operation
# ------------------------------------------------

proc copyView*(window: AppWindow): AppWindow {.inline.} =
  ## Copies the :code:`window` view.
  result = newWindowView(
    window.nazo[],
    window.positions[],
    window.mode[],
    window.state[],
    window.focus[],
    window.inserted[],
    window.nextIdx[],
    window.nextPos[],
    window.cfg,
    window.resource,
    window.db)

  result.originalNazo = window.originalNazo
  result.stableNazo = window.stableNazo

  result.undoDeque = window.undoDeque
  result.redoDeque = window.redoDeque

  result.recordState = window.recordState
  result.records = window.records
  result.recordIdx = window.recordIdx