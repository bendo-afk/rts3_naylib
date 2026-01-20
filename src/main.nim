import raylib
import raymath

import tilemap
import camera


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

  while not windowShouldClose():
    dragCamera(camera)
    zoomCamera(camera)

    var offset: Vector2
    if isKeyDown(Right):
      offset = Vector2(x: 100, y: 0)
    if isKeyDown(Left):
      offset = Vector2(x: -100, y: 0)
    if isKeyDown(Down):
      offset = Vector2(x: 0, y: 100)
    if isKeyDown(Up):
      offset = Vector2(x: 0, y: -100) 
      

    circlePos = circlePos +  offset * getFrameTime() * 10


    beginDrawing()
    clearBackground(Black)

    mode2D(camera):
      map.draw_map()
      drawCircle(circlePos, 100, RayWhite)

    drawFPS(100, 100)
    endDrawing()


  closeWindow()

main()