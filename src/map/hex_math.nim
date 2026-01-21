import math
import raylib
import ../utils

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


proc tile2pos*(vsize: float, tile: Vector2i): Vector2 =
  var
    x = sqrt(float(3)) * (float(tile.x) + 0.5 * float(tile.y and 1))
    y = 3 / 2 * float(tile.y)
  x = x * vsize
  y = y * vsize
  return Vector2(x: x, y: y)


proc axialRound(x, y: var float): Vector2i =
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


proc pos2tile*(vsize: float, pos: Vector2): Vector2i =
  let
    x = pos.x / vsize
    y = pos.y / vsize
  var
    q = (sqrt(float(3)) / 3 * x - 1 / 3 * y)
    r = 2 / 3 * y
  return axial2oddr(axialRound(q, r))


proc tile2index*(max_x: int, tile: Vector2i): int =
  tile.y * (max_x + 1) + tile.x


proc oddr_to_axial(tile: Vector2i): Vector2i =
  let
    parity = tile.y and 1
    q = tile.x - (tile.y - parity) div 2
    r = tile.y
  return Vector2i(x: q, y: r)


proc axial_dist(a, b: Vector2i): int =
  (abs(a.x - b.x) + abs(a.x + a.y - b.x - b.y) + abs(a.y - b.y)) div 2


proc calc_dist*(a, b: Vector2i): int  =
  let
    ac = oddr_to_axial(a)
    bc = oddr_to_axial(b)
  return axial_dist(ac, bc)
