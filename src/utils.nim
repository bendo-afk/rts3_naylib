import math
import hashes
import raylib, raymath


type Vector2i* = object
  x*, y*: int

proc `+`*(a, b: Vector2i): Vector2i =
  Vector2i(x: a.x + b.x, y: a.y + b.y)


proc hash*(v: Vector2i): Hash =
  hash((v.x, v.y))

proc `==`*(a, b: Vector2i): bool =
  if a.x == b.x and a.y == b.y:
    return true
  else:
    return false


proc turn*(v0, v1, v2: Vector2): int =
  crossProduct(v1 - v0, v2 - v0).sgn()