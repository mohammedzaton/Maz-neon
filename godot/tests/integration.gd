extends SceneTree
var game: Node3D
var failures: int=0
func check(value: bool,message: String) -> void:
 if value:
  print("PASS: "+message)
 else:
  push_error("FAIL: "+message)
  failures+=1
func frames(count: int) -> void:
 for i in count:
  await physics_frame
func screen_touch(index: int,at: Vector2,down: bool,cancel: bool=false) -> void:
 var e=InputEventScreenTouch.new()
 e.index=index
 e.position=at
 e.pressed=down
 e.canceled=cancel
 root.push_input(e,true)
func pedal(index: int,action: String,down: bool) -> void:
 var b=game.hud.touch_buttons.filter(func(item):return item.action==action)[0]
 screen_touch(index,b.get_global_transform_with_canvas()*Vector2(56,56),down)
func drag(index: int,at: Vector2) -> void:
 var e=InputEventScreenDrag.new()
 e.index=index
 e.position=at
 root.push_input(e,true)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 game=load("res://main.tscn").instantiate()
 root.add_child(game)
 await frames(3)
 check(game.player.model.detailed_asset_loaded,"detailed pinned CC0 vehicle is instantiated")
 check(game.player.model.paint!=null and game.player.model.wheels.size()==4,"paint finish and all four animated wheels are bound")
 check(game.track.length>1000,"closed circuit has meaningful length")
 check(game.track.sample(0).distance_to(game.track.sample(game.track.length-0.01))<0.1,"circuit seam closes")
 check(game.rivals.size()==5,"five AI rivals are present")
 game.start_race()
 game.countdown=0
 await frames(3)
 check(game.state=="race","countdown starts native race")
 var yaw=game.player.rotation.y
 var rival_progress=game.rivals[0].progress
 screen_touch(0,Vector2(340,430),true)
 await frames(2)
 check(Input.get_action_strength("steer_left")>0.8,"anywhere on left driving screen activates strong steering")
 pedal(1,"boost",true)
 await frames(2)
 check(Input.is_action_pressed("steer_left") and Input.is_action_pressed("boost"),"screen steering and a second nitro finger work together")
 await frames(40)
 check(game.player.rotation.y>yaw+0.1,"screen touch changes vehicle heading")
 check(game.player.nitro<95,"second finger consumes nitro")
 check(game.rivals[0].progress>rival_progress+1,"AI rivals drive along circuit")
 drag(0,Vector2(460,430))
 await frames(2)
 check(Input.is_action_pressed("steer_right") and not Input.is_action_pressed("steer_left"),"rightward drag reverses direction immediately")
 var strength=Input.get_action_strength("steer_right")
 drag(0,Vector2(375,430))
 await frames(2)
 check(Input.get_action_strength("steer_right")<strength,"drag distance controls analog steering strength")
 screen_touch(0,Vector2(375,430),false)
 await frames(2)
 check(not Input.is_action_pressed("steer_right") and Input.is_action_pressed("boost"),"releasing steering does not release the other finger's nitro")
 pedal(1,"boost",false)
 screen_touch(2,Vector2(800,430),true)
 await frames(2)
 check(Input.get_action_strength("steer_right")>0.8,"right half of driving view steers right")
 screen_touch(3,Vector2(300,430),true)
 screen_touch(3,Vector2(300,430),false)
 await frames(2)
 check(Input.is_action_pressed("steer_right"),"unrelated finger release cannot cancel steering")
 screen_touch(2,Vector2(800,430),false,true)
 await frames(2)
 check(game.screen_steering.pointer_id==-1 and not Input.is_action_pressed("steer_right"),"cancelled touch releases screen steering")
 pedal(4,"brake",true)
 await frames(2)
 check(game.screen_steering.pointer_id==-1 and Input.is_action_pressed("brake"),"pedal touch is not stolen by full-screen steering")
 pedal(4,"brake",false)
 screen_touch(5,Vector2(800,430),true)
 await frames(2)
 game.pause_race()
 var pos=game.player.global_position
 await frames(20)
 check(game.player.global_position.distance_to(pos)<0.01,"pause freezes player physics")
 check(game.screen_steering.pointer_id==-1 and not Input.is_action_pressed("steer_right"),"pause clears pointer ownership and all steering")
 game.resume_race()
 await frames(2)
 game.player.spawn(14,0)
 game.player.previous_progress=game.track.length*0.99
 game.player.checkpoint=1
 game.player.global_position=game.track.sample(2)
 await frames(2)
 check(game.player.lap==0,"finish crossing without checkpoints does not award lap")
 game.player.checkpoint=4
 game.player.previous_progress=game.track.length*0.99
 game.player.global_position=game.track.sample(2)
 await frames(1)
 check(game.player.lap==1,"ordered checkpoints allow lap completion")
 game.player.rescue()
 check(game.player.global_position.distance_to(game.track.sample(game.player.progress))<7,"rescue returns car to road")
 game.player.lap=3
 game.end_race()
 check(game.state=="results" and not game.player.running,"finish stops race and shows results")
 print("NATIVE_INTEGRATION_FAILURES="+str(failures))
 game.queue_free()
 await frames(2)
 quit(0 if failures==0 else 1)
