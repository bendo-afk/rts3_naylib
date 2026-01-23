import ../map/tilemap
import ../unit/unit

type
  # チームごとの進行状態をまとめる
  ActionState = ref object
    leftCd: float
    lockedUnit: Unit
    targetTile: Vector2i
    isRaise: bool

type HeightSystem* = object
  map: TileMap
  maxCd: float
  states: array[2, ActionState]


proc newHeightSystem*(map: TileMap, maxCd: float): HeightSystem =
  var initialActionState = ActionState(leftCd: maxCd)
  var states: array[2, ActionState] = [initialActionState, initialActionState.deepCopy()]
  HeightSystem(map: map, maxCd: maxCd, states: states)


# チーム判定用のヘルパー
template s(self: HeightSystem, isAlly: bool): ActionState =
  if isAlly: self.states[0] else: self.states[1]

proc canStartAction(self: HeightSystem, isAlly: bool): bool =
  let state = self.s(isAlly)
  return state.leftCd <= 0 and state.lockedUnit.isNil


proc tryStart*(self: var HeightSystem, unit: Unit, isAlly: bool, tile: Vector2i, isRaise: bool) =
  if not canStartAction(self, isAlly): return

  unit.heightAction.isChanging = true
  var state = self.s(isAlly)
  state.lockedUnit = unit
  state.targetTile = tile
  state.isRaise = isRaise  


proc stopAction(lockedUnit: var Unit) =
  lockedUnit.heightAction.reset()
  lockedUnit = nil


proc update*(self: var HeightSystem, delta: float) =
  var changedTile = Vector2i(x: int.low, y: int.low)
  var isRaise = false
  for state in self.states:
    if state.leftCd > 0:
      state.leftCd -= delta
    
    if not state.lockedUnit.isNil:
      var u = state.lockedUnit

      if not self.map.canChangeHeight(state.targetTile, state.isRaise) or
          not self.map.isMovable(self.map.pos2tile(u.move.pos), state.targetTile):
        if state.targetTile != changedTile:
          stopAction(u)
          continue
        # 同時に同じタイルを同方向に変えたとき、あとのチームがタイルをかえれず、スコアを得られない。
    
      u.heightAction.update(delta)

      if u.heightAction.leftTimer <= 0:
        stopAction(u)
        state.leftCd = self.maxCd
        if state.targetTile != changedTile or isRaise != state.isRaise:
          self.map.changeHeight(state.targetTile, state.isRaise)
          changedTile = state.targetTile
          isRaise = state.isRaise
        getScore(state)