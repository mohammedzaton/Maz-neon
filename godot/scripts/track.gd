class_name CoastTrack
extends Node3D

var curve: Curve3D
var length: float
var road_width: float = 18.0
var checkpoints: Array[Vector3] = []
var points: PackedVector3Array
var asphalt: StandardMaterial3D
var rng = RandomNumberGenerator.new()

func _ready() -> void:
 rng.seed = 624
 build_curve()
 build_environment()
 build_road()
 build_scenery()

func build_curve() -> void:
 var raw = [Vector3(0,0,0),Vector3(0,0,-140),Vector3(-70,0,-255),Vector3(-230,0,-240),Vector3(-295,0,-105),Vector3(-250,0,35),Vector3(-280,0,160),Vector3(-140,0,250),Vector3(25,0,205),Vector3(130,0,100),Vector3(95,0,0)]
 curve = Curve3D.new()
 curve.bake_interval = 2.5
 for i in raw.size():
  var tangent: Vector3 = (raw[(i+1)%raw.size()] - raw[posmod(i-1,raw.size())])*0.22
  curve.add_point(raw[i],-tangent,tangent)
 var tangent: Vector3 = (raw[1]-raw[-1])*0.22
 curve.add_point(raw[0],-tangent,tangent)
 length = curve.get_baked_length()
 points = curve.get_baked_points()

func sample(distance: float) -> Vector3:
 return curve.sample_baked(fposmod(distance,length),true)

func direction(distance: float) -> Vector3:
 return (sample(distance+2)-sample(distance-2)).normalized()

func right(distance: float) -> Vector3:
 return direction(distance).cross(Vector3.UP).normalized()

func offset(at: Vector3) -> float:
 return curve.get_closest_offset(Vector3(at.x,0,at.z))

func mesh_strip(inner: float, outer: float, mat: Material, y: float) -> void:
 var st = SurfaceTool.new()
 st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var count = ceili(length/4)
 for i in count:
  var d1 = float(i)*length/count
  var d2 = float(i+1)*length/count
  var a = sample(d1)+right(d1)*inner+Vector3.UP*y
  var b = sample(d1)+right(d1)*outer+Vector3.UP*y
  var c = sample(d2)+right(d2)*inner+Vector3.UP*y
  var d = sample(d2)+right(d2)*outer+Vector3.UP*y
  for v in [a,b,c,b,d,c]:
   st.set_uv(Vector2(v.x*0.1,v.z*0.1))
   st.add_vertex(v)
 st.generate_normals()
 var m = MeshInstance3D.new()
 m.mesh = st.commit()
 m.material_override = mat
 add_child(m)

func build_road() -> void:
 asphalt = CoastCarModel.material(Color("303a43"),0.05,0.9)
 # Tileable procedural asphalt with subtle aggregate, generated once.
 var noise = FastNoiseLite.new()
 noise.frequency = 0.75
 var tex = NoiseTexture2D.new()
 tex.width = 128
 tex.height = 128
 tex.noise = noise
 tex.seamless = true
 asphalt.albedo_texture = tex
 asphalt.uv1_scale = Vector3(7,7,7)
 asphalt.cull_mode = BaseMaterial3D.CULL_DISABLED
 asphalt.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 mesh_strip(-9,9,asphalt,0.025)
 var sand = CoastCarModel.material(Color("b69d7c"),0,1)
 mesh_strip(-12,-9,sand,0.012)
 mesh_strip(9,12,sand,0.012)
 var white = CoastCarModel.material(Color("ede2cc"))
 mesh_strip(-8.65,-8.45,white,0.04)
 mesh_strip(8.45,8.65,white,0.04)
 var red = CoastCarModel.material(Color("d64832"))
 var curb_white = CoastCarModel.material(Color("e4dcca"))
 var rails = CoastCarModel.material(Color("77818b"),0.65,0.5)
 for i in range(0,ceili(length),6):
  var p = sample(i)
  var yaw = atan2(-direction(i).x,-direction(i).z)
  for side in [-1,1]:
   var curb = CoastCarModel.box(self,Vector3(0.65,0.1,5.8),p+right(i)*side*9.1+Vector3.UP*0.05,red if (i/6)%2==0 else curb_white)
   curb.rotation.y = yaw
  if i%12==0:
   var dash = CoastCarModel.box(self,Vector3(0.14,0.02,3.0),p+Vector3.UP*0.048,white)
   dash.rotation.y = yaw
  # Barrier rails are visible road-side boundaries, with physical collisions.
  if i%12==0:
   for side in [-1,1]:
    var rail = StaticBody3D.new()
    rail.position = p+right(i)*side*12.5
    rail.rotation.y = yaw
    add_child(rail)
    CoastCarModel.box(rail,Vector3(0.22,0.45,12.5),Vector3(0,0.68,0),rails)
    for z in [-4,4]:
     CoastCarModel.box(rail,Vector3(0.18,1.0,0.18),Vector3(0,0.4,z),rails)
    var shape = CollisionShape3D.new()
    var collision = BoxShape3D.new()
    collision.size = Vector3(0.6,1.2,12.5)
    shape.shape = collision
    shape.position.y = 0.6
    rail.add_child(shape)
 for x in range(-8,9):
  for z in range(4):
   CoastCarModel.box(self,Vector3(1,0.025,1),Vector3(x,0.06,z+8),white if (x+z)%2==0 else CoastCarModel.material(Color("17212d")))
 # Start gantry, elevated without obstructing the road.
 var dark = CoastCarModel.material(Color("142a36"),0.35)
 for x in [-11,11]:
  CoastCarModel.box(self,Vector3(0.5,7,0.5),Vector3(x,3.5,10),dark)
 CoastCarModel.box(self,Vector3(23,1.7,0.6),Vector3(0,7,10),dark)
 var banner = Label3D.new()
 banner.text = "MAZ  /  COAST CIRCUIT"
 banner.font_size = 80
 banner.pixel_size = 0.008
 banner.position = Vector3(0,7,10.35)
 banner.modulate = Color("65ffcb")
 add_child(banner)

