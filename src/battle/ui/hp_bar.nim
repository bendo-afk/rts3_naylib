import raylib

type
  ImmHpBar = object of RootObj
    pos: Vector2
    size: Vector2
    min, max, value: float32
    bgColor, fgColor: Color

  DiffHpBar = object of ImmHpBar
    timer: float32
    leftTimer: float32 = 0
    lastValue: float32
    diffColor: Color

template assignArgs(pos, size, min, max, bgColor, fgColor) =
  result.pos = pos
  result.size = size
  result.min = min
  result.max = max
  result.value = max
  result.bgColor = bgColor
  result.fgColor = fgColor

proc initImmHpBar*(pos, size: Vector2, min, max: float32, bgColor, fgColor: Color): ImmHpBar =
  assignArgs(pos, size, min, max, bgColor, fgColor)

proc initDiffHpBar*(pos, size: Vector2, min, max: float32, bgColor, fgColor: Color, timer: float32, diffColor: Color): DiffHpBar =
  assignArgs(pos, size, min, max, bgColor, fgColor)
  result.timer = timer
  result.lastValue = max
  result.diffColor = diffColor


proc updateDiffHpBar*(hpBar: var DiffHpBar, value: float32, delta: float32) =
  hpBar.leftTimer = max(0, hpBar.leftTimer - delta)
  
  if hpBar.value != value:
    hpBar.value = value
    hpBar.leftTimer = hpBar.timer

  if hpBar.leftTimer == 0:
    hpBar.lastValue = hpBar.value


proc drawBg(hpBar: ImmHpBar) =
  drawRectangle(hpBar.pos, hpBar.size, hpBar.bgColor)

proc drawFg(hpBar: ImmHpBar) =
  let leftSize = Vector2(x: hpBar.size.x * (hpBar.value - hpBar.min) / (hpBar.max - hpBar.min), y: hpBar.size.y)
  drawRectangle(hpBar.pos, leftSize, hpBar.fgColor)

proc drawHpBar*(hpBar: ImmHpBar) =
  drawBg(hpBar)
  drawFg(hpBar)

proc drawHpBar*(hpBar: DiffHpBar) =
  drawBg(hpBar)

  if hpBar.leftTimer > 0:
    let diffSize = Vector2(x: hpBar.size.x * (hpBar.lastValue - hpBar.min) / (hpBar.max - hpBar.min), y: hpBar.size.y)
    drawRectangle(hpBar.pos, diffSize, hpBar.diffColor)

  drawFg(hpBar)


when isMainModule:
  var
    value = 100.float32
    pos = Vector2(x: 10, y:100)
    size = Vector2(x: 300, y: 90)
    min = 0.float32
    max = 100.float32
    bg = Gray
    fg = SkyBlue
    timer = 1.float32
    diff = fg.colorBrightness(0.5)
  var hpBar = initDiffHpBar(pos, size, min, max, bg, fg, timer, diff)

  initWindow(900, 800, "raylib example - binary search tree")

  while not windowShouldClose():
    hpBar.updateDiffHpBar(value, getFrameTime())

    beginDrawing()
    hpBar.drawHpBar()
    endDrawing()

    if isKeyPressed(Space):
      value -= 10
  
  closeWindow()