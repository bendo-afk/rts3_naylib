import sequtils
import raylib
import raymath
import astar

import control
import map/tilemap
import camera

import map/hex_math
import map/my_astar
import utils


const
  screenWidth = 900
  screenHeight = 800


var circlePos = Vector2(x: 100, y: 100)

var
  vsize = 100
  max_x, max_y = 19
  max_height = 4


proc main =
  initWindow(screenWidth, screenHeight, "raylib example - binary search tree")


  var map = newTileMap(vsize.float, max_x, max_y, max_height)

  let
    width = getScreenWidth()
    height = getScreenHeight()
  var camera = Camera2D(zoom: 0.1, target: Vector2(x: -100, y: -100), offset: Vector2(x: width.float32 / 2, y: height.float32 / 2))
  echo camera

  var paths: seq[Vector2i]

  while not windowShouldClose():
    dragCamera(camera)
    zoomCamera(camera)

    circlePos = tile2pos(map.vsize, Vector2i(x: 0, y: 0))


    let rightClickPos = onRightClicked()
    if rightClickPos[0]:
      let worldPos = rightClickPos[1].getScreenToWorld2D(camera)
      let
        start = pos2tile(map.vsize, circlePos)
        goal = pos2tile(map.vsize, worldPos)
      echo start, goal
      paths = path[Grid, Vector2i, float](map.grid, start, goal).toSeq()


    beginDrawing()
    clearBackground(Black)

    mode2D(camera):
      map.draw_map()
      drawCircle(circlePos, 10, RayWhite)

      let paths_vec2 = paths.mapIt(map.tile2pos(it))
      drawLineStrip(paths_vec2, Black)

    drawFPS(1, 1)
    endDrawing()


  closeWindow()

main()