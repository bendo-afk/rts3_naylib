import tables
import raylib, raymath
import ../../control
import ../map/tilemap
import ../unit/unit
import ../world
import ui_settings, in_unit_ui


type
  InUI* = object
    fontSize: int32
    unitsInUI: Table[int, InUnitUI]
    maxNameWidth: int32
    
    unitSize = 10
    boxColor = Color(r: 0, g: 178, b: 255, a: 76)
    lineColor = Color(r: 0, g: 127, b: 255, a: 153)


proc setupUnits(self: var InUI, s: UISettings, units: seq[Unit], team: Team) =
  let 
    barColor = if team == Team.Ally: s.allyColor else: s.enemyColor
    brightness = s.DiffBarBright
    hpColorDiff = barColor.colorBrightness(brightness)
  
  var idx = 0
  for u in units:
    if u.team != team: continue
    self.unitsInUI[u.id] = initInUnitUI(
      u, s.names[idx], self.fontSize, s.inBarX, s.inReloadRatio, 
      s.barBg, barColor, s.inReloadColor, hpColorDiff
    )
    inc idx


proc initInUI*(s: UISettings, units: seq[Unit]): InUI =
  result.fontSize = s.inFontSize.int32
  result.unitSize = 10
  result.boxColor = Color(r: 0, g: 178, b: 255, a: 76)
  result.lineColor = Color(r: 0, g: 127, b: 255, a: 153)
    
  result.setupUnits(s, units, Team.Ally)
  result.setupUnits(s, units, Team.Enemy)
  for n in s.names:
    result.maxNameWidth = max(result.maxNameWidth, measureText(n, result.fontSize))
  


proc update*(self: var InUI, units: seq[Unit], delta: float32) =
  for u in units:
    if u.isDead: continue
    self.unitsInUI[u.id].update(u.hp.hp.float32, u.attack.leftReloadTime.float32, delta)

    

proc drawUnits(units: seq[Unit], unitSize: float32) =
  for u in units:
    if u.isDead: continue
    let isEnemy = u.team == Team.Enemy
    if isEnemy and u.vision.visibleState != visVisible: continue
    
    let color = if isEnemy: Red else: Blue
    drawCircle(u.move.pos, unitSize.float32, color)
    let lineEnd = u.move.pos + Vector2(x: 1000 * cos(u.attack.turretAngle), y: 1000 * sin(u.attack.turretAngle))
    drawLine(u.move.pos, lineEnd, 2, RayWhite)


proc drawDragBox(dragBox: DragBox, camera: Camera2D, boxColor, lineColor: Color) =
  if dragBox.dragging:
    drawRectangle(dragBox.rect, boxColor)
    drawRectangleLines(dragBox.rect, 2 / camera.zoom,lineColor)


proc toKey(pos: Vector2): Vector2 =
  return Vector2(x: pos.x.round, y: pos.y.round)


proc draw*(self: InUI, world: World, camera: Camera2D) =
  mode2D(camera):
    world.map.draw_map()
    world.dragBox.drawDragBox(camera, self.boxColor, self.lineColor)
    drawUnits(world.units, self.unitSize)

  var groups: Table[Vector2, seq[int]]

  for u in world.units:
    if u. isDead: continue
    if u.team == Team.Enemy and u.vision.visibleState != visVisible:
      continue

    let key = u.move.pos.toKey()
    groups.mgetOrPut(key, @[]).add(u.id)

  let stackOffset = self.fontSize.float32
  for key, ids in groups:
    for count, id in ids:
      var screenPos = key.getWorldToScreen2D(camera)
      screenPos.y -= stackOffset * (ids.len - count).float32 # + 20
      self.unitsInUI[id].draw(screenPos, self.fontSize, self.maxNameWidth)

