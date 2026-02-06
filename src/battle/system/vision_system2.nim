import raylib
import ../unit/unit
import ../map/tilemap


const InvalidTile = Vector2i(x: int.low, y: int.low)


type VisionSystem* = object
  map: TileMap
  lMargin, sMargin: float32


proc newVisionSystem*(map: TileMap, lMargin, sMargin: float32): VisionSystem =
  VisionSystem(map: map, lMargin: lMargin, sMargin: sMargin)


proc nextHexas*(map: TileMap, cur: Vector2i, pos1, pos2: Vector2): array[2, Vector2i] =
  let toTile = map.pos2tile(pos2)
  let curDist = calcDist(cur, toTile)
  # turnsで候補を出す
  # 最大4つでてくるが、そのうち目的地までの距離が短い順にcur1 cur2に入れる。
  # ただし、現在のタイルより長くなる場合ははじく。
  # cur1に対して1を実行する。cur1==目的地となれば終了
  var cands = [InvalidTile, InvalidTile, InvalidTile, InvalidTile]
  var turns: array[6, int]
  turns[0] = turn(pos1, pos2, map.getVertex(cur, 0))
  for i in 0..5:
    turns[(i + 1) mod 6] = turn(pos1, pos2, map.getVertex(cur, (i + 1) mod 6))
    # if cur == Vector2i(x: 6, y: 4):
    #   echo turns
    if turns[i] == 0 and turns[(i + 1) mod 6] == 0:
      cands[0] = getAdjacentTile(cur, i)
      cands[1] = getAdjacentTile(cur, (i + 1) mod 6)
      cands[2] = getAdjacentTile(cur, (i + 5) mod 6)
      break
    elif turns[i] == 0:
      for j, c in cands.mpairs:
        if c == InvalidTile:
          c = getAdjacentTile(cur, (i+5) mod 6)
          cands[j + 1] = getAdjacentTile(cur, i)
          break
    if turns[i] * turns[(i + 1) mod 6] == -1:
      for c in cands.mitems:
        if c == InvalidTile:
          c = getAdjacentTile(cur, i)
          break
  
  var dists = [int.high, int.high, int.high, int.high]
  for i, c in cands:
    if c == InvalidTile or not map.isExists(c): continue
    dists[i] = calcDist(c, toTile)
  
  var best0, best1 = int.high
  var idx0, idx1 = -1

  for i in 0..3:
    let d = dists[i]
    if d == int.high: continue
    if d < best0:
      best1 = best0
      idx1 = idx0
      best0 = d
      idx0 = i
    elif d < best1:
      best1 = d
      idx1 = i
  
  # if cur == Vector2i(x: 6, y: 4):
  #   echo cands

  result[0] = if idx0 != -1: cands[idx0] else: InvalidTile
  if best1 <= curDist and idx1 != -1:
    result[1] = cands[idx1]
  else:
    result[1] = InvalidTile
  # if pos1 == map.tile2pos(Vector2i(x: 1, y: 7)):
  #   echo result

proc isVisible*(visionSystem: VisionSystem, fromPos, toPos: Vector2, unit_height1, unit_height2: float32): VisibleState =
  template map: TileMap = visionSystem.map
  let
    fromTile = map.pos2tile(fromPos)
    toTile = map.pos2tile(toPos)
  if fromTile == toTile:
    return visVisible

  let
    height1: float32 = unit_height1 + map.getHeight(fromTile).float32
    height2: float32 = unit_height2 + map.getHeight(toTile).float32
    slope: float32 = (height2 - height1) / calc_dist(fromTile, toTile).float32
  
  var min_margin: float32 = system.Inf
  var tiles: seq[array[2,Vector2i]]
  var curTiles = [fromTile, InvalidTile]
  while true:
    tiles.add(curTiles)
    if curTiles[0] == toTile:
      break

    for t in curTiles:
      if t == InvalidTile: break
      let
        t_height = map.getHeight(t)
        t_dist = calc_dist(fromTile, t)
        t_margin: float32 = (slope * t_dist.float32) + height1 - t_height.float32
      if t_margin < min_margin:
        if t_margin < visionSystem.lMargin:
          return visNot
        min_margin = t_margin
    
    let lasts = curTiles
    curTiles = nextHexas(map, lasts[0], fromPos, toPos)
    # if fromTile == Vector2i(x: 5, y: 4):
      # echo curTiles
    if curTiles[0] == InvalidTile:
      echo fromPos, toPos
      curTiles = nextHexas(map, lasts[1], fromPos, toPos)

  if min_margin + visionSystem.sMargin < 0:
    return visHalf
  else:
    return visVisible


proc resetVision(units: var seq[Unit]) =
  for u in units.mitems:
    u.vision.visibleState = visNot
    u.visibleEnemyIds.setLen(0)


proc update*(self: var VisionSystem, units: var seq[Unit]) =
  units.resetVision()
  
  for i in 0 ..< units.len:
    let a = addr units[i]
    if a[].isDead(): continue
    
    for j in i + 1 ..< units.len:
      let b = addr units[j]
      if b[].isDead(): continue

      if a.team == b.team: continue
      
      let visState = self.isVisible(a.move.pos, b.move.pos, a.vision.height, b.vision.height)
      
      a.vision.visibleState = max(a.vision.visibleState, visState)
      b.vision.visibleState = max(b.vision.visibleState, visState)
      
      if visState == visVisible:
        a.visibleEnemyIds.add(b.id)
        b.visibleEnemyIds.add(a.id)
  
  for u in units.mitems:
    if u.vision.visibleState == visVisible:
      u.vision.lastPosition = u.move.pos

