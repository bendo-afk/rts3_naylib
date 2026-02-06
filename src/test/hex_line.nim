import raylib, raymath
import ../battle/unit/unit
import ../battle/map/tilemap


const InvalidTile = Vector2i(x: int.low, y: int.low)


proc nextHexas*(map: TileMap, cur: Vector2i, pos1, pos2: Vector2): array[2, Vector2i] =
  let toTile = map.pos2tile(pos2)
  let curDist = calcDist(cur, toTile)
  var cands = [InvalidTile, InvalidTile, InvalidTile, InvalidTile]
  var turns: array[6, int]
  turns[0] = turn(pos1, pos2, map.getVertex(cur, 0))
  for i in 0..5:
    turns[(i + 1) mod 6] = turn(pos1, pos2, map.getVertex(cur, (i + 1) mod 6))
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


when isMainModule:
  var map = newTileMap(100, 19, 19, 5)
  let
    # fromPos = Vector2(x: 500, y: 500)
    toPos = Vector2(x: 3377.499, y: 2850.0)
  # for i in 0..5:
  #   echo i, ":", turn(fromPos, toPos, map.getVertex(Vector2i(x: 5, y: 4), i))
  # for i in 0..5:
  #   echo i, " ", turn(fromPos, toPos, map.getVertex(Vector2i(x: 6, y: 4), i))
  # for i in 0..5:
  #   echo i, " ", turn(fromPos, toPos, map.getVertex(Vector2i(x: 5, y: 5), i))
  
  # var curTiles = [map.pos2tile(fromPos), InvalidTile]
  # while true:
  #   echo curTiles
  #   if curTiles[0] == map.pos2tile(toPos):
  #     break
  #   curTiles = nextHexas(map, curTiles[0], fromPos, toPos)
  for y in 0..19:
    for x in 0..19:
      let tile = Vector2i(x: x, y: y)
      let center = map.tile2pos(tile)
      for i in 0..5:
        let adj = getAdjacentTile(tile, i)
        if not map.isExists(adj):
          continue
        let adjPos = map.tile2pos(adj)
        var weight = 0.0
        while weight < 1:
          let pos = lerp(center, adjPos, weight)
          var curTiles = [map.pos2tile(pos), InvalidTile]
          while true:
            if curTiles[0] == map.pos2tile(toPos):
              break
            curTiles = nextHexas(map, curTiles[0], pos, toPos)
            # echo curTiles
          # echo weight
          weight = min(1, weight + 3 / 60)
      # echo x, y
  echo "sucess!"