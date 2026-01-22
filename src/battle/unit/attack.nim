import math
import raylib

import ../../utils

type AttackComp* = object
  damage*: int
  traverseSpeed: float
  angleMargin*: float
  maxReloadTime*: float
  leftReloadTime*: float
  turretAngle*: float
  targetPos*: Vector2

proc newAttackComp*(damage: int, traverseSpeed, angleMargin, maxReloadTime, leftReloadTime, turretAngle: float): AttackComp =
  AttackComp(damage: damage, traverseSpeed: traverseSpeed, angleMargin: angleMargin, maxReloadTime: maxReloadTime, leftReloadTime: leftReloadTime, turretAngle: turretAngle)



proc rotateToward*(current, target, maxDelta: float): float =
  var diff = (target - current) mod (2 * PI)
  if diff > PI: diff -= 2 * PI
  if diff < -PI: diff += 2 * PI
  
  if abs(diff) <= maxDelta:
    return target
  
  return current + sgn(diff).float * maxDelta


proc rotateTurret*(self: var AttackComp, relTargetPos: Vector2, delta: float) =
  let toAngle = angle(relTargetPos)
  
  # traverseSpeed * PI * delta で回転量を計算
  let speed = self.traverseSpeed * PI * delta
  
  self.turretAngle = rotateToward(
    self.turretAngle, 
    toAngle, 
    speed
  )
