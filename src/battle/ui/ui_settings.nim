import raylib

type
  UISettings* = object
    scoreSize: float32
    scoreCdSize: float32

    barBg: Color
    DiffBarBright: float32

    sideTopMargin: float32
    sizeFontSize: float32
    sizeBarX: float32

    inFontSize: float32
    inBarX: float32
    inReloadRatio: float32
    inReloadColor: Color

    unitSize: float32
    allyColor: Color
    enemyColor: Color

    turretColor: Color
    turretWidth: float32

    pathColor: Color
    pathWidth: float32

    names: seq[string]