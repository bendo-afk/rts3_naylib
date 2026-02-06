import strformat
import raylib
import ui_settings

type
  TopUI* = object
    scoreSize: float32
    heightCdSize: float32
    scoreSpacing: float32
    cdSpacing: float32
    padding: float32


proc initTopUI*(s: UISettings): TopUI =
  result.scoreSize = s.scoreSize
  result.heightCdSize = s.heightCdSize
  result.scoreSpacing = s.scoreSize / 10
  result.cdSpacing = s.heightCdSize / 10
  result.padding = 10


proc draw*(self: TopUI, aScore, eScore: float, aCd, eCd: float) =
  let
    midX = getScreenWidth().float / 2
    topY = self.padding.float
    font = getFontDefault()

    aScoreStr = $aScore.int
    eScoreStr = $eScore.int
    aCdStr = fmt"{aCd:.1f}"
    eCdStr = fmt"{eCd:.1f}"
    aCdWidth = measureText(aCdStr, self.heightCdSize.int32)
    eScoreWidth = measureText(eScoreStr, self.scoreSize.int32)

  drawText(font, aScoreStr, 
    Vector2(x: midX - self.scoreSize * 3 + self.padding.float, y: topY), 
    Vector2(x: 0, y: 0),
    0, self.scoreSize.float, self.scoreSpacing, RayWhite)

  drawText(font, aCdStr, 
    Vector2(x: midX - self.scoreSize * 3 - self.padding.float, y: topY), 
    Vector2(x: aCdWidth.float32, y: 0),
    0, self.heightCdSize.float, self.cdSpacing, RayWhite)

  drawText(font, eScoreStr, 
    Vector2(x: midX + self.scoreSize * 3 - self.padding.float, y: topY), 
    Vector2(x: eScoreWidth.float, y: 0),
    0, self.scoreSize.float, self.scoreSpacing, RayWhite)

  drawText(font, eCdStr, 
    Vector2(x: midX + self.scoreSize * 3 + self.padding.float, y: topY), 
    Vector2(x: 0, y: 0),
    0, self.heightCdSize.float, self.cdSpacing, RayWhite)
  