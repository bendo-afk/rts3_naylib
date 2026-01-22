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
  for i in 0..1:
    var state = self.states[i]

    if state.leftCd > 0:
      state.leftCd -= delta
    
    if not state.lockedUnit.isNil:
      var u = state.lockedUnit

      if not self.map.canChangeHeight(state.targetTile, state.isRaise) or
          not self.map.isMovable(self.map.pos2tile(u.move.pos), state.targetTile):
        state.lockedUnit.stopAction()
        continue # このチームの処理は終了
    
      u.heightAction.update(delta)

      if u.heightAction.leftTimer <= 0:
        stopAction(u)
        state.leftCd = self.maxCd
        self.map.changeHeight(state.targetTile, state.isRaise)