import raylib
import ../unit/unit
import hp_bar

type
  InUnitUI* = object
    name: string
    nameWidth: int32
    hpBar: DiffHpBar
    reloadBar: ImmHpBar
    padding: float32 = 5


proc initInUnitUI*(unit: Unit, name: string, fontSize: int32, barSizeX, barRatio: float32, bgColor, hpColor, reloadColor, hpDiffColor: Color): InUnitUI =
  result.name = name
  result.nameWidth = measureText(name, fontSize)

  let
    hpBarSizeY = fontSize.float32 * barRatio
    reloadBarSizeY = fontSize.float32 - hpBarSizeY
  result.hpBar = initDiffHpBar(Vector2(x: barSizeX, y: hpBarSizeY), 0'f32,
      unit.hp.maxHp.float32, bgColor, hpColor, 1, hpDiffColor
  )
  result.reloadBar = initImmHpBar(Vector2(x: barSizeX, y: reloadBarSizeY), 0,
      unit.attack.maxReloadTime, bgColor, reloadColor
  )

  result.padding = 5


proc update*(self: var InUnitUI, hp, leftReload: float32, delta: float32) =
  self.hpBar.updateDiffHpBar(hp, delta)
  self.reloadBar.updateImmHpBar(self.reloadBar.max - leftReload)


proc draw*(self: InUnitUI, pos: Vector2, fontSize: int32, maxNameWidth: int32) =

  let
    barPosX = pos.x - self.reloadBar.size.x / 2
    textPosY = pos.y - fontSize.float32
  self.hpBar.drawHpBar(Vector2(x: barPosX, y: textPosY))
  self.reloadBar.drawHpBar(Vector2(x: barPosX, y: textPosY + self.hpBar.size.y))
 
  let
    textPosX = barPosX - self.padding - maxNameWidth.float32
  drawText(self.name, textPosX.int32, textPosY.int32, fontSize, RayWhite)
