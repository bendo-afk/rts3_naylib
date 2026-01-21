import raylib

proc onRightClicked*(): (bool, Vector2) =
  if isMouseButtonPressed(Right):
    return (true, getMousePosition())
  return (false, Vector2(x: 0, y: 0))