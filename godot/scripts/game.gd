extends Node3D

var track: CoastTrack
var player: CoastRacer
var rivals: Array[CoastRacer] = []
var hud: CoastHUD
var camera: Camera3D
var audio: CoastEngineAudio
var minimap: CoastMinimap
var state: String = "menu"
var countdown: float = 3.0
var elapsed: float = 0
var best_time: float = 0
var camera_mode: int = 0
var camera_roll: float = 0
var saved_assist: bool = true
var toast_time: float = 0
var camera_shake: float = 0
var screen_steering: CoastScreenSteering
var speed_fx: CoastSpeedFX
var menu_angle: float = 0
var lap_started: float = 0
var lap_times: Array[float] = []
const TOTAL_LAPS: int = 3
var web_race_control: JavaScriptObject

func _ready() -> void:
 setup_input()
 DisplayServer.screen_set_keep_on(true)
 track = CoastTrack.new()
 add_child(track)
 player = CoastRacer.new()
 add_child(player)
 player.build(track,Color("18c3b5"),true,"SPECTRAL GT RS")
 player.model.enable_player_fx()
 player.spawn(14,0)
 player.lap_completed.connect(on_lap)
 player.impact.connect(func():
  camera_shake=0.35
  player.model.emit_sparks()
  if speed_fx:
   speed_fx.hit=0.7
 )
 var colors = [Color("ee6b3b"),Color("e3be5d"),Color("436eae"),Color("9c6cba"),Color("e5e1d3")]
 for i in 5:
  var rival = CoastRacer.new()
  add_child(rival)
  rival.build(track,colors[i],false,["BLAZE RS","SOLAR R","BLUEFIN","DUSK GT","GHOST R"][i])
  rival.ai_skill = 0.76+i*0.025
  rival.ai_lane = -3.3 if i%2==0 else 3.3
  rival.max_speed = 61
  rivals.append(rival)
 camera = Camera3D.new()
 camera.fov = 63
 camera.far = 1000
 camera.near = 0.15
 add_child(camera)
 camera.current = true
 hud = CoastHUD.new()
 add_child(hud)
 screen_steering = CoastScreenSteering.new()
 screen_steering.hud = hud
 add_child(screen_steering)
 speed_fx = CoastSpeedFX.new()
 speed_fx.steering = screen_steering
 hud.add_child(speed_fx)
 hud.start_requested.connect(start_race)
 hud.pause_requested.connect(pause_race)
 hud.resume_requested.connect(resume_race)
 hud.home_requested.connect(show_home)
 hud.rescue_requested.connect(func():
  if state=="race":
   player.rescue()
   toast("BACK ON TRACK")
 )
 hud.camera_requested.connect(func(): camera_mode=(camera_mode+1)%3)
 hud.sound_requested.connect(func():
  audio.enabled = not audio.enabled
  toast("ENGINE AUDIO ON" if audio.enabled else "ENGINE AUDIO OFF")
 )
 hud.assist_changed.connect(func(value):
  saved_assist = value
  player.throttle_assist = value
 )
 minimap = CoastMinimap.new()
 minimap.position = Vector2(40,215)
 hud.add_child(minimap)
 for p in track.points:
  minimap.route.append(map_point(p))
 audio = CoastEngineAudio.new()
 add_child(audio)
 load_record()
 show_home()
 if OS.has_feature("web"):
  web_race_control = JavaScriptBridge.create_callback(on_web_race_control)
  var browser = JavaScriptBridge.get_interface("window")
  browser.coastRaceControl = web_race_control

func on_web_race_control(_arguments: Array) -> void:
 match state:
  "menu", "results":
   start_race()
  "race":
   pause_race()
  "pause":
   resume_race()

