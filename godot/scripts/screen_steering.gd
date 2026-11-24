class_name CoastScreenSteering
extends Node

# A finger can steer from the whole driving view. Pedals and toolbar keep their
# own fingers; lifting one finger never releases another finger's action.
var enabled: bool = false
var pointer_id: int = -1
var origin: Vector2
var finger: Vector2
var dragging: bool = false
var value: float = 0
var hud: CoastHUD
var deadzone: float = 10
var sensitivity: float = 0.10

func _input(event: InputEvent) -> void:
 if not enabled:
  return
 if event is InputEventScreenTouch:
  if not event.pressed or event.canceled:
   if event.index==pointer_id:
    reset()
   return
  if pointer_id!=-1 or is_reserved(event.position):
   return
  pointer_id=event.index
  origin=event.position
  finger=event.position
  dragging=false
  var width=get_viewport().get_visible_rect().size.x
  apply(-0.92 if origin.x<width*0.5 else 0.92)
 elif event is InputEventScreenDrag and event.index==pointer_id:
  finger=event.position
  var dx=finger.x-origin.x
  if absf(dx)>deadzone:
   dragging=true
  if dragging:
   var travel=get_viewport().get_visible_rect().size.x*sensitivity
   apply(clampf((absf(dx)-deadzone)/maxf(1,travel),0,1)*signf(dx))

func is_reserved(at: Vector2) -> bool:
 if at.y<115:
  return true
 if hud:
  for b in hud.touch_buttons:
   if b.visible:
    var local=b.get_global_transform_with_canvas().affine_inverse()*at
    if local.distance_to(Vector2(56,56))<66:
     return true
 return false

func apply(steering: float) -> void:
 value=steering
 Input.action_release("steer_left")
 Input.action_release("steer_right")
 if steering<0:
  Input.action_press("steer_left",-steering)
 elif steering>0:
  Input.action_press("steer_right",steering)

func reset() -> void:
 pointer_id=-1
 dragging=false
 value=0
 Input.action_release("steer_left")
 Input.action_release("steer_right")
