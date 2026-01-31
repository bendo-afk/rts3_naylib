import tables
import raylib, raymath
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



proc initInUI*(s: UISettings, aUnits, eUnits: seq[Unit]): InUI =
  result.fontSize = s.inFontSize.int32
  let
    names = s.names
    fontSize = s.inFontSize.int32
    barSizeX = s.inBarX
    barRatio = s.inReloadRatio
    bgColor = s.barBg
    reloadColor = s.inReloadColor
    brightness = s.DiffBarBright
  for i, a in aUnits:
    result.unitsInUI[a.id] = initInUnitUI(
        a, names[i], fontSize, barSizeX, barRatio, bgColor, s.allyColor,
        reloadColor, s.allyColor.colorBrightness(brightness)
    )
  for i, e in eUnits:
    result.unitsInUI[e.id] = initInUnitUI(
        e, names[i], fontSize, barSizeX, barRatio, bgColor, s.enemyColor,
        reloadColor, s.enemyColor.colorBrightness(brightness)
    )
  for n in names:
    result.maxNameWidth = max(result.maxNameWidth, measureText(n, fontSize))
  
  result.unitSize = 10
  result.boxColor = Color(r: 0, g: 178, b: 255, a: 76)
  result.lineColor = Color(r: 0, g: 127, b: 255, a: 153)


proc update*(self: var InUI, aUnits, eUnits: seq[Unit], delta: float32) =
  for a in aUnits:
    self.unitsInUI[a.id].update(a.hp.hp.float32, a.attack.leftReloadTime.float32, delta)
  for e in eUnits:
    self.unitsInUI[e.id].update(e.hp.hp.float32, e.attack.leftReloadTime.float32, delta)



proc drawWorld*(world: World, camera: Camera2D, unitSize: int, boxColor, lineColor: Color) =
  mode2D(camera):
    world.map.draw_map()
    for a in world.aUnits:
      drawCircle(a.move.pos, unitSize.float32, Blue)
      drawLine(a.move.pos, a.move.pos + Vector2(x: 1000 * cos(a.attack.turretAngle), y: 1000 * sin(a.attack.turretAngle)), 2, RayWhite)
    
    for e in world.eUnits:
      if e.vision.visibleState == visVisible:
        drawCircle(e.move.pos, unitSize.float32, Red)
        drawLine(e.move.pos, e.move.pos + Vector2(x: 1000 * cos(e.attack.turretAngle), y: 1000 * sin(e.attack.turretAngle)), 2, RayWhite)
    
    if world.dragBox.dragging:
      drawRectangle(world.dragBox.rect, boxColor)
      drawRectangleLines(world.dragBox.rect, 2 / camera.zoom,lineColor)



proc toKey(pos: Vector2): Vector2 =
  return Vector2(x: pos.x.round, y: pos.y.round)


proc draw*(self: InUI, world: World, camera: Camera2D) =
  world.drawWorld(camera, self.unitSize, self.boxColor, self.lineColor)
  

  var groups: Table[Vector2, seq[int]]

  let allUnits = world.aUnits & world.eUnits

  for u in allUnits:
    if u in world.eUnits and u.vision.visibleState != visVisible:
      continue

    let key = u.move.pos.toKey()
    if not groups.hasKey(key):
      groups[key] = @[]
    groups[key].add(u.id)

  let stackOffset = self.fontSize.float32
  for key, ids in groups:
    for count, id in ids:
      var screenPos = key.getWorldToScreen2D(camera)
      screenPos.y -= stackOffset * (ids.len - count).float32 # + 20
      self.unitsInUI[id].draw(screenPos, self.fontSize, self.maxNameWidth)