func setup_input() -> void:
 var bindings = {"steer_left":[KEY_LEFT,KEY_A],"steer_right":[KEY_RIGHT,KEY_D],"throttle":[KEY_UP,KEY_W],"brake":[KEY_DOWN,KEY_S],"drift":[KEY_SPACE],"boost":[KEY_SHIFT],"pause_race":[KEY_ESCAPE],"rescue":[KEY_R],"camera_view":[KEY_C]}
 for action in bindings:
  if not InputMap.has_action(action):
   InputMap.add_action(action)
  for code in bindings[action]:
   var event = InputEventKey.new()
   event.physical_keycode = code
   InputMap.action_add_event(action,event)

func clear_input() -> void:
 if screen_steering:
  screen_steering.reset()
 for action in ["steer_left","steer_right","throttle","brake","drift","boost"]:
  Input.action_release(action)

func set_running(value: bool) -> void:
 player.running = value
 if screen_steering:
  screen_steering.enabled=value
 if speed_fx:
  speed_fx.active=value
 for rival in rivals:
  rival.running = value
 audio.active = value
 if not value:
  for racer in [player]+rivals:
   racer.boosting=false
   racer.model.set_drift(false)
   for flame in racer.model.flames:
    flame.visible=false

func show_home() -> void:
 state = "menu"
 set_running(false)
 clear_input()
 hud.show_mode("menu")
 minimap.visible = false
 hud.best_label.text = "PERSONAL BEST   /   "+format_time(best_time) if best_time>0 else "FIRST SESSION   /   SET YOUR RECORD"
 player.spawn(14,0)
 for rival in rivals:
  rival.visible = false

func start_race() -> void:
 state = "countdown"
 elapsed = 0
 lap_started = 0
 lap_times.clear()
 countdown = 3.4
 set_running(false)
 player.spawn(14,-3.3)
 player.throttle_assist = saved_assist
 for i in rivals.size():
  rivals[i].visible = true
  rivals[i].spawn(22+(i/2)*8,3.3 if i%2==0 else -3.3)
 clear_input()
 hud.show_mode("countdown")
 minimap.visible = true
 camera.global_position = player.global_position+Vector3(0,4,10)
 update_hud()

func pause_race() -> void:
 if state!="race":
  return
 state = "pause"
 set_running(false)
 clear_input()
 hud.show_mode("pause")
 minimap.visible = false

func resume_race() -> void:
 if state!="pause":
  return
 clear_input()
 state = "race"
 set_running(true)
 hud.show_mode("race")
 minimap.visible = true

func on_lap(racer: CoastRacer) -> void:
 if racer!=player or state!="race":
  return
 lap_times.append(elapsed-lap_started)
 lap_started = elapsed
 if player.lap>=TOTAL_LAPS:
  end_race()
 else:
  toast("LAP %d COMPLETE / %s" % [player.lap,format_time(lap_times[-1])])

func end_race() -> void:
 var place = get_place()
 state = "results"
 set_running(false)
 clear_input()
 hud.show_mode("results")
 minimap.visible = false
 hud.result_title.text = "COAST CHAMPION." if place==1 else "FINISH LINE."
 hud.result_stats.text = "POSITION   %d / 6\nTOTAL TIME   %s\nDRIFT SCORE   %d" % [place,format_time(elapsed),int(player.drift_points)]
 if best_time==0 or elapsed<best_time:
  best_time = elapsed
  var file = FileAccess.open("user://coast_record.json",FileAccess.WRITE)
  if file:
   file.store_string(JSON.stringify({"best_time":best_time}))

func get_place() -> int:
 var place = 1
 for rival in rivals:
  if rival.race_distance>player.race_distance:
   place += 1
 return place

func format_time(seconds: float) -> String:
 return "%02d:%05.2f" % [int(seconds)/60,fmod(seconds,60)]

func map_point(p: Vector3) -> Vector2:
 return Vector2((p.x+320)*0.45,(p.z+270)*0.3)

