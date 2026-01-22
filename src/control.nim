import raylib

proc onRightClicked*(): (bool, Vector2) =
  if isMouseButtonPressed(Right):
    return (true, getMousePosition())
  return (false, Vector2(x: 0, y: 0))


type DragBox* = object
  dragging*: bool
  dragStart*: Vector2
  dragEnd*: Vector2
  rect*: Rectangle

proc newDragBox*(): DragBox =
  DragBox(dragging: false)