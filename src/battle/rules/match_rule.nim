import conversion
export conversion


type MapMode {.pure.} = enum
  Point, Line, Not

type ParamDef = object
  min, max: float
  steps: int
  tradeOff: bool

proc newParamDef(min, max: float, steps: int, tradeOff: bool): ParamDef =
  ParamDef(min: min, max: max, steps: steps, tradeOff: tradeOff)


type MatchRule* = object
  # units
  nUnit* = 7

  paramSteps* = 4
  hpDef* = newParamDef(9, 21, 4, true)
  damageDef* = newParamDef(2, 12, 4, true)
  speedDef* = newParamDef(1, 4, 4, true)
  heightDef* = newParamDef(0, 0, 1, false)

  speed2traverse* = newConversion(0, 1, 1)
  damage2reload* = newConversion(0, 1, 1)

  # map
  maxHeight* = 4
  maxX*, maxY* = 19
  mapMode* = MapMode.Point

  # system
  angleMargin* = 0.1
  diff2speed* = newConversion(1, -0.3, 1)

  lMargin* = 0
  sMargin* = 0

  heightCd* = 10
  heightActionTimer* = 1

  scoreInterval* = 9
  scoreKaisuu* = 3
  scoreBase* = 10
  dist2penalty* = newConversion(0, 2, -1)

  matchTime* = 60 * 3

