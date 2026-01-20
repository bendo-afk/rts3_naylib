import raylib
import raymath

var zoomSpeed = 0.2

proc dragCamera*(camera: var Camera2D) =
  if isMouseButtonDown(Middle):
    let delta = getMouseDelta()
    camera.target = camera.target - delta / camera.zoom

proc zoomCamera*(camera: var Camera2D) =
  let
    mouseScreenPos = getMousePosition()
    mouseWorldPos = getScreenToWorld2D(mouseScreenPos, camera)
  camera.offset = mouseScreenPos
  camera.target = mouseWorldPos

  let wheel = getMouseWheelMove()
  if wheel != 0:
    camera.zoom = camera.zoom * (1 + wheel * zoomSpeed)
    if camera.zoom < 0.1:
      camera.zoom = 0.1
