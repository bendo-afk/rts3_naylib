import sequtils
import ../rules/conversion
import ../../utils
import ../map/hex_math

type EffectiveTile = object
  tile: Vector2i
  leftTime: float
  leftCount: int
  createdFrame: int


type ScoreSystem* = object
  scoreInterval: float
  scoreKaisuu: int
  basePoint: float
  dist2pena: Conversion
  allyTiles, enemyTiles: seq[EffectiveTile]
  aScore*, eScore*: float


proc calcScore(self: ScoreSystem, eTile: EffectiveTile, isAlly: bool): float =
  var penalty = 0.0
  let effTiles = if isAlly: self.allyTiles else: self.enemyTiles
  for t in effTiles:
    if eTile == t: continue
    let dist = calcDist(eTile.tile, t.tile)
    if dist == 0:
      return 0.0
    penalty += self.dist2pena.calc(dist.float)

  return max(self.basePoint - penalty, 0.0)


proc onTileChanged*(self: var ScoreSystem, tile: Vector2i, isAlly: bool, currentFrame: int) =
  let eTile = EffectiveTile(
      tile: tile,
      leftTime: self.scoreInterval,
      leftCount: self.scoreKaisuu,
      createdFrame: currentFrame
  )
  if isAlly:
    self.enemyTiles.keepItIf(not (it.tile == tile and it.createdFrame != currentFrame))
    self.allyTiles.add(eTile)
  else:
    self.allyTiles.keepItIf(not (it.tile == tile and it.createdFrame != currentFrame))
    self.enemyTiles.add(eTile)
  

proc updateSide(self: var ScoreSystem, isAlly: bool, delta: float) =
  var tiles = if isAlly: self.allyTiles else: self.enemyTiles
  
  var i = tiles.len
  while i > 0:
    tiles[i].leftTime -= delta
    
    if tiles[i].leftTime <= 0:
      let s = self.calcScore(tiles[i], isAlly)
      if isAlly: self.aScore += s else: self.eScore += s
      
      tiles[i].leftCount -= 1
      if tiles[i].leftCount <= 0:
        tiles.delete(i)
      else:
        tiles[i].leftTime = self.scoreInterval
    dec i


# メインの更新処理
proc update*(self: var ScoreSystem, delta: float) =
  self.updateSide(true, delta)
  self.updateSide(false, delta)