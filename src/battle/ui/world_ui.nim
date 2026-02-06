import strutils
import raylib
import ui_settings, sides_ui, top_ui, in_ui
import ../world
import ../unit/unit

type
  UIMode* = enum
    uiPlayer, uiObs

type
  WorldUI* = object
    uiMode: UIMode
    uiSettings: UISettings
    sideUI: SideUI
    topUI: TopUI
    inUI: InUI



proc initWorldUI*(world: World, uiMode: UIMode): WorldUI =
  result.uiSettings = UISettings()
  let s = result.uiSettings
  result.sideUI = initSideUI(s, world.units)
  result.topUI = initTopUI(s)
  result.inUI = initInUI(s, world.units)
  result.uiMode = uiMode


proc update*(worldUI: var WorldUI, world: World, delta: float32) =
  worldUI.sideUI.update(world.units, delta)
  worldUI.inUI.update(world.units, delta)



proc draw*(self: WorldUI, world: World, camera: Camera2D) =
  let fontSize = self.uiSettings.sideFontSize.int32
  let padding = 15.float32

  case self.uiMode:
    of uiPlayer:
      self.inUI.drawPlayer(world, camera)
    of uiObs:
      self.inUI.drawObs(world, camera)


  self.sideUI.draw(world.units, fontSize, padding)

  self.topUI.draw(world.scoreSystem.scores[Team.Ally], world.scoreSystem.scores[Team.Enemy], world.heightSystem.states[Team.Ally].leftCd, world.heightSystem.states[Team.Enemy].leftCd)

  let
    leftSeconds = world.leftMatchTime.int
    m = leftSeconds div 60
    s = leftSeconds mod 60
    text = "$#:$#".format(m, s.intToStr(2))
  drawText(text, getScreenWidth() - 50, 5, 23, RayWhite)