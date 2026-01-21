import raylib

import ../rules/match_rule as mr
import ../map/tilemap
import ../unit/unit


var matchRule: MatchRule

var map: TileMap
var aUnits: seq[Unit]
var eUnits: seq[Unit]

var
  vsize = 100
  max_x, max_y = 19
  max_height = 4


proc setupWorld*(pMatchRule: MatchRule) =
  matchRule = pMatchRule

  map = newTileMap(vsize.float, max_x, max_y, max_height)

  for i in matchRule.nUnit:
    aUnits.add(newUnit())

proc physics() =
  discard