import ../map/tilemap
import ../unit/unit

type
  # チームごとの進行状態をまとめる
  ActionState = ref object
    leftCd*: float
    lockedUnitId: UnitId = -1
    targetTile: Vector2i
    isRaise: bool

  IsChanged = object
    isChanged*: bool
    tile*: Vector2i

type HeightSystem* = object
  map: TileMap
  maxCd: float
  states*: array[2, ActionState]
  areChanged*: array[2, IsChanged]


proc newHeightSystem*(map: TileMap, maxCd: float): HeightSystem =
  result = HeightSystem(map: map, maxCd: maxCd)
  for i in 0 ..< result.states.len:
    result.states[i] = ActionState(leftCd: maxCd)


# チーム判定用のヘルパー
template s(self: HeightSystem, isAlly: bool): ActionState =
  if isAlly: self.states[0] else: self.states[1]

proc canStartAction(self: HeightSystem, isAlly: bool): bool =
  let state = self.s(isAlly)
  return state.leftCd <= 0 and state.lockedUnitId == -1


proc tryStart*(self: var HeightSystem, unit: var Unit, isAlly: bool, tile: Vector2i, isRaise: bool) =
  if not canStartAction(self, isAlly): return

  unit.heightAction.isChanging = true
  var state = self.s(isAlly)
  state.lockedUnitId = unit.id
  state.targetTile = tile
  state.isRaise = isRaise  


proc update*(self: var HeightSystem, units:seq[Unit], delta: float) =
  var changedTile = Vector2i(x: int.low, y: int.low)
  var isRaise = false
  for i, state in self.states:
    self.areChanged[i].isChanged = false

    if state.leftCd > 0:
      state.leftCd = max(0, state.leftCd - delta)
    
    if not state.lockedUnitId == -1:
      var u = addr units[state.lockedUnitId]

      if not self.map.canChangeHeight(state.targetTile, state.isRaise) or
          not self.map.isMovable(self.map.pos2tile(u.move.pos), state.targetTile):
        if state.targetTile != changedTile:
          u.heightAction.reset()
          state.lockedUnitId = -1
          continue
        # 同時に同じタイルを同方向に変えたとき、あとのチームがタイルをかえれず、スコアを得られない。
    
      u.heightAction.update(delta)

      if u.heightAction.leftTimer <= 0:
        u.heightAction.reset()
        state.lockedUnitId = -1
        state.leftCd = self.maxCd
        if state.targetTile != changedTile or isRaise != state.isRaise:
          self.map.changeHeight(state.targetTile, state.isRaise)
          changedTile = state.targetTile
          isRaise = state.isRaise
                
        self.areChanged[i].isChanged = true
        self.areChanged[i].tile = state.targetTile
