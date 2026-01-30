import raylib
import hp_bar, ui_settings, align_vertical, side_unit_ui
import ../world

type
  WorldUI* = object
    uiSettings: UISettings

    allySideUIs: seq[SideUnitUI]
    allyColWidths: seq[int32]
    enemySideUIs: seq[SideUnitUI]
    enemyColWidths: seq[int32]


proc initWorldUI*(world: World): WorldUI =
  result.uiSettings = UISettings()
  let s = result.uiSettings
  let fontSize = s.sideFontSize.int32
  
  # damage speed height
  var allyTexts: seq[seq[string]]
  for i in 0..<world.aUnits.len:
    allyTexts.add(@[s.names[i], $world.aUnits[i].attack.damage, $world.aUnits[i].move.speed, $world.aUnits[i].vision.height])
  result.allyColWidths = getColWidths(allyTexts, fontSize)

  var aPos = Vector2(x: s.sideSideMargin.float32, y: s.sideTopMargin)
  var barSize = Vector2(x: s.sideBarX, y: s.sideFontSize)
  for i, a in world.aUnits:
    let bar = initDiffHpBar(barSize, 0'f32, a.hp.maxHp.float32, s.barBg, s.allyColor, 1'f32, s.allyColor.colorBrightness(s.DiffBarBright))
    result.allySideUIs.add(initSideUnitUI(aPos, bar, allyTexts[i], fontSize))
    aPos.y += s.sideFontSize + 10

  var enemyTexts: seq[seq[string]]
  for i in 0..<world.eUnits.len:
    enemyTexts.add(@[s.names[i], $world.eUnits[i].attack.damage, $world.eUnits[i].move.speed, $world.eUnits[i].vision.height])
  result.enemyColWidths = getColWidths(enemyTexts, fontSize)

  var ePos = Vector2(x: getScreenWidth().float32 - s.sideSideMargin, y: s.sideTopMargin)
  barSize = Vector2(x: -s.sideBarX, y: s.sideFontSize)
  for i, e in world.eUnits:
    let bar = initDiffHpBar(barSize, 0'f32, e.hp.maxHp.float32, s.barBg, s.enemyColor, 1'f32, s.enemyColor.colorBrightness(s.DiffBarBright))
    result.enemySideUIs.add(initSideUnitUI(ePos, bar, enemyTexts[i], fontSize))
    ePos.y += s.sideFontSize + 10



proc update*(worldUI: var WorldUI, world: World, delta: float32) =
  for i, a in world.aUnits:
    worldUI.allySideUIs[i].bar.updateDiffHpBar(a.hp.hp.float32, delta)
  for i, e in world.eUnits:
    worldUI.enemySideUIs[i].bar.updateDiffHpBar(e.hp.hp.float32, delta)


proc draw*(worldUI: WorldUI, world: World) =
  let fontSize = worldUI.uiSettings.sideFontSize.int32
  let padding = 15.float32

  for i, u in worldUI.allySideUIs:
    let unit = world.aUnits[i]
    u.draw(worldUI.allyColWidths, fontSize, padding, true, unit.attack.leftReloadTime, unit.attack.maxReloadTime)
  for i, u in worldUI.enemySideUIs:
    let unit = world.eUnits[i]
    u.draw(worldUI.enemyColWidths, fontSize, padding, false, unit.attack.leftReloadTime, unit.attack.maxReloadTime)
