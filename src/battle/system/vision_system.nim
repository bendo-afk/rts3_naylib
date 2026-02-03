import raylib
import ../unit/unit
import ../map/tilemap


const InvalidTile = Vector2i(x: int.low, y: int.low)


type VisionSystem* = object
  map: TileMap
  lMargin, sMargin: float32


proc newVisionSystem*(map: TileMap, lMargin, sMargin: float32): VisionSystem =
  VisionSystem(map: map, lMargin: lMargin, sMargin: sMargin)


proc firstStep*(map: TileMap, last1, last2, cur1, cur2: var Vector2i, pos1, pos2: Vector2) =
  cur1 = map.pos2tile(pos1)
  let to_tile = map.pos2tile(pos2)
  last1 = cur1

  var cand11, cand12, cand21, cand22 = InvalidTile

  for i in 0..5:
    let turn1 = turn(pos1, pos2, map.getVertex(cur1, i))
    let turn2 = turn(pos1, pos2, map.getVertex(cur1, (i + 1) mod 6))
    
    if turn1 == 0 and turn2 == 0:
      last2 = getAdjacentTile(cur1, i)
      let tile1 = getAdjacentTile(cur1, (i+1) mod 6)
      let tile5 = getAdjacentTile(cur1, (i+5) mod 6)
      if calc_dist(to_tile, tile1) < calc_dist(to_tile, tile5):
        cur1 = tile1
      else:
        cur1 = tile5
      return

    elif turn1 * turn2 == -1:
      if cand11 == InvalidTile:
        cand11 = getAdjacentTile(cur1, i)
      else:
        cand21 = getAdjacentTile(cur1, i)
    
    elif turn1 == 0:
      if cand11 == InvalidTile:
        cand11 = getAdjacentTile(cur1, (i+5) mod 6)
        cand12 = getAdjacentTile(cur1, i)
      else:
        cand21 = getAdjacentTile(cur1, (i+5) mod 6)
        cand22 = getAdjacentTile(cur1, i)

  if calc_dist(to_tile, cand11) < calc_dist(to_tile, cand21):
    cur1 = cand11
    if cand12 != InvalidTile:
      cur2 = cand12
  else:
    cur1 = cand21
    if cand22 != InvalidTile:
      cur2 = cand22


proc nextHexas*(map: TileMap, last1, last2, cur1, cur2: Vector2i, next1, next2: var Vector2i, pos1, pos2: Vector2) =
  if cur1 == InvalidTile: return
  var tile: Vector2i
  
  for i in 0..5:
    let turn1 = turn(pos1, pos2,
        map.getVertex(cur1, i))
    let turn2 = turn(pos1, pos2,
        map.getVertex(cur1, (i + 1) mod 6))

    if turn1 == 0 or turn2 == 0 or turn1 != turn2:
      tile = getAdjacentTile(cur1, i)
      if tile != cur1 and tile != cur2 and tile != next1 and
          tile != next2 and tile != last1 and tile != last2:
        if next1 == InvalidTile:
          next1 = tile
        elif next2 == InvalidTile:
          next2 = tile

      if turn1 == 0:
        tile = getAdjacentTile(cur1, (i + 5) mod 6)
        if tile != cur1 and tile != cur2 and tile != next1 and
            tile != next2 and tile != last1 and tile != last2:
          if next1 == InvalidTile:
            next1 = tile
          elif next2 == InvalidTile:
            next2 = tile

      if turn2 == 0:
        tile = getAdjacentTile(cur1, (i + 1) mod 6)
        if tile != cur1 and tile != cur2 and tile != next1 and
            tile != next2 and tile != last1 and tile != last2:
          if next1 == InvalidTile:
            next1 = tile
          elif next2 == InvalidTile:
            next2 = tile


proc isVisible*(visionSystem: VisionSystem, from_pos, to_pos: Vector2, unit_height1, unit_height2: float): VisibleState =
  template map: TileMap = visionSystem.map
  let
    from_tile = map.pos2tile(from_pos)
    to_tile = map.pos2tile(to_pos)
  if from_tile == to_tile:
    return visVisible

  let
    height1: float32 = unit_height1 + map.getHeight(from_tile).float32
    height2: float32 = unit_height2 + map.getHeight(to_tile).float32
    slope: float32 = (height2 - height1) / calc_dist(from_tile, to_tile).float32
  
  var min_margin: float32 = system.Inf

  var last1, last2, cur1, cur2, next1, next2 = InvalidTile
  
  first_step(map, last1, last2, cur1, cur2, from_pos, to_pos)

  while true:
    if cur1 == to_tile or cur2 == to_tile:
      break

    for t in [cur1, cur2]:
      if t == InvalidTile:
        break
      let
        t_height = map.getHeight(t)
        t_dist = calc_dist(from_tile, t)
        t_margin: float32 = (slope * t_dist.float32) + height1 - t_height.float32
      if t_margin < min_margin:
        if t_margin < visionSystem.lMargin:
          return visNot
        min_margin = t_margin
    
    next1 = InvalidTile
    next2 = InvalidTile
    next_hexas(map, last1, last2, cur1, cur2, next1, next2, from_pos, to_pos)
    next_hexas(map, last1, last2, cur2, cur1, next1, next2, from_pos, to_pos)
    (last1, last2) = (cur1, cur2)
    (cur1, cur2) = (next1, next2)

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
