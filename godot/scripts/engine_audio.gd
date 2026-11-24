class_name CoastEngineAudio
extends AudioStreamPlayer
var phase: float = 0
var playback: AudioStreamGeneratorPlayback
var engine_speed: float = 0
var active: bool = false
var enabled: bool = true
func _ready() -> void:
 var gen = AudioStreamGenerator.new()
 gen.mix_rate = 22050
 gen.buffer_length = 0.12
 stream = gen
 volume_db = -24
 play()
 playback = get_stream_playback()
func _process(_delta: float) -> void:
 if playback == null:
  return
 var frames = playback.get_frames_available()
 var frequency = 40+engine_speed*2.4
 for i in frames:
  phase = fmod(phase+frequency/22050.0,1.0)
  var value = (sin(phase*TAU)+sin(phase*TAU*2)*0.3+sin(phase*TAU*4)*0.1)*0.4 if active and enabled else 0.0
  playback.push_frame(Vector2(value,value))
