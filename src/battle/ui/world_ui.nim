import raylib
import ui_settings, sides_ui, top_ui, in_ui
import ../world

type
  WorldUI* = object
    uiSettings: UISettings
    sideUI: SideUI
    topUI: TopUI
    inUI: InUI



proc initWorldUI*(world: World): WorldUI =
  result.uiSettings = UISettings()
  let s = result.uiSettings
  result.sideUI = initSideUI(s, world.aUnits, world.eUnits)
  result.topUI = initTopUI(s)
  result.inUI = initInUI(s, world.aUnits, world.eUnits)


proc update*(worldUI: var WorldUI, world: World, delta: float32) =
  worldUI.sideUI.update(world.aUnits, world.eUnits, delta)
  worldUI.inUI.update(world.aUnits, world.eUnits, delta)



proc draw*(self: WorldUI, world: World, camera: Camera2D) =
  let fontSize = self.uiSettings.sideFontSize.int32
  let padding = 15.float32


  self.inUI.draw(world, camera)

  self.sideUI.draw(world.aUnits, world.eUnits, fontSize, padding)

  self.topUI.draw(world.scoreSystem.aScore, world.scoreSystem.eScore, world.heightSystem.states[0].leftCd, world.heightSystem.states[1].leftCd)

