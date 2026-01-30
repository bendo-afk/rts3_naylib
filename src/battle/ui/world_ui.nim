import raylib
import ui_settings, sides_ui, top_ui
import ../world

type
  WorldUI* = object
    uiSettings: UISettings
    sideUI: SideUI
    topUI: TopUI



proc initWorldUI*(world: World): WorldUI =
  result.uiSettings = UISettings()
  let s = result.uiSettings
  result.sideUI = initSideUI(s, world.aUnits, world.eUnits)
  result.topUI = initTopUI(s)


proc update*(worldUI: var WorldUI, world: World, delta: float32) =
  worldUI.sideUI.update(world.aUnits, world.eUnits, delta)


proc draw*(worldUI: WorldUI, world: World) =
  let fontSize = worldUI.uiSettings.sideFontSize.int32
  let padding = 15.float32
  worldUI.sideUI.draw(world.aUnits, world.eUnits, fontSize, padding)

  worldUI.topUI.draw(world.scoreSystem.aScore, world.scoreSystem.eScore, world.heightSystem.states[0].leftCd, world.heightSystem.states[1].leftCd)


