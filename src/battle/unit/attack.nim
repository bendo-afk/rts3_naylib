import math
import raylib

import ../../utils

type AttackComp* = object
  damage*: int
  traverseSpeed*: float32
  angleMargin*: float32
  maxReloadTime*: float32
  leftReloadTime*: float32
  turretAngle*: float32
  targetPos*: Vector2

proc newAttackComp*(damage: int, traverseSpeed, angleMargin, maxReloadTime, leftReloadTime, turretAngle: float32): AttackComp =
  AttackComp(damage: damage, traverseSpeed: traverseSpeed, angleMargin: angleMargin, maxReloadTime: maxReloadTime, leftReloadTime: leftReloadTime, turretAngle: turretAngle)



proc rotateToward*(current, target, maxDelta: float32): float32 =
  var diff: float32 = (target - current) mod (2 * PI)
  if diff > PI: diff -= 2 * PI
  if diff < -PI: diff += 2 * PI
  
  if abs(diff) <= maxDelta:
    return target
  
  return current + sgn(diff).float32 * maxDelta


proc rotateTurret*(self: var AttackComp, relTargetPos: Vector2, delta: float32) =
  let toAngle: float32 = angle(relTargetPos)
  
  # traverseSpeed * PI * delta で回転量を計算
  let speed: float32 = self.traverseSpeed * PI * delta
  
  self.turretAngle = rotateToward(
    self.turretAngle, 
    toAngle, 
    speed
  )
