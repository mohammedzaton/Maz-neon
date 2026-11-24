class_name CoastRacer
extends CharacterBody3D

var track: CoastTrack
var model: CoastCarModel
var is_player: bool = false
var running: bool = false
var car_name: String = "APEX GT"
var speed: float = 0
var nitro: float = 100
var steer: float = 0
var drift_points: float = 0
var boosting: bool = false
var lap: int = 0
var checkpoint: int = 1
var progress: float = 0
var previous_progress: float = 0
var race_distance: float = 0
var ai_skill: float = 0.8
var ai_lane: float = 0
var max_speed: float = 62
var is_drifting: bool = false
var collision_cooldown: float = 0
var throttle_assist: bool = true
var trail_timer: float = 0
var reset_timer: float = 0
var hits: int = 0
signal lap_completed(racer: CoastRacer)
signal impact()

func build(owner_track: CoastTrack, color: Color, player: bool, title: String) -> void:
 track = owner_track
 is_player = player
 car_name = title
 model = CoastCarModel.new()
 add_child(model)
 model.build(color)
 var shape = CollisionShape3D.new()
 var box = BoxShape3D.new()
 box.size = Vector3(2.0,1.2,4.5)
 shape.shape = box
 shape.position.y = 0.62
 add_child(shape)
 floor_snap_length = 0.4
 floor_max_angle = 0.8

func spawn(at: float, lane: float) -> void:
 global_position = track.sample(at)+track.right(at)*lane+Vector3.UP*0.05
 var dir = track.direction(at)
 rotation.y = atan2(-dir.x,-dir.z)
 velocity = Vector3.ZERO
 speed = 0
 nitro = 100
 steer = 0
 progress = at
 previous_progress = at
 lap = 0
 checkpoint = 1
 race_distance = at
 collision_cooldown = 0
 drift_points = 0
 reset_timer = 0
 hits = 0

func rescue() -> void:
 var at = maxf(0,progress-5)
 global_position = track.sample(at)+Vector3.UP*0.2
 var dir = track.direction(at)
 rotation.y = atan2(-dir.x,-dir.z)
 speed = 0
 velocity = Vector3.ZERO
 collision_cooldown = 1

func _physics_process(delta: float) -> void:
 if not running or track == null:
  return
 collision_cooldown = maxf(0,collision_cooldown-delta)
 var forward = -global_transform.basis.z
 var desired_steer: float = 0
 var throttle: float = 1
 var braking: bool = false
 var handbrake: bool = false
 if is_player:
  desired_steer = Input.get_axis("steer_left","steer_right")
  throttle = 1.0 if throttle_assist or Input.is_action_pressed("throttle") else 0.0
  braking = Input.is_action_pressed("brake")
  handbrake = Input.is_action_pressed("drift") and speed>13
  boosting = Input.is_action_pressed("boost") and nitro>2 and not braking
 else:
  var lookahead = 12+speed*0.45
  var target = track.sample(progress+lookahead)+track.right(progress+lookahead)*ai_lane
  var dir = (target-global_position).normalized()
  var angle = forward.signed_angle_to(dir,Vector3.UP)
  desired_steer = clampf(-angle*2.3,-1,1)
  var next_dir = track.direction(progress+45)
  var curve_amount = absf(forward.signed_angle_to(next_dir,Vector3.UP))
  throttle = clampf(1-curve_amount*0.65,0.45,1)
  braking = curve_amount>0.85 and speed>33
  boosting = false
 steer = move_toward(steer,desired_steer,delta*11.0)
 var center = track.sample(progress)
 var offroad = Vector2(global_position.x-center.x,global_position.z-center.z).length()>9.2
 var limit = max_speed if is_player else max_speed*ai_skill
 if offroad:
  limit = 17
 var acceleration = 24.0 if is_player else 18.0
 if boosting:
  limit += 17
  acceleration += 16
  nitro = maxf(0,nitro-26*delta)
 else:
  nitro = minf(100,nitro+(4+absf(steer)*2)*delta)
 if braking:
  speed = move_toward(speed,0,delta*42)
 elif throttle>0:
  speed = move_toward(speed,limit*throttle,delta*acceleration)
 else:
  speed = move_toward(speed,0,delta*5)
 if speed>limit:
  speed = move_toward(speed,limit,delta*12)
 var speed_factor = clampf(speed/9,0,1)
 var turn_rate = lerpf(2.6,1.15,clampf(speed/75.0,0,1))
 rotation.y -= steer*turn_rate*speed_factor*delta*(1.25 if handbrake else 1.0)
 forward = -global_transform.basis.z
 var desired_velocity = forward*speed
 var grip = 3.0 if handbrake else 13.0
 var planar = Vector3(velocity.x,0,velocity.z).lerp(desired_velocity,1-exp(-grip*delta))
 velocity.x = planar.x
 velocity.z = planar.z
 velocity.y = -2 if is_on_floor() else velocity.y-22*delta
 is_drifting = handbrake and absf(steer)>0.25 and not offroad
 if is_drifting:
  drift_points += speed*delta*0.2
  nitro = minf(100,nitro+15*delta)
 move_and_slide()
 if get_slide_collision_count()>0:
  for i in get_slide_collision_count():
   var collision = get_slide_collision(i)
   if absf(collision.get_normal().y)<0.5 and collision_cooldown<=0:
    speed *= 0.68
    collision_cooldown = 0.65
    hits += 1
    impact.emit()
 progress = track.offset(global_position)
 if checkpoint<4 and progress>track.length*checkpoint/4.0 and progress<track.length*(checkpoint+0.65)/4.0:
  checkpoint += 1
 if previous_progress>track.length*0.85 and progress<track.length*0.15 and checkpoint==4:
  lap += 1
  checkpoint = 1
  lap_completed.emit(self)
 previous_progress = progress
 race_distance = lap*track.length+progress
 if not is_player and speed<3:
  reset_timer += delta
  if reset_timer>3:
   rescue()
   reset_timer = 0
 else:
  reset_timer = 0
 model.animate(delta,speed,steer,boosting)
 model.set_drift(is_drifting)
 if is_drifting:
  trail_timer += delta
  if trail_timer>0.07:
   trail_timer = 0
   # Small pooled-by-lifetime marks. Maximum roughly 60 live marks/player.
   var mark = CoastCarModel.box(track,Vector3(1.75,0.015,0.28),global_position+Vector3.UP*0.035,CoastCarModel.material(Color("282b2a")))
   mark.rotation.y = rotation.y
   var tween = create_tween()
   tween.tween_interval(3)
   tween.tween_callback(mark.queue_free)
