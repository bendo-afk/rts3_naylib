import raylib
import raymath

import battle/battle


const
  screenWidth = 900
  screenHeight = 800


type Scene {.pure.} = enum
  Battle


var circlePos: Vector2




proc main =
  initWindow(screenWidth, screenHeight, "raylib example - binary search tree")

  let
    width = getScreenWidth()
    height = getScreenHeight()

  var scene = Scene.Battle

  var battle = newBattle(width.float32, height.float32)

  while not windowShouldClose():

    case scene
    of Scene.Battle:
      battle.update()
      battle.draw()
    



  closeWindow()

main()

# todo
# マップ外をクリックしたときにクラッシュする