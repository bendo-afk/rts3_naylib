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
  
  # for a in world.aUnits:

  var pos = Vector2(x: result.uiSettings.sideSideMargin, y: result.uiSettings.sideTopMargin)
  var size = Vector2(x: result.uiSettings.sideBarX, y: result.uiSettings.sideFontSize)
  for a in world.aUnits:
    result.allySideBars.add(initDiffHpBar(pos, size, 0'f32, a.hp.maxHp.float32, result.uiSettings.barBg, result.uiSettings.allyColor, 1'f32, result.uiSettings.allyColor.colorBrightness(result.uiSettings.DiffBarBright)))
    pos.y += result.uiSettings.sideFontSize + 10

  pos = Vector2(x: getScreenWidth().float32 - result.uiSettings.sideSideMargin, y: result.uiSettings.sideTopMargin)
  pos.y += size.y
  size.x *= -1
  size.y *= -1
  for e in world.eUnits:
    result.enemySideBars.add(initDiffHpBar(pos, size, 0'f32, e.hp.maxHp.float32, result.uiSettings.barBg, result.uiSettings.enemyColor, 1'f32, result.uiSettings.enemyColor.colorBrightness(result.uiSettings.DiffBarBright)))
    pos.y += result.uiSettings.sideFontSize + 10


proc update*(worldUI: var WorldUI, world: World, delta: float32) =
  for i, a in world.aUnits:
    worldUI.allySideBars[i].updateDiffHpBar(a.hp.hp.float32, delta)
  for i, e in world.eUnits:
    worldUI.enemySideBars[i].updateDiffHpBar(e.hp.hp.float32, delta)


proc draw*(worldUI: WorldUI) =
  for side in [worldUI.allySideBars, worldUI.enemySideBars]:
    for b in side:
      b.drawHpBar()

