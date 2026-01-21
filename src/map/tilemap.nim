import math, random
import raylib
import raymath
import perlin
import ../utils
import hex_math
import my_astar


var
  frequency = 0.2
  octaves = 3
  persistence = 0.5

const MIN_GREEN = Color(r: 0, g: 60, b: 0, a: 255)
const MAX_GREEN = Color(r: 0, g: 255, b: 0, a: 255)


type TileMap* = ref object
  vsize*: float
  max_x, max_y: int
  max_height: int
  vertices: array[6, Vector2]
  # all_verts: seq[array[6, Vector2]]
  colors: seq[Color]

  heights: seq[int]
  centerPos: seq[Vector2]

  grid*: Grid



proc getAllCenterPos(vsize: float, max_x, max_y: int): seq[Vector2] =
  for y in 0..max_y:
    for x in 0..max_x:
      result.add(tile2pos(vsize, Vector2i(x: x, y: y)))


proc generateMap(map: var TileMap) =
  randomize()

  map.heights = newSeq[int]((map.max_x + 1) * (map.max_y + 1))
  for y in 0..map.max_y:
    for x in 0..map.max_x:
      var noise = newNoise(octaves, persistence)
      let value = noise.simplex(x.float * frequency, y.float * frequency)
      map.heights[tile2index(map.max_x, Vector2i(x: x, y: y))] = int(map.max_height.float * value)


proc newTileMap*(vsize: float, max_x, max_y, max_height: int): TileMap =
  var map = TileMap(
    vsize: vsize,
    max_x: max_x, max_y: max_y, max_height: max_height
  )

  let
    hsize = sqrt(3.0) / 2 * vsize
    half_vsize = vsize / 2
  map.vertices = [
    Vector2(x: 0, y: -vsize),
    Vector2(x: hsize, y: -half_vsize),
    Vector2(x: hsize, y: half_vsize),
    Vector2(x: 0, y: vsize),
    Vector2(x: -hsize, y: half_vsize),
    Vector2(x: -hsize, y: -half_vsize)
  ]

  generateMap(map)

  for i in 0..max_height:
    map.colors.add(colorLerp(MIN_GREEN, MAX_GREEN, i / max_height))

  map.centerPos = getAllCenterPos(map.vsize, map.max_x, map.max_y)

  map.grid = newGrid(map.heights, maxX, maxY, maxHeight)

  return map




proc get_height*(map: TileMap, tile: Vector2i): int =
  map.heights[tile2index(map.max_x, tile)]



proc change_height*(map: var TileMap, tile: Vector2i, height: int) =
  map.heights[tile2index(map.max_x, tile)] = height


proc get_vertex(map: TileMap, tile: Vector2i, index: int): Vector2 =
  tile2pos(map.vsize, tile) + map.vertices[index]



proc draw_tile(map: TileMap, tile: Vector2i) =
  drawPoly(tile2pos(map.vsize, tile), 6, map.vsize, 90, map.colors[map.get_height(tile)])
  

proc draw_map*(map: TileMap) =
  for y in 0..map.max_y:
    for x in 0..map.max_x:
      draw_tile(map, Vector2i(x: x, y: y))


proc tile2pos*(map: TileMap, tile: Vector2i): Vector2 =
  map.centerPos[tile2index(map.maxX, tile)]