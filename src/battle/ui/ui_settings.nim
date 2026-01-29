import raylib

type
  UISettings* = object
    scoreSize*: float32 = 40
    scoreCdSize*: float32 = 30

    barBg*: Color = DarkGray
    DiffBarBright*: float32 = 0.5

    sideTopMargin*: float32 = 100
    sideFontSize*: float32 = 20
    sideBarX*: float32 = 100

    inFontSize*: float32 = 30
    inBarX*: float32 = 100
    inReloadRatio*: float32 = 0.8
    inReloadColor*: Color = RayWhite

    unitSize*: float32 = 10
    allyColor*: Color = Blue
    enemyColor*: Color = Red

    turretColor*: Color = Lime
    turretWidth*: float32 = 2

    pathColor*: Color = RayWhite
    pathWidth*: float32 = 2

    names*: seq[string] = @[
        "A", "B", "C", "D", "E",
        "F", "G"
    ]