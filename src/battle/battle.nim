import raylib
import world
import ../camera
import ../control
import rules/match_rule

var vsize = 100

type Battle* = object
  world: World
  camera: Camera2D


proc newBattle*(width, height: float32): Battle =
  let camera = Camera2D(zoom: 1, target: Vector2(x: -100, y: -100), offset: Vector2(x: width / 2, y: height / 2))
  Battle(world: newWorld(MatchRule(), vsize.float), camera: camera)



proc handleInputs(battle: var Battle) =
  if isMouseButtonPressed(Right):
    let
      screenPos = getMousePosition()
      worldPos = screenPos.getScreenToWorld2D(battle.camera)
    battle.world.setPath(worldPos)


proc update*(battle: var Battle) =
  handleInputs(battle)
  battle.world.update()


proc draw*(battle: var Battle) =
  dragCamera(battle.camera)
  zoomCamera(battle.camera)

  beginDrawing()
  clearBackground(Black)
  battle.world.draw(battle.camera)
  drawFPS(1, 1)
  endDrawing()
  

