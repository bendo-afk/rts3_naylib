import strformat
import raylib
import ui_settings

type
  TopUI* = object
    scoreSize: float32
    heightCdSize: float32
    padding: float32


proc initTopUI*(s: UISettings): TopUI =
  result.scoreSize = s.scoreSize
  result.heightCdSize = s.heightCdSize
  result.padding = 10



# proc draw*(self: TopUI, aScore, eScore: float, aCd, eCd: float) =
#   let
#     aScoreText = $aScore
#     eScoreText = $eScore
#     aCdText = fmt"{aCd: .1f}"
#     eCdText = fmt"{eCd: .1f}"
#     aScoreWidth = measureText(aScoreText, self.scoreSize.int32)
#     eScoreWidth = measureText(eScoreText, self.scoreSize.int32)
#     aCdWidth = measureText(aCdText, self.heightCdSize.int32)
#     middlePosX = getScreenWidth() / 2
  
#   drawText(aScoreText, (middlePosX.int32 - self.padding.int32 - aScoreWidth), self.padding.int32, self.scoreSize.int32, RayWhite)
#   drawText(aCdText, (middlePosX.int32 - self.padding.int32 * 2 - aScoreWidth.int32 - aCdWidth), self.padding.int32, self.heightCdSize.int32, RayWhite)
#   drawText(eScoreText, (middlePosX.int32 + self.padding.int32), self.padding.int32, self.scoreSize.int32, RayWhite)
#   drawText(eCdText, (middlePosX.int32 + self.padding.int32 * 2 + eScoreWidth.int32), self.padding.int32, self.heightCdSize.int32, RayWhite)


proc draw*(self: TopUI, aScore, eScore: float, aCd, eCd: float) =
  let
    midX = getScreenWidth().float / 2
    topY = self.padding.float
    font = getFontDefault()
    spacing = 0'f32

    # 文字列変換
    aScoreStr = $aScore.int
    eScoreStr = $eScore.int
    aCdStr = fmt"{aCd:.1f}"
    eCdStr = fmt"{eCd:.1f}"
    aScoreWidth = measureText(aScoreStr, self.scoreSize.int32)
    aCdWidth = measureText(aCdStr, self.heightCdSize.int32)

  # --- 左側 (Ally): 右詰め ---
  # スコア: midXからpadding分左の位置に「右端」を合わせる
  drawText(font, aScoreStr, 
    Vector2(x: midX - self.padding.float, y: topY), 
    Vector2(x: aScoreWidth.float32, y: 0), # origin.x を幅分に設定 = 右詰め
    0, self.scoreSize.float, spacing, RayWhite)

  # CD: スコアのさらに左。位置を固定。
  drawText(font, aCdStr, 
    Vector2(x: midX - self.padding.float * 2 - self.scoreSize * 2, y: topY), 
    Vector2(x: aCdWidth.float32, y: 0), # origin.x を幅分に設定 = 右詰め
    0, self.heightCdSize.float, spacing, RayWhite)

  # --- 右側 (Enemy): 左詰め ---
  # スコア: midXからpadding分右の位置に「左端」を合わせる
  drawText(font, eScoreStr, 
    Vector2(x: midX + self.padding.float, y: topY), 
    Vector2(x: 0, y: 0), # origin.x を幅分に設定 = 右詰め
    0, self.scoreSize.float, spacing, RayWhite)

  # CD: スコアのさらに右。
  drawText(font, eCdStr, 
    Vector2(x: midX + self.padding.float * 2 + self.scoreSize * 2, y: topY), 
    Vector2(x: 0, y: 0), # origin.x を幅分に設定 = 右詰め
    0, self.heightCdSize.float, spacing, RayWhite)
  