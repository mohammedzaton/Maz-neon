class_name CoastSpeedFX
extends Node2D
var boost: float=0
var speed: float=0
var hit: float=0
var elapsed: float=0
var steering: CoastScreenSteering
var active: bool=false
func _process(delta: float) -> void:
 elapsed+=delta
 hit=maxf(0,hit-delta*2)
 queue_redraw()
func _draw() -> void:
 var size=get_viewport().get_visible_rect().size
 if hit>0:
  draw_rect(Rect2(Vector2.ZERO,size),Color(1,0.15,0.05,hit*0.25))
 if not active:
  return
 var center=size*Vector2(0.5,0.43)
 var intensity=clampf((speed-30)/60,0,0.7)+boost*0.5
 if intensity>0:
  for i in 30:
   var angle=float(i)*TAU/30+0.12
   var phase=fposmod(elapsed*(0.7+boost)+float(i)*0.317,1)
   var radius=lerpf(size.y*0.52,size.x*0.8,phase)
   var dir=Vector2(cos(angle),sin(angle))
   var start=center+dir*radius
   var end=start+dir*(25+boost*90)*phase
   draw_line(start,end,Color(0.72,0.95,1.0,intensity*phase*0.38),1.3+boost,true)
 if steering and steering.pointer_id>=0:
  var p=steering.finger
  draw_arc(steering.origin,32,0,TAU,32,Color(0.4,1,0.85,0.35),2,true)
  draw_line(steering.origin,p,Color(0.5,1,0.9,0.55),3,true)
  draw_circle(p,12,Color(0.55,1,0.9,0.32))
