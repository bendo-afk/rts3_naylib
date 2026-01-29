import raylib
import hp_bar, ui_settings
import ../world

type
  WorldUI* = object
    uiSettings: UISettings
    allySideBars: seq[DiffHpBar]
    enemySideBars: seq[DiffHpBar]


proc initWorldUI*(world: World): WorldUI =
  result.uiSettings = UISettings()
  
  var pos = Vector2(x: 10, y: result.uiSettings.sideTopMargin)
  var size = Vector2(x: result.uiSettings.sideBarX, y: result.uiSettings.sideFontSize)
  for a in world.aUnits:
    result.allySideBars.add(initDiffHpBar(pos, size, 0'f32, a.hp.maxHp.float32, result.uiSettings.barBg, result.uiSettings.allyColor, 1'f32, result.uiSettings.allyColor.colorBrightness(result.uiSettings.DiffBarBright)))
    pos.y += result.uiSettings.sideFontSize



proc update*(worldUI: var WorldUI, world: World, delta: float32) =
  for i, a in world.aUnits:
    worldUI.allySideBars[i].updateDiffHpBar(a.hp.hp.float32, delta)


proc draw*(worldUI: WorldUI) =
  for b in worldUI.allySideBars:
    b.drawHpBar()
