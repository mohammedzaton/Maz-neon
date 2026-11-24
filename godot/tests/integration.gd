extends SceneTree
var game: Node3D
var failures: int = 0
func check(value: bool, message: String) -> void:
 if value:
  print("PASS: "+message)
 else:
  push_error("FAIL: "+message)
  failures += 1
func frames(count: int) -> void:
 for i in count:
  await physics_frame
func touch(index: int, action: String, down: bool) -> void:
 var b = game.hud.touch_buttons.filter(func(item):return item.action==action)[0]
 var event = InputEventScreenTouch.new()
 event.index = index
 event.position = b.get_global_transform_with_canvas()*Vector2(56,56)
 event.pressed = down
 root.push_input(event,true)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 game = load("res://main.tscn").instantiate()
 root.add_child(game)
 await frames(3)
 check(game.track.length>1000,"closed circuit has meaningful length")
 check(game.track.sample(0).distance_to(game.track.sample(game.track.length-0.01))<0.1,"circuit seam closes")
 check(game.rivals.size()==5,"five AI rivals are present")
 game.start_race()
 game.countdown = 0
 await frames(3)
 check(game.state=="race","countdown starts native race")
 var old_yaw = game.player.rotation.y
 var old_rival = game.rivals[0].progress
 touch(0,"steer_left",true)
 await frames(2)
 check(Input.is_action_pressed("steer_left"),"actual screen-touch event activates native left button")
 touch(1,"boost",true)
 await frames(2)
 check(Input.is_action_pressed("steer_left") and Input.is_action_pressed("boost"),"two simultaneous fingers hold steering and nitro")
 await frames(60)
 check(game.player.rotation.y>old_yaw+0.1,"touch steering changes vehicle heading in physics")
 check(game.player.nitro<95,"second finger consumes nitro")
 check(game.rivals[0].progress>old_rival+1,"AI rivals drive along the circuit")
 touch(0,"steer_left",false)
 touch(1,"boost",false)
 await frames(2)
 check(not Input.is_action_pressed("steer_left") and not Input.is_action_pressed("boost"),"finger release clears both actions")
 touch(2,"steer_right",true)
 await frames(2)
 check(Input.is_action_pressed("steer_right"),"right steering button receives touch")
 game.pause_race()
 var pos = game.player.global_position
 await frames(30)
 check(game.player.global_position.distance_to(pos)<0.01,"pause freezes player physics")
 check(not Input.is_action_pressed("steer_right"),"pause clears held input")
 game.resume_race()
 touch(2,"steer_right",false)
 await frames(2)
 game.player.spawn(14,0)
 game.player.previous_progress = game.track.length*0.99
 game.player.checkpoint = 1
 game.player.global_position = game.track.sample(2)
 await frames(2)
 check(game.player.lap==0,"crossing finish without checkpoints does not award lap")
 game.player.checkpoint = 4
 game.player.previous_progress = game.track.length*0.99
 game.player.global_position = game.track.sample(2)
 await frames(1)
 check(game.player.lap==1,"ordered checkpoints allow lap completion")
 game.player.rescue()
 check(game.player.global_position.distance_to(game.track.sample(game.player.progress))<7,"rescue returns car to road")
 game.player.lap = 3
 game.end_race()
 check(game.state=="results" and not game.player.running,"finish stops race and shows results")
 print("NATIVE_INTEGRATION_FAILURES="+str(failures))
 game.queue_free()
 await frames(1)
 quit(0 if failures==0 else 1)
