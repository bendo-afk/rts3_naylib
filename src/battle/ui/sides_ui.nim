import raylib
import ../unit/unit
import ui_settings, side_unit_ui, align_vertical, hp_bar

type
  SideUI* = object
    allySideUIs: seq[SideUnitUI]
    allyColWidths: seq[int32]
    enemySideUIs: seq[SideUnitUI]
    enemyColWidths: seq[int32]


proc initSideUI*(s: UISettings, aUnits, eUnits: seq[Unit]): SideUI =
  let fontSize = s.sideFontSize.int32
  
  var allyTexts: seq[seq[string]]
  for i in 0..<aUnits.len:
    allyTexts.add(@[s.names[i], $aUnits[i].attack.damage, $aUnits[i].move.speed, $aUnits[i].vision.height])
  result.allyColWidths = getColWidths(allyTexts, fontSize)
  
  var aPos = Vector2(x: s.sideSideMargin.float32, y: s.sideTopMargin)
  var barSize = Vector2(x: s.sideBarX, y: s.sideFontSize)
  for i, a in aUnits:
    let bar = initDiffHpBar(barSize, 0'f32, a.hp.maxHp.float32, s.barBg, s.allyColor, 1'f32, s.allyColor.colorBrightness(s.DiffBarBright))
    result.allySideUIs.add(initSideUnitUI(aPos, bar, allyTexts[i], fontSize))
    aPos.y += s.sideFontSize + 10

  var enemyTexts: seq[seq[string]]
  for i in 0..<eUnits.len:
    enemyTexts.add(@[s.names[i], $eUnits[i].attack.damage, $eUnits[i].move.speed, $eUnits[i].vision.height])
  result.enemyColWidths = getColWidths(enemyTexts, fontSize)

  var ePos = Vector2(x: getScreenWidth().float32 - s.sideSideMargin, y: s.sideTopMargin)
  barSize = Vector2(x: -s.sideBarX, y: s.sideFontSize)
  for i, e in eUnits:
    let bar = initDiffHpBar(barSize, 0'f32, e.hp.maxHp.float32, s.barBg, s.enemyColor, 1'f32, s.enemyColor.colorBrightness(s.DiffBarBright))
    result.enemySideUIs.add(initSideUnitUI(ePos, bar, enemyTexts[i], fontSize))
    ePos.y += s.sideFontSize + 10


proc update*(self: var SideUI, aUnits, eUnits: seq[Unit], delta: float32) =
  for i, a in aUnits:
    self.allySideUIs[i].bar.updateDiffHpBar(a.hp.hp.float32, delta)
  for i, e in eUnits:
    self.enemySideUIs[i].bar.updateDiffHpBar(e.hp.hp.float32, delta)


proc draw*(self: SIdeUI, aUnits, eUnits: seq[Unit], fontSize: int32, padding: float32) =
  for i, u in self.allySideUIs:
    let unit = aUnits[i]
    u.draw(self.allyColWidths, fontSize, padding, true, unit.attack.leftReloadTime, unit.attack.maxReloadTime)
  for i, u in self.enemySideUIs:
    let unit = eUnits[i]
    u.draw(self.enemyColWidths, fontSize, padding, false, unit.attack.leftReloadTime, unit.attack.maxReloadTime)