func build_environment() -> void:
 var env = WorldEnvironment.new()
 var e = Environment.new()
 var sky = Sky.new()
 var sm = ProceduralSkyMaterial.new()
 sm.sky_top_color = Color("24415b")
 sm.sky_horizon_color = Color("e8b68d")
 sm.ground_bottom_color = Color("34424b")
 sm.ground_horizon_color = Color("c8a786")
 sm.sky_energy_multiplier = 0.7
 sky.sky_material = sm
 e.background_mode = Environment.BG_SKY
 e.sky = sky
 e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 e.ambient_light_color = Color("b7c8d2")
 e.ambient_light_energy = 0.65
 e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 e.fog_enabled = true
 e.fog_light_color = Color("aa9a8b")
 e.fog_density = 0.00085
 env.environment = e
 add_child(env)
 var sun = DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-27,-35,0)
 sun.light_color = Color("ffdfb0")
 sun.light_energy = 1.45
 sun.shadow_enabled = true
 sun.directional_shadow_max_distance = 110
 add_child(sun)
 var ground = StaticBody3D.new()
 add_child(ground)
 var col = CollisionShape3D.new()
 var shape = BoxShape3D.new()
 shape.size = Vector3(2200,1,2200)
 col.shape = shape
 col.position.y = -0.51
 ground.add_child(col)
 CoastCarModel.box(ground,Vector3(2200,0.1,2200),Vector3(0,-0.06,0),CoastCarModel.material(Color("9b9876"),0,1))
 var ocean = CoastCarModel.material(Color("347f8f"),0.3,0.22)
 CoastCarModel.box(self,Vector3(1300,0.2,1800),Vector3(850,-0.15,0),ocean)

func build_scenery() -> void:
 var pine = CoastCarModel.material(Color("335d4c"))
 var bark = CoastCarModel.material(Color("69533c"))
 var rock = CoastCarModel.material(Color("796e60"),0,1)
 var facade = [Color("c6b9a5"),Color("657b85"),Color("9b8a79"),Color("ddd0b4")]
 for i in 140:
  var p = Vector3(rng.randf_range(-470,290),0,rng.randf_range(-430,420))
  if p.distance_to(sample(offset(p))) < 24:
   continue
  if i%3==0:
   var height = rng.randf_range(7,18)
   CoastCarModel.box(self,Vector3(0.7,height*0.5,0.7),p+Vector3.UP*height*0.25,bark)
   var crown = MeshInstance3D.new()
   var cone = CylinderMesh.new()
   cone.top_radius = 0.15
   cone.bottom_radius = height*0.25
   cone.height = height*0.75
   cone.radial_segments = 7
   crown.mesh = cone
   crown.material_override = pine
   crown.position = p+Vector3.UP*height*0.7
   add_child(crown)
  elif i%3==1:
   var h = rng.randf_range(5,28)
   var building = CoastCarModel.box(self,Vector3(9,h,10),p+Vector3.UP*h/2,CoastCarModel.material(facade[i%4]))
   for floor_index in range(1,int(h/3)):
    for window_index in 3:
     CoastCarModel.box(building,Vector3(1.2,1.1,0.03),Vector3(-3+window_index*3,-h/2+floor_index*3,5.02),CoastCarModel.material(Color("334c58"),0.6))
  else:
   var mountain = MeshInstance3D.new()
   var sphere = SphereMesh.new()
   sphere.radial_segments = 8
   sphere.rings = 4
   mountain.mesh = sphere
   mountain.material_override = rock
   mountain.scale = Vector3(rng.randf_range(12,30),rng.randf_range(6,17),rng.randf_range(12,24))
   mountain.position = p
   add_child(mountain)
 # Course-side signs and palm silhouettes make the racing line readable.
 for d in range(80,int(length),95):
  var p = sample(d)+right(d)*16
  var sign = Label3D.new()
  sign.text = "COAST / 02" if d%2 else "MAZ RACING"
  sign.font_size = 48
  sign.pixel_size = 0.04
  sign.position = p+Vector3.UP*3
  sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
  sign.modulate = Color("f4ddb3")
  add_child(sign)
