class_name CoastMinimap
extends Node2D
var route: PackedVector2Array
var racers: Array[Vector2] = []
var visible_on_race: bool = true
func _draw() -> void:
 if route.size()<2:
  return
 draw_style_box(_panel(),Rect2(-8,-8,240,190))
 draw_polyline(route,Color(0.65,0.8,0.8,0.35),5,true)
 for i in racers.size():
  draw_circle(racers[i],5 if i==0 else 3.5,Color("72f2cf") if i==0 else Color("edb882"))
func _panel() -> StyleBoxFlat:
 var s = StyleBoxFlat.new()
 s.bg_color = Color(0.03,0.08,0.12,0.65)
 s.set_corner_radius_all(12)
 return s
