class_name CoastHUD
extends CanvasLayer
signal start_requested()
signal pause_requested()
signal resume_requested()
signal home_requested()
signal rescue_requested()
signal camera_requested()
signal sound_requested()
signal assist_changed(value: bool)
var root: Control
var menu: Control
var race_ui: Control
var pause_menu: Control
var results: Control
var speed_label: Label
var lap_label: Label
var position_label: Label
var time_label: Label
var drift_label: Label
var countdown_label: Label
var nitro_bar: ProgressBar
var map_control: Control
var map_points: PackedVector2Array = []
var map_racers: Array[Vector2] = []
var touch_buttons: Array[TouchScreenButton] = []
var player_name: String = "APEX GT"
var result_title: Label
var result_stats: Label
var best_label: Label
var assist: CheckButton
const CYAN = Color("72f2cf")

func label(parent: Node, text: String, font_size: int, pos: Vector2, size: Vector2 = Vector2(400,80), color: Color = Color.WHITE) -> Label:
 var l = Label.new()
 l.text = text
 l.position = pos
 l.size = size
 l.add_theme_font_size_override("font_size",font_size)
 l.add_theme_color_override("font_color",color)
 l.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(l)
 return l

func style(color: Color, border: Color = Color.TRANSPARENT, radius: int = 12) -> StyleBoxFlat:
 var s = StyleBoxFlat.new()
 s.bg_color = color
 s.border_color = border
 s.set_border_width_all(1)
 s.set_corner_radius_all(radius)
 s.content_margin_left = 24
 s.content_margin_right = 24
 return s

func button(parent: Control, text: String, pos: Vector2, size: Vector2, callback: Callable, primary: bool = false) -> Button:
 var b = Button.new()
 b.text = text
 b.position = pos
 b.size = size
 b.add_theme_font_size_override("font_size",20)
 b.add_theme_stylebox_override("normal",style(CYAN if primary else Color(0.06,0.13,0.17,0.93),Color(0.7,0.9,0.9,0.2)))
 b.add_theme_stylebox_override("hover",style(Color("a5ffdf") if primary else Color("22454d")))
 b.add_theme_stylebox_override("pressed",style(Color("39b896")))
 b.add_theme_color_override("font_color",Color("102a28") if primary else Color.WHITE)
 b.pressed.connect(callback)
 parent.add_child(b)
 return b

func make_panel() -> Control:
 var panel = Control.new()
 panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 root.add_child(panel)
 return panel

func _ready() -> void:
 root = Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(root)
 menu = make_panel()
 var shade = ColorRect.new()
 shade.color = Color(0.015,0.045,0.06,0.82)
 shade.size = Vector2(640,900)
 shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
 menu.add_child(shade)
 label(menu,"M A Z   /   R A C I N G",18,Vector2(60,40),Vector2(500,40),CYAN)
 label(menu,"OWN THE\nCOAST.",88,Vector2(58,125),Vector2(600,210))
 label(menu,"COAST CIRCUIT  /  SUNSET SESSION",16,Vector2(65,365),Vector2(560,40),CYAN)
 label(menu,"6 DRIVERS    •    3 LAPS    •    ONE WINNER",16,Vector2(65,413),Vector2(550,40),Color("b8c7ce"))
 button(menu,"START RACE    ▶",Vector2(65,485),Vector2(300,68),func(): start_requested.emit(),true)
 button(menu,"SOUND  ♪",Vector2(380,485),Vector2(165,68),func(): sound_requested.emit())
 assist = CheckButton.new()
 assist.text = "AUTO ACCELERATE  /  تسارع تلقائي"
 assist.position = Vector2(65,575)
 assist.button_pressed = true
 assist.add_theme_font_size_override("font_size",17)
 assist.toggled.connect(func(value): assist_changed.emit(value))
 menu.add_child(assist)
 best_label = label(menu,"FIRST SESSION / SET YOUR RECORD",13,Vector2(65,655),Vector2(600,40),Color("8ba8b5"))
 race_ui = make_panel()
 lap_label = label(race_ui,"LAP 1 / 3",24,Vector2(35,25),Vector2(250,40),CYAN)
 position_label = label(race_ui,"6 / 6",48,Vector2(35,68),Vector2(250,70))
 time_label = label(race_ui,"00:00.00",25,Vector2(35,142),Vector2(260,40),Color("d6e5e7"))
 speed_label = label(race_ui,"000",72,Vector2(0,0),Vector2(200,100))
 drift_label = label(race_ui,"",20,Vector2(0,0),Vector2(400,45),CYAN)
 nitro_bar = ProgressBar.new()
 nitro_bar.show_percentage = false
 nitro_bar.max_value = 100
 nitro_bar.value = 100
 nitro_bar.size = Vector2(175,9)
 nitro_bar.add_theme_stylebox_override("background",style(Color("273f46")))
 nitro_bar.add_theme_stylebox_override("fill",style(CYAN))
 race_ui.add_child(nitro_bar)
 button(race_ui,"Ⅱ",Vector2(1155,25),Vector2(80,52),func(): pause_requested.emit())
 button(race_ui,"CAM",Vector2(1055,25),Vector2(85,52),func(): camera_requested.emit())
 button(race_ui,"RESET",Vector2(940,25),Vector2(100,52),func(): rescue_requested.emit())
 countdown_label = label(root,"",100,Vector2(560,245),Vector2(400,160),CYAN)
 # Native multitouch buttons: no JavaScript joystick and no mouse-only pressed signals.
 add_touch("steer_left","◀",Vector2(88,615),Color("263e49"))
 add_touch("steer_right","▶",Vector2(218,615),Color("263e49"))
 add_touch("brake","BRAKE",Vector2(925,615),Color("794438"))
 add_touch("drift","DRIFT",Vector2(1050,615),Color("4a5968"))
 add_touch("boost","NITRO",Vector2(1175,615),Color("237a71"))
 add_touch("throttle","GAS",Vector2(1175,482),Color("336853"))
 pause_menu = make_panel()
 add_overlay(pause_menu)
 label(pause_menu,"TAKE A BREATH.",52,Vector2(390,190),Vector2(700,100))
 button(pause_menu,"RESUME RACE",Vector2(440,330),Vector2(400,65),func(): resume_requested.emit(),true)
 button(pause_menu,"BACK TO MENU",Vector2(440,420),Vector2(400,65),func(): home_requested.emit())
 results = make_panel()
 add_overlay(results)
 result_title = label(results,"FINISH LINE.",60,Vector2(350,140),Vector2(850,100),CYAN)
 result_stats = label(results,"",27,Vector2(385,255),Vector2(850,160))
 button(results,"RACE AGAIN",Vector2(440,455),Vector2(400,65),func(): start_requested.emit(),true)
 button(results,"BACK TO MENU",Vector2(440,540),Vector2(400,65),func(): home_requested.emit())
 show_mode("menu")
 get_viewport().size_changed.connect(layout)
 layout()

