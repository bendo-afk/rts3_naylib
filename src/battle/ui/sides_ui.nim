import raylib
import ../unit/unit
import ui_settings, side_unit_ui, align_vertical, hp_bar

type
  SideUI* = object
    allySideUIs: seq[SideUnitUI]
    allyColWidths: seq[int32]
    enemySideUIs: seq[SideUnitUI]
    enemyColWidths: seq[int32]


proc getUnitTexts(s: UISettings, units: seq[Unit], team: Team): seq[seq[string]] =
  var idx = 0
  for u in units:
    if u.team != team: continue
    result.add(@[s.names[idx], $u.attack.damage, $u.move.speed, $u.vision.height])
    inc idx


proc createSideUIs(s: UISettings, units: seq[Unit], team: Team, texts: seq[seq[string]]): seq[SideUnitUI] =
  let fontSize = s.sideFontSize.int32
  let isAlly = team == Team.Ally
  
  let startX = if isAlly: s.sideSideMargin.float32 
      else: getScreenWidth().float32 - s.sideSideMargin
  let barWidth = if isAlly: s.sideBarX else: -s.sideBarX
  let barColor = if isAlly: s.allyColor else: s.enemyColor
  
  var pos = Vector2(x: startX, y: s.sideTopMargin)
  let barSize = Vector2(x: barWidth, y: s.sideFontSize)
  
  var textIdx = 0
  for u in units:
    if u.team != team: continue
    
    let bar = initDiffHpBar(barSize, 0'f32, u.hp.maxHp.float32, s.barBg, barColor, 1'f32, barColor.colorBrightness(s.DiffBarBright))
    result.add(initSideUnitUI(pos, bar, texts[textIdx], fontSize))
    
    pos.y += s.sideFontSize + 10
    inc textIdx


proc initSideUI*(s: UISettings, units: seq[Unit]): SideUI =
  let fontSize = s.sideFontSize.int32
  
  var allyTexts = getUnitTexts(s, units, Team.Ally)
  result.allyColWidths = getColWidths(allyTexts, fontSize)
  result.allySideUIs = createSideUIs(s, units, Team.Ally, allyTexts)

  var enemyTexts = getUnitTexts(s, units, Team.Enemy)
  result.enemyColWidths = getColWidths(enemyTexts, fontSize)
  result.enemySideUIs = createSideUIs(s, units, Team.Enemy, enemyTexts)


proc update*(self: var SideUI, units: seq[Unit], delta: float32) =
  var
    aIdx = 0
    eIdx = 0
  for u in units:
    if u.team == Team.Ally:
      self.allySideUIs[aIdx].bar.updateDiffHpBar(u.hp.hp.float32, delta)
      inc aIdx
    else:
      self.enemySideUIs[eIdx].bar.updateDiffHpBar(u.hp.hp.float32, delta)
      inc eIdx


proc draw*(self: SIdeUI, units: seq[Unit], fontSize: int32, padding: float32) =
  var
    aIdx = 0
    eIdx = 0
  for u in units:
    if u.team == Team.Ally:
      self.allySideUIs[aIdx].draw(self.allyColWidths, fontSize, padding, true, u.attack.leftReloadTime, u.attack.maxReloadTime)
      inc aIdx
    else:
      self.enemySideUIs[eIdx].draw(self.enemyColWidths, fontSize, padding, false, u.attack.leftReloadTime, u.attack.maxReloadTime)
      inc eIdx