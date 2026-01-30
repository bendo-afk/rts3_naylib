import raylib
import hp_bar, ui_settings, align_vertical
import ../world

type
  WorldUI* = object
    uiSettings: UISettings

    allyColRights: seq[int32]
    allySideBars: seq[DiffHpBar]
    enemySideBars: seq[DiffHpBar]


proc initWorldUI*(world: World): WorldUI =
  result.uiSettings = UISettings()
  
  # damage speed height
  var texts: seq[seq[string]]
  texts.setLen(world.aUnits.len)
  for i, a in world.aUnits:
    texts[i] = @[result.uiSettings.names[i], $a.attack.damage, $a.move.speed, $a.vision.height]
  
  var padding = 20'i32
  var colRights = getColRights(texts, result.uiSettings.sideFontSize.int32, padding)
  for c in colRights.mitems:
    c += result.uiSettings.sideSideMargin.int32
  result.allyColRights = colRights

  var pos = Vector2(x: colRights[^1].float32 + padding.float32, y: result.uiSettings.sideTopMargin)
  var size = Vector2(x: result.uiSettings.sideBarX, y: result.uiSettings.sideFontSize)
  for a in world.aUnits:
    result.allySideBars.add(initDiffHpBar(
        pos, size, 0'f32, a.hp.maxHp.float32, result.uiSettings.barBg,
        result.uiSettings.allyColor, 1'f32,
        result.uiSettings.allyColor.colorBrightness(result.uiSettings.DiffBarBright))
    )
    pos.y += result.uiSettings.sideFontSize + 10

  pos = Vector2(x: getScreenWidth().float32 - pos.x, y: result.uiSettings.sideTopMargin)
  pos.y += size.y
  size.x *= -1
  size.y *= -1

  for e in world.eUnits:
    result.enemySideBars.add(initDiffHpBar(
        pos, size, 0'f32, e.hp.maxHp.float32, result.uiSettings.barBg,
        result.uiSettings.enemyColor, 1'f32,
        result.uiSettings.enemyColor.colorBrightness(result.uiSettings.DiffBarBright))
    )
    pos.y += result.uiSettings.sideFontSize + 10


proc update*(worldUI: var WorldUI, world: World, delta: float32) =
  for i, a in world.aUnits:
    worldUI.allySideBars[i].updateDiffHpBar(a.hp.hp.float32, delta)
  for i, e in world.eUnits:
    worldUI.enemySideBars[i].updateDiffHpBar(e.hp.hp.float32, delta)


proc draw*(worldUI: WorldUI, world: World) =
  let fontSize = worldUI.uiSettings.sideFontSize.int32
  for i, a in world.aUnits:
    let
      (name, p0, p1, p2) = (worldUI.uiSettings.names[i], $a.attack.damage, $a.move.speed, $a.vision.height)
      w0 = measureText(name, fontSize)
      w1 = measureText(p0, fontSize)
      w2 = measureText(p1, fontSize)
      w3 = measureText(p2, fontSize)
      bar = worldUI.allySideBars[i]
    drawText(name, worldUI.allyColRights[0] - w0, bar.pos.y.int32, fontSize, RayWhite)
    drawText(p0, worldUI.allyColRights[1] - w1, bar.pos.y.int32, fontSize, RayWhite)
    drawText(p1, worldUI.allyColRights[2] - w2, bar.pos.y.int32, fontSize, RayWhite)
    drawText(p2, worldUI.allyColRights[3] - w3, bar.pos.y.int32, fontSize, RayWhite)

  for side in [worldUI.allySideBars, worldUI.enemySideBars]:
    for b in side:
      b.drawHpBar()

