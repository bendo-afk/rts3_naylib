import raylib
import raymath
import utils
import std/math
import std/algorithm
import perlin


var
  frequency = 0.2
  octaves = 3
  persistence = 0.5

const MIN_GREEN = Color(r: 0, g: 60, b: 0, a: 255)
const MAX_GREEN = Color(r: 0, g: 255, b: 0, a: 255)


type TileMap* = object
  vsize: float
  max_x, max_y: int
  max_height: int
  vertices: array[6, Vector2]
  all_verts: seq[array[6, Vector2]]
  colors: seq[Color]

  heights: seq[int]



proc tile2index(map: TileMap, tile: Vector2i): int =
  tile.y * (map.max_x + 1) + tile.x


proc generateMap(map: var TileMap) =
  map.heights = newSeq[int]((map.max_x + 1) * (map.max_y + 1))
  for y in 0..map.max_x:
    for x in 0..map.max_y:
      var noise = newNoise(octaves, persistence)
      let value = noise.simplex(x.float * frequency, y.float * frequency)
      map.heights[map.tile2index(Vector2i(x: x, y: y))] = int(map.max_height.float * value)



proc tile2pos*(map: TileMap, tile: Vector2i): Vector2 =
  var
    x = sqrt(float(3)) * (float(tile.x) + 0.5 * float(tile.y and 1))
    y = 3 / 2 * float(tile.y)
  x = x * map.vsize
  y = y * map.vsize
  return Vector2(x: x, y: y)


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

  for y in 0..max_y:
    for x in 0..max_x:
      let center = tile2pos(map, Vector2i(x: x , y: y))
      var verts: array[6, Vector2]
      for i in 0..5:
        verts[i] = center + map.vertices[i]
      map.all_verts.add(verts)

  # map.heights = newSeq[int]((max_x + 1) * (max_y + 1))
  # map.heights.fill(1)
  generateMap(map)

  for i in 0..max_height:
    map.colors.add(colorLerp(MIN_GREEN, MAX_GREEN, i / max_height))

  return map




proc get_height*(map: TileMap, tile: Vector2i): int =
  map.heights[map.tile2index(tile)]



proc change_height*(map: var TileMap, tile: Vector2i, height: int) =
  map.heights[map.tile2index(tile)] = height


proc axial_round(x, y: var float): Vector2i =
  let
    xgrid = round(x)
    ygrid = round(y)
  x -= xgrid
  y -= ygrid
  if abs(x) >= abs(y):
    return Vector2i(x: int(xgrid + round(x + 0.5 * y)), y: int(ygrid))
  else:
    return Vector2i(x: int(xgrid), y: int(ygrid + round(y + 0.5 * x)))


proc axial2oddr(tile: Vector2i): Vector2i =
  let
    parity = tile.y and 1
    x = tile.x + (tile.y - parity) div 2
    y = tile.y
  return Vector2i(x: x, y: y)


proc pos2tile*(map: TileMap, pos: Vector2): Vector2i =
  let
    x = pos.x / map.vsize
    y = pos.y / map.vsize
  var
    q = (sqrt(float(3)) / 3 * x - 1 / 3 * y)
    r = 2 / 3 * y
  return axial2oddr(axial_round(q, r))



proc get_vertex(map: TileMap, tile: Vector2i, index: int): Vector2 =
  tile2pos(map, tile) + map.vertices[index]



proc draw_tile(map: TileMap, tile: Vector2i) =
  drawPoly(map.tile2pos(tile), 6, map.vsize, 90, map.colors[map.get_height(tile)])
  
  # drawPoly(map.tile2pos(tile), 6, map.vsize, 90, Color(r: 0, g: 200, b: 0, a: 1))
  


proc draw_map*(map: TileMap) =
  for y in 0..map.max_y:
    for x in 0..map.max_x:
      draw_tile(map, Vector2i(x: x, y: y))