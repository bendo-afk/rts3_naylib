import world
import control
import ../rules/match_rule

proc setupBattle*() =
  setupWorld(MatchRule())