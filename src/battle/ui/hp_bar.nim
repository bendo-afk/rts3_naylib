import raylib

type
  ImmHpBar = object of RootObj
    pos: Vector2
    size: Vector2
    min, max: float32
    ratio: float32 = 1
    bgColor, fgColor: Color

  DiffHpBar = object of ImmHpBar
    timer: float32
    leftTimer: float32 = 0
    lastRatio: float32 = 1
    diffColor: Color

template assignArgs(pos, size, min, max, bgColor, fgColor) =
  result.pos = pos
  result.size = size
  result.min = min
  result.max = max
  result.bgColor = bgColor
  result.fgColor = fgColor

proc initImmHpBar*(pos, size: Vector2, min, max: float32, bgColor, fgColor: Color): ImmHpBar =
  assignArgs(pos, size, min, max, bgColor, fgColor)

proc initDiffHpBar*(pos, size: Vector2, min, max: float32, bgColor, fgColor: Color, timer: float32, diffColor: Color): DiffHpBar =
  assignArgs(pos, size, min, max, bgColor, fgColor)
  result.timer = timer
  result.diffColor = diffColor


proc updateDiffHpBar*(hpBar: var DiffHpBar, delta: float32) =
  hpBar.leftTimer = max(0, hpBar.leftTimer - delta)
  if hpBar.leftTimer == 0:
    hpBar.lastRatio = hpBar.ratio

proc setRatio*(hpBar: var ImmHpBar, value: float32) =
  hpBar.ratio = (value - hpBar.min) / (hpBar.max - hpBar.min)

proc setRatio*(hpBar: var DiffHpBar, value: float32) =
  hpBar.ratio = (value - hpBar.min) / (hpBar.max - hpBar.min)
  hpBar.leftTimer = hpBar.timer


proc drawBg(hpBar: ImmHpBar) =
  drawRectangle(hpBar.pos, hpBar.size, hpBar.bgColor)

proc drawFg(hpBar: ImmHpBar) =
  let leftSize = Vector2(x: hpBar.size.x * hpBar.ratio, y: hpBar.size.y)
  drawRectangle(hpBar.pos, leftSize, hpBar.fgColor)

proc drawHpBar*(hpBar: ImmHpBar) =
  drawBg(hpBar)
  drawFg(hpBar)

proc drawHpBar*(hpBar: DiffHpBar) =
  drawBg(hpBar)

  if hpBar.leftTimer > 0:
    let diffSize = Vector2(x: hpBar.size.x * hpBar.lastRatio, y: hpBar.size.y)
    drawRectangle(hpBar.pos, diffSize, hpBar.diffColor)

  drawFg(hpBar)