func update_hud() -> void:
 hud.speed_label.text = "%03d" % int(player.speed*3.6)
 hud.lap_label.text = "LAP %d / %d" % [mini(player.lap+1,TOTAL_LAPS),TOTAL_LAPS]
 hud.position_label.text = "%d / 6" % get_place()
 hud.time_label.text = format_time(elapsed)
 hud.nitro_bar.value = player.nitro
 if player.is_drifting:
  hud.drift_label.text = "DRIFT  +%d  /  NITRO CHARGING" % int(player.drift_points)
 elif toast_time<=0:
  hud.drift_label.text = ""
 minimap.racers.clear()
 minimap.racers.append(map_point(player.global_position))
 for rival in rivals:
  minimap.racers.append(map_point(rival.global_position))
 minimap.queue_redraw()

func toast(message: String) -> void:
 if hud:
  hud.drift_label.text = message
  toast_time = 2.3

func _physics_process(delta: float) -> void:
 if player==null:
  return
 if state=="countdown":
  countdown -= delta
  hud.countdown_label.text = str(ceili(countdown)) if countdown>0 else "GO"
  if countdown<=0:
   state = "race"
   set_running(true)
   hud.show_mode("race")
 if state=="race":
  elapsed += delta
  update_hud()
 toast_time = maxf(0,toast_time-delta)
 if audio:
  audio.engine_speed = player.speed
 if speed_fx:
  speed_fx.speed=player.speed
  speed_fx.boost=lerpf(speed_fx.boost,1.0 if player.boosting else 0.0,delta*6)
 camera_shake = maxf(0,camera_shake-delta)
 update_camera(delta)

func update_camera(delta: float) -> void:
 if camera==null:
  return
 if state=="menu":
  menu_angle += delta*0.08
  var target = player.global_position+Vector3.UP*0.7
  camera.global_position = target+Vector3(7.2+sin(menu_angle)*1.2,2.6,7.5)
  var camera_right = (target-camera.global_position).normalized().cross(Vector3.UP)
  camera.look_at(target-camera_right*2.7,Vector3.UP)
  camera.fov=lerpf(camera.fov,52.0,delta*3)
  return
 var forward = -player.global_transform.basis.z
 var desired: Vector3
 var target: Vector3
 if camera_mode==0:
  desired = player.global_position-forward*8.0+Vector3.UP*3.5
  target = player.global_position+forward*8+Vector3.UP*0.8
 elif camera_mode==1:
  desired = player.global_position+forward*0.7+Vector3.UP*1.5
  target = player.global_position+forward*30+Vector3.UP*1.2
 else:
  desired = player.global_position+forward*0.15-player.global_transform.basis.x*0.33+Vector3.UP*1.12
  target = player.global_position+forward*30+Vector3.UP*1.13
 var smoothing = 1-exp(-delta*(8 if camera_mode==0 else 25))
 camera.global_position = camera.global_position.lerp(desired,smoothing)
 if camera_shake>0:
  camera.global_position += Vector3(randf_range(-0.1,0.1),randf_range(-0.07,0.07),0)
 if camera.global_position.distance_to(target)>0.1:
  camera.look_at(target,Vector3.UP)
 camera.fov = lerpf(camera.fov,80.0 if player.boosting else 64.0+player.speed*0.07,delta*4)
 camera_roll=lerpf(camera_roll,-player.steer*0.035,delta*5)
 camera.rotation.z=camera_roll

func load_record() -> void:
 if FileAccess.file_exists("user://coast_record.json"):
  var value = JSON.parse_string(FileAccess.get_file_as_string("user://coast_record.json"))
  if value is Dictionary and value.get("best_time",0) is float:
   var candidate = value.get("best_time",0.0)
   if is_finite(candidate) and candidate>0:
    best_time = candidate

func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("pause_race"):
  if state=="race":
   pause_race()
  elif state=="pause":
   resume_race()
 if event.is_action_pressed("rescue") and state=="race":
  player.rescue()
 if event.is_action_pressed("camera_view"):
  camera_mode = (camera_mode+1)%3

func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:
  pause_race()
  if state=="countdown":
   state = "pause"
   hud.show_mode("pause")
  clear_input()
 if what==NOTIFICATION_WM_GO_BACK_REQUEST:
  if state=="race":
   pause_race()
  elif state=="pause":
   resume_race()
