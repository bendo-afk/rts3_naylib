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
  if isAlly:
    # --- 味方: [Text0][Text1]... [HPBar] ---
    var currX = u.basePos.x
    for i in 0..<u.stats.len:
      # カラム内右寄せ (現在位置 + カラム幅 - 文字幅)
      let drawX = currX + colWidths[i].float32 - u.statsWidths[i].float32
      drawText(u.stats[i], drawX.int32, u.basePos.y.int32, fontSize, RayWhite)
      currX += colWidths[i].float32 + padding
    u.bar.drawHpBar(Vector2(x: currX, y: u.basePos.y))
    let hpValue = $u.bar.value.int
    let hpPosX = currX + (u.bar.size.x - measureText(hpValue, fontSize).float32) / 2
    drawText(hpValue, hpPosX.int32, u.basePos.y.int32, fontSize, RayWhite)

    let reloadText = fmt"{leftReload: .1f}" & "/" & fmt"{maxReload: .1f}"
    drawText(reloadText, (currX + u.bar.size.x + padding).int32, u.basePos.y.int32, fontSize, RayWhite)

  else:
    # テキストはバーの右側（padding分空ける）から開始
    var currX = u.basePos.x
    # 名前(stats[0])が一番右に来るように、statsを逆順にループ
    for i in 0..<u.stats.len:
      # 敵側はシンプルに左詰めで並べる
      let drawX = currX - u.statsWidths[i].float32
      drawText(u.stats[i], drawX.int32, u.basePos.y.int32, fontSize, RayWhite)
      currX -= colWidths[i].float32 + padding
    u.bar.drawHpBar(Vector2(x: currX, y: u.basePos.y))
    let hpValue = $u.bar.value.int
    let hpPosX = currX - (u.bar.size.x.abs + measureText(hpValue, fontSize).float32) / 2
    drawText(hpValue, hpPosX.int32, u.basePos.y.int32, fontSize, RayWhite)

    let reloadText = fmt"{leftReload: .1f}" & "/" & fmt"{maxReload: .1f}"
    drawText(reloadText, (currX + u.bar.size.x - padding - measureText(reloadText, fontSize).float32).int32, u.basePos.y.int32, fontSize, RayWhite)