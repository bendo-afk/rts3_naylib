import ../map/tilemap
import ../unit/unit

type
  # チームごとの進行状態をまとめる
  ActionState = ref object
    leftCd*: float32
    lockedUnitId: UnitId = -1
    targetTile: Vector2i
    isRaise: bool

  IsChanged = object
    isChanged*: bool
    tile*: Vector2i

type HeightSystem* = object
  map: TileMap
  maxCd: float32
  states*: array[Team, ActionState]
  areChanged*: array[Team, IsChanged]


proc newHeightSystem*(map: TileMap, maxCd: float32): HeightSystem =
  result = HeightSystem(map: map, maxCd: maxCd)
  for t in Team:
    result.states[t] = ActionState(leftCd: maxCd)


proc canStartAction(self: HeightSystem, team: Team): bool =
  let state = self.states[team]
  return state.leftCd <= 0 and state.lockedUnitId == -1


proc tryStart*(self: var HeightSystem, unit: var Unit, team: Team, tile: Vector2i, isRaise: bool) =
  if not canStartAction(self, team): return

  unit.heightAction.isChanging = true
  var state = self.states[team]
  state.lockedUnitId = unit.id
  state.targetTile = tile
  state.isRaise = isRaise  


proc update*(self: var HeightSystem, units:seq[Unit], delta: float32) =
  var changedTile = Vector2i(x: int.low, y: int.low)
  var isRaise = false
  for i, state in self.states:
    self.areChanged[i].isChanged = false

    if state.leftCd > 0:
      state.leftCd = max(0, state.leftCd - delta)
    
    if not state.lockedUnitId == -1:
      var u = addr units[state.lockedUnitId]

      if u[].isDead():
        u.heightAction.reset()
        state.lockedUnitId = -1
        continue
      
      if not self.map.isExists(state.targetTile) or
          not self.map.isMovable(self.map.pos2tile(u.move.pos), state.targetTile) or
          not self.map.canChangeHeight(state.targetTile, state.isRaise):
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