func add_overlay(parent: Control) -> void:
 var bg = ColorRect.new()
 bg.color = Color(0.01,0.035,0.045,0.94)
 bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 bg.mouse_filter = Control.MOUSE_FILTER_STOP
 parent.add_child(bg)

func circle_texture(color: Color) -> ImageTexture:
 var image = Image.create(112,112,false,Image.FORMAT_RGBA8)
 for y in 112:
  for x in 112:
   var d = Vector2(x-56,y-56).length()
   var c = color
   c.a = 0.82 if d<53 else 0.0
   if d>50 and d<53:
    c = Color(0.8,0.95,0.94,0.5)
   image.set_pixel(x,y,c)
 return ImageTexture.create_from_image(image)

func add_touch(action_name: String, title: String, at: Vector2, color: Color) -> void:
 var b = TouchScreenButton.new()
 b.name = action_name
 b.action = action_name
 b.position = at-Vector2(56,56)
 b.texture_normal = circle_texture(color)
 b.texture_pressed = circle_texture(CYAN)
 b.shape = CircleShape2D.new()
 b.shape.radius = 53
 b.passby_press = true
 b.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
 var text = Label.new()
 text.text = title
 text.position = Vector2(0,32)
 text.size = Vector2(112,50)
 text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 text.add_theme_font_size_override("font_size",20)
 text.mouse_filter = Control.MOUSE_FILTER_IGNORE
 b.add_child(text)
 add_child(b)
 touch_buttons.append(b)

func layout() -> void:
 var size = get_viewport().get_visible_rect().size
 var dx = size.x-1280
 var dy = size.y-720
 for i in touch_buttons.size():
  var positions = [Vector2(88,615),Vector2(218,615),Vector2(925+dx,615),Vector2(1050+dx,615),Vector2(1175+dx,615),Vector2(1175+dx,482)]
  touch_buttons[i].position = positions[i]+Vector2(0,dy)-Vector2(56,56)
 speed_label.position = Vector2(size.x-235,265)
 nitro_bar.position = Vector2(size.x-220,370)
 drift_label.position = Vector2(size.x/2-190,105)
 countdown_label.position = Vector2(size.x/2-80,size.y/2-80)

func show_mode(mode: String) -> void:
 menu.visible = mode=="menu"
 race_ui.visible = mode in ["race","countdown"]
 pause_menu.visible = mode=="pause"
 results.visible = mode=="results"
 countdown_label.visible = mode=="countdown"
 for b in touch_buttons:
  b.visible = mode=="race"

func draw_map(at_points: PackedVector2Array, racers: Array[Vector2]) -> void:
 map_points = at_points
 map_racers = racers
 # Rendering delegated to a compact Node2D, kept separate from the input layer.
