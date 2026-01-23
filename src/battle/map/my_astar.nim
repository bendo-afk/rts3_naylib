import ../../utils
import hex_math
import ../rules/conversion

# vec2iで計算し、結果はtile2indexによってvec2を格納したseqからとってくる

var diff2speed: Conversion = newConversion(1, -0.3, 1)

type Grid* = object
  heights: ref seq[int]
  maxX, maxY, maxHeight: int


proc newGrid*(heights: ref seq[int], maxX, maxY, maxHeight: int): Grid =
  Grid(heights: heights, maxX: maxX, maxY: maxY, maxHeight: maxHeight)


proc isMovable(grid: Grid, t1, t2: Vector2i): bool =
  let heightDiff = grid.heights[tile2index(grid.maxX, t2)] - grid.heights[tile2index(grid.maxX, t1)]
  if heightDiff > 1:
    return false
  return true


iterator neighbors*(grid: Grid, tile: Vector2i): Vector2i =
  for i in 0..5:
    let nextTile = getAdjacentTile(tile, i)
    if isExists(grid.maxX, grid.maxY, nextTile) and isMovable(grid, tile, nextTile):
      yield nextTile


proc cost*(grid: Grid, a, b: Vector2i): float =
  let
    hA = grid.heights[tile2index(grid.maxX, a)]
    hB = grid.heights[tile2index(grid.maxX, b)]
    diff = hB - hA
    speed = diff2speed.calc(diff.float)
  return 1 / speed


proc heuristic*(grid: Grid, next, goal: Vector2i): float =
  let
    dist = calcDist(next, goal)
    maxSpeed = diff2speed.calc(-grid.maxHeight.float)
  return dist.float / maxSpeed

