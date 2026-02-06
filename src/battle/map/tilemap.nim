import random, sequtils
import raymath
import perlin
import hex_math
import my_astar
import astar

export hex_math


var
  frequency = 0.2
  octaves = 3
  persistence = 0.5

const MIN_GREEN = Color(r: 0, g: 60, b: 0, a: 255)
const MAX_GREEN = Color(r: 0, g: 255, b: 0, a: 255)


type TileMap* = ref object
  vsize*: float32
  maxX, maxY: int
  maxHeight: int
  vertices: array[6, Vector2]
  # all_verts: seq[array[6, Vector2]]
  colors: seq[Color]

  heights: ref seq[int]
  centerPos: seq[Vector2]

  grid*: Grid



proc getAllCenterPos(vsize: float32, max_x, max_y: int): seq[Vector2] =
  for y in 0..max_y:
    for x in 0..max_x:
      result.add(tile2pos(vsize, Vector2i(x: x, y: y)))


proc generateMap(map: var TileMap) =
  randomize()

  map.heights = new seq[int]
  map.heights[].setLen((map.max_x + 1) * (map.max_y + 1))
  for y in 0..map.max_y:
    for x in 0..map.max_x:
      var noise = newNoise(octaves, persistence)
      let value = noise.simplex(x.float * frequency, y.float * frequency)
      # map.heights[tile2index(map.max_x, Vector2i(x: x, y: y))] = int(map.max_height.float * value)
      map.heights[tile2index(map.max_x, Vector2i(x: x, y: y))] = 1


proc newTileMap*(vsize: float32, max_x, max_y, max_height: int): TileMap =
  var map = TileMap(
    vsize: vsize,
    max_x: max_x, max_y: max_y, max_height: max_height
  )

  map.vertices = getHexVertices(vsize)
  generateMap(map)

  for i in 0..max_height:
    map.colors.add(colorLerp(MIN_GREEN, MAX_GREEN, i / max_height))

  map.centerPos = getAllCenterPos(map.vsize, map.max_x, map.max_y)

  map.grid = newGrid(map.heights, maxX, maxY, maxHeight)

  return map


proc getHeight*(map: TileMap, tile: Vector2i): int =
  map.heights[tile2index(map.max_x, tile)]


proc canChangeHeight*(map: TileMap, tile: Vector2i, isRaise: bool): bool =
  let h = map.getHeight(tile)
  return not ((isRaise and h == map.maxHeight) or (not isRaise and h == 0))


proc changeHeight*(map: var TileMap, tile: Vector2i, isRaise: bool) =
  let diff = if isRaise: 1 else: -1
  map.heights[tile2index(map.max_x, tile)] += diff


proc getVertex*(map: TileMap, tile: Vector2i, index: int): Vector2 =
  tile2pos(map.vsize, tile) + map.vertices[index]



proc draw_tile(map: TileMap, tile: Vector2i) =
  drawPoly(tile2pos(map.vsize, tile), 6, map.vsize, 90, map.colors[map.get_height(tile)])
  

proc draw_map*(map: TileMap) =
  for y in 0..map.max_y:
    for x in 0..map.max_x:
      draw_tile(map, Vector2i(x: x, y: y))


proc tile2pos*(map: TileMap, tile: Vector2i): Vector2 =
  map.centerPos[tile2index(map.maxX, tile)]


proc pos2tile*(map: TileMap, pos: Vector2): Vector2i =
  pos2tile(map.vsize, pos)


proc calcPath*(map: TileMap, fromTile, toTile: Vector2i): seq[Vector2i] =
  path[Grid, Vector2i, float](map.grid, fromTile, toTile).toSeq()


proc isExists*(map: Tilemap, tile: Vector2i): bool =
  isExists(map.maxX, map.maxY, tile)


proc isMovable*(map: TileMap, t1, t2: Vector2i): bool =
  if calc_dist(t1, t2) > 1: return false
  let heightDiff = map.getHeight(t2) - map.getHeight(t1)
  if heightDiff > 1:
    return false
  return true
