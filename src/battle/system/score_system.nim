import sequtils
import ../rules/conversion
import ../../utils
import ../map/hex_math
import ../unit/unit

type EffectiveTile = object
  tile*: Vector2i
  leftTime*: float32
  leftCount*: int
  createdFrame: float32


type ScoreSystem* = object
  scoreInterval: float32
  scoreKaisuu: int
  basePoint: float32
  dist2pena: Conversion
  effTiles*: array[Team, seq[EffectiveTile]]
  scores*: array[Team, float32]


proc newScoreSystem*(scoreInterval: float32, scoreKaisuu: int, basePoint: float32, dist2pena: Conversion): ScoreSystem =
  ScoreSystem(scoreInterval: scoreInterval, scoreKaisuu: scoreKaisuu, basePoint: basePoint, dist2pena: dist2pena, scores: [0, 0])


proc calcScore(self: ScoreSystem, eTile: EffectiveTile, effTiles: seq[EffectiveTile]): float32 =
  var penalty: float32 = 0.0
  for t in effTiles:
    if eTile == t: continue
    let dist = calcDist(eTile.tile, t.tile)
    if dist == 0:
      return 0.0
    penalty += self.dist2pena.calc(dist.float32)

  return max(self.basePoint - penalty, 0.0)


proc onTileChanged*(self: var ScoreSystem, tile: Vector2i, team: Team, currentFrame: float32) =
  let eTile = EffectiveTile(
      tile: tile,
      leftTime: self.scoreInterval,
      leftCount: self.scoreKaisuu,
      createdFrame: currentFrame
  )
  if team == Team.Ally:
    self.effTiles[Team.Enemy].keepItIf(not (it.tile == tile and it.createdFrame != currentFrame))
    self.effTiles[Team.Ally].add(eTile)
  else:
    self.effTiles[Team.Ally].keepItIf(not (it.tile == tile and it.createdFrame != currentFrame))
    self.effTiles[Team.Enemy].add(eTile)


proc updateSide(self: var ScoreSystem, delta: float32) =
  for team in Team:
    template tiles: untyped = self.effTiles[team]
    for t in tiles.mitems:
      t.leftTime -= delta

      if t.leftTime <= 0:
        self.scores[team] += self.calcScore(t, tiles)
        t.leftTime = self.scoreInterval
        dec t.leftCount

    tiles.keepItIf(it.leftCount > 0)

# メインの更新処理
proc update*(self: var ScoreSystem, delta: float32) =
  self.updateSide(delta)