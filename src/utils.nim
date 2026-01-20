import raylib

type Vector2i* = object
  x*, y*: int

# proc `+`*(a, b: Vector2i): Vector2i =
#   Vector2i(x: a.x + b.x, y: a.y + b.y)