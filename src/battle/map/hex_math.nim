import math
import raylib
import ../../utils

export math, raylib, utils

const
  oddOffsets*: array[6, Vector2i] = [
    Vector2i(x: 1, y: -1),
    Vector2i(x: 1, y: 0),
    Vector2i(x: 1, y: 1),
    Vector2i(x: 0, y: 1),
    Vector2i(x: -1, y: 0),
    Vector2i(x: 0, y: -1)
  ]
  evenOffsets*: array[6, Vector2i] = [
    Vector2i(x: 0, y: -1),
    Vector2i(x: 1, y: 0),
    Vector2i(x: 0, y: 1),
    Vector2i(x: -1, y: 1),
    Vector2i(x: -1, y: 0),
    Vector2i(x: -1, y: -1)
  ]


proc getAdjacentTile*(tile: Vector2i, index: int): Vector2i =
  if (tile.y mod 2) == 1:
    return tile + oddOffsets[index]
  else:
    return tile + evenOffsets[index]


proc tile2pos*(vsize: float32, tile: Vector2i): Vector2 =
  var
    x: float32 = sqrt(float32(3)) * (float32(tile.x) + 0.5 * float32(tile.y and 1))
    y: float32 = 3 / 2 * float32(tile.y)
  x = x * vsize
  y = y * vsize
  return Vector2(x: x, y: y)


proc axialRound(x, y: float32): Vector2i =
  let
    xgrid = round(x)
    ygrid = round(y)
    a = x - xgrid
    b = y - ygrid
  if abs(a) >= abs(b):
    return Vector2i(x: int(xgrid + round(a + 0.5 * b)), y: int(ygrid))
  else:
    return Vector2i(x: int(xgrid), y: int(ygrid + round(b + 0.5 * a)))


proc axial2oddr(tile: Vector2i): Vector2i =
  let
    parity = tile.y and 1
    x = tile.x + (tile.y - parity) div 2
    y = tile.y
  return Vector2i(x: x, y: y)


proc pos2tile*(vsize: float32, pos: Vector2): Vector2i =
  let
    x = pos.x / vsize
    y = pos.y / vsize
    q: float32 = (sqrt(float32(3)) / 3 * x - 1 / 3 * y)
    r: float32 = 2 / 3 * y
  return axial2oddr(axialRound(q, r))


proc tile2index*(max_x: int, tile: Vector2i): int =
  tile.y * (max_x + 1) + tile.x


proc oddr2axial(tile: Vector2i): Vector2i =
  let
    parity = tile.y and 1
    q = tile.x - (tile.y - parity) div 2
    r = tile.y
  return Vector2i(x: q, y: r)


proc axial_dist(a, b: Vector2i): int =
  (abs(a.x - b.x) + abs(a.x + a.y - b.x - b.y) + abs(a.y - b.y)) div 2


proc calc_dist*(a, b: Vector2i): int  =
  let
    ac = oddr2axial(a)
    bc = oddr2axial(b)
  return axial_dist(ac, bc)


proc isExists*(maxX, maxY: int, tile: Vector2i): bool =
  return
    tile.y >= 0 and tile.y <= maxY and
    tile.x >= 0 and tile.x <= maxX


proc getHexVertices*(vsize: float32): array[6, Vector2] =
  let
    hsize: float32 = sqrt(3.0) / 2 * vsize
    half_vsize: float32 = vsize / 2
  result = [
    Vector2(x: 0, y: -vsize),
    Vector2(x: hsize, y: -half_vsize),
    Vector2(x: hsize, y: half_vsize),
    Vector2(x: 0, y: vsize),
    Vector2(x: -hsize, y: half_vsize),
    Vector2(x: -hsize, y: -half_vsize)
  ]