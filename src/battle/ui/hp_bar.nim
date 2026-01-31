import raylib

type
  ImmHpBar* = object of RootObj
    size*: Vector2
    min, max*, value*: float32
    bgColor, fgColor: Color

  DiffHpBar* = object of ImmHpBar
    timer: float32
    leftTimer: float32 = 0
    lastValue: float32
    diffColor: Color

template assignArgs(size, min, max, bgColor, fgColor) =
  result.size = size
  result.min = min
  result.max = max
  result.value = max
  result.bgColor = bgColor
  result.fgColor = fgColor

proc initImmHpBar*(size: Vector2, min, max: float32, bgColor, fgColor: Color): ImmHpBar =
  assignArgs(size, min, max, bgColor, fgColor)

proc initDiffHpBar*(size: Vector2, min, max: float32, bgColor, fgColor: Color, timer: float32, diffColor: Color): DiffHpBar =
  assignArgs(size, min, max, bgColor, fgColor)
  result.timer = timer
  result.lastValue = max
  result.diffColor = diffColor


proc updateImmHpBar*(bar: var ImmHpBar, value: float32) =
  bar.value = value

proc updateDiffHpBar*(hpBar: var DiffHpBar, value: float32, delta: float32) =
  hpBar.leftTimer = max(0, hpBar.leftTimer - delta)
  
  if hpBar.value != value:
    hpBar.value = value
    hpBar.leftTimer = hpBar.timer

  if hpBar.leftTimer == 0:
    hpBar.lastValue = hpBar.value


proc drawRectangleRev(pos, size: Vector2, color: Color) =
  var
    actualPos = pos
    actualSize = size
  if size.x < 0:
    actualSize.x = size.x.abs
    actualPos.x += size.x
  drawRectangle(actualPos, actualSize, color)
    

proc drawBg(hpBar: ImmHpBar, pos: Vector2) =
  drawRectangleRev(pos, hpBar.size, hpBar.bgColor)

proc drawFg(hpBar: ImmHpBar, pos: Vector2) =
  let leftSize = Vector2(x: hpBar.size.x * (hpBar.value - hpBar.min) / (hpBar.max - hpBar.min), y: hpBar.size.y)
  drawRectangleRev(pos, leftSize, hpBar.fgColor)

proc drawHpBar*(hpBar: ImmHpBar, pos: Vector2) =
  drawBg(hpBar, pos)
  drawFg(hpBar, pos)

proc drawHpBar*(hpBar: DiffHpBar, pos: Vector2) =
  drawBg(hpBar, pos)

  if hpBar.leftTimer > 0:
    let diffSize = Vector2(x: hpBar.size.x * (hpBar.lastValue - hpBar.min) / (hpBar.max - hpBar.min), y: hpBar.size.y)
    drawRectangleRev(pos, diffSize, hpBar.diffColor)

  drawFg(hpBar, pos)


when isMainModule:
  var
    value = 100.float32
    pos = Vector2(x: 10, y:100)
    size = Vector2(x: -300, y: 90)
    min = 0.float32
    max = 100.float32
    bg = Gray
    fg = SkyBlue
    timer = 1.float32
    diff = fg.colorBrightness(0.5)
  var hpBar = initDiffHpBar(size, min, max, bg, fg, timer, diff)

  initWindow(900, 800, "raylib example - binary search tree")

  while not windowShouldClose():
    hpBar.updateDiffHpBar(value, getFrameTime())

    beginDrawing()
    hpBar.drawHpBar(pos)

    drawRectangle(pos, Vector2(x: -300, y: -90), RayWhite)

    endDrawing()

    if isKeyPressed(Space):
      value -= 10
  
  closeWindow()