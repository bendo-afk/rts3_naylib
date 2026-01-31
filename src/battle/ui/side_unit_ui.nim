import strformat
import raylib, raymath
import hp_bar

type
  SideUnitUI* = object
    basePos*: Vector2
    bar*: DiffHpBar
    stats*: seq[string]
    statsWidths: seq[int32]


proc initSideUnitUI*(pos: Vector2, bar: DiffHpBar, stats: seq[string], fontSize: int32): SideUnitUI =
  result = SideUnitUI(basePos: pos, bar: bar, stats: stats)
  for s in stats:
    result.statsWidths.add(measureText(s, fontSize))


proc draw*(u: SideUnitUI, colWidths: seq[int32], fontSize: int32, padding: float32, isAlly: bool, leftReload, maxReload: float) =
  let
    font = getFontDefault()
    spacing = (fontSize / 10).float32
  if isAlly:
    var currX = u.basePos.x
    for i in 0..<u.stats.len:
      let posX = currX + colWidths[i].float32
      drawText(font, u.stats[i], Vector2(x: posX, y: u.basePos.y), 
          Vector2(x: u.statsWidths[i].float32, y: 0),
          0.0, fontSize.float, spacing, RayWhite)
      currX += colWidths[i].float32 + padding

    u.bar.drawHpBar(Vector2(x: currX, y: u.basePos.y))
    let hpValue = $u.bar.value.int
    let hpWidth = measureText(hpValue, fontSize)
    let barMidX = currX + u.bar.size.x / 2
    drawText(font, hpValue, Vector2(x: barMidX, y: u.basePos.y),
        Vector2(x: hpWidth / 2, y: 0), 0.0, fontSize.float, spacing, RayWhite)

    let reloadText = fmt"{leftReload: .1f}" & "/" & fmt"{maxReload: .1f}"
    drawText(reloadText, (currX + u.bar.size.x + padding).int32, u.basePos.y.int32, fontSize, RayWhite)

  else:
    var currX = u.basePos.x
    for i in 0..<u.stats.len:
      drawText(font, u.stats[i], Vector2(x: currX, y: u.basePos.y),
          Vector2(x: u.statsWidths[i].float32, y: 0),
          0.0, fontSize.float, spacing, RayWhite)
      currX -= colWidths[i].float32 + padding

    u.bar.drawHpBar(Vector2(x: currX, y: u.basePos.y))
    let
      hpValue = $u.bar.value.int
      hpWidth = measureText(hpValue, fontSize)
      barMidX = currX + u.bar.size.x / 2
    drawText(font, hpValue, Vector2(x: barMidX, y: u.basePos.y),
        Vector2(x: hpWidth / 2, y: 0), 0.0, fontSize.float, spacing, RayWhite)

    let reloadText = fmt"{leftReload: .1f}" & "/" & fmt"{maxReload: .1f}"
    drawText(reloadText, (currX + u.bar.size.x - padding - measureText(reloadText, fontSize).float32).int32, u.basePos.y.int32, fontSize, RayWhite)