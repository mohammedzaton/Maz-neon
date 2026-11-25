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
 build_race_landmarks()

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
 noise.frequency = 0.12
 var tex = NoiseTexture2D.new()
 tex.width = 128
 tex.height = 128
 tex.noise = noise
 var ramp = Gradient.new()
 ramp.colors = PackedColorArray([Color(0.65,0.65,0.65),Color(0.9,0.9,0.9)])
 tex.color_ramp = ramp
 tex.seamless = true
 asphalt.albedo_texture = tex
 asphalt.uv1_scale = Vector3(1.8,1.8,1.8)
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
 var curb_red=[]
 var curb_pale=[]
 var dash_transforms=[]
 var rail_bars=[]
 var rail_posts=[]
 for i in range(0,ceili(length),6):
  var p=sample(i)
  var yaw=atan2(-direction(i).x,-direction(i).z)
  var basis=Basis(Vector3.UP,yaw)
  for side in [-1,1]:
   var transform=Transform3D(basis,p+right(i)*side*9.1+Vector3.UP*0.05)
   if (i/6)%2==0:
    curb_red.append(transform)
   else:
    curb_pale.append(transform)
  if i%12==0:
   dash_transforms.append(Transform3D(basis,p+Vector3.UP*0.048))
   for side in [-1,1]:
    var at=p+right(i)*side*12.5
    rail_bars.append(Transform3D(basis,at+Vector3.UP*0.68))
    for z in [-4,4]:
     rail_posts.append(Transform3D(basis,at+basis*Vector3(0,0.4,z)))
    var rail=StaticBody3D.new()
    rail.position=at
    rail.rotation.y=yaw
    add_child(rail)
    var shape=CollisionShape3D.new()
    var collision=BoxShape3D.new()
    collision.size=Vector3(0.6,1.2,12.5)
    shape.shape=collision
    shape.position.y=0.6
    rail.add_child(shape)
 batch_boxes(Vector3(0.65,0.1,5.8),red,curb_red)
 batch_boxes(Vector3(0.65,0.1,5.8),curb_white,curb_pale)
 batch_boxes(Vector3(0.14,0.02,3),white,dash_transforms)
 batch_boxes(Vector3(0.22,0.45,12.5),rails,rail_bars)
 batch_boxes(Vector3(0.18,1,0.18),rails,rail_posts)
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
 sm.sky_top_color = Color("264f79")
 sm.sky_horizon_color = Color("93b5c6")
 sm.ground_bottom_color = Color("34424b")
 sm.ground_horizon_color = Color("819b9b")
 sm.sky_energy_multiplier = 0.7
 sky.sky_material = sm
 e.background_mode = Environment.BG_SKY
 e.sky = sky
 e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 e.ambient_light_color = Color("b7c8d2")
 e.ambient_light_energy = 0.48
 e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 e.fog_enabled = true
 e.fog_light_color = Color("779bac")
 e.fog_density = 0.00018
 env.environment = e
 add_child(env)
 var sun = DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-27,-35,0)
 sun.light_color = Color("ffdfbc")
 sun.light_energy = 1.0
 sun.shadow_enabled = not OS.has_feature("web")
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
 CoastCarModel.box(ground,Vector3(2200,0.1,2200),Vector3(0,-0.3,0),CoastCarModel.material(Color("718061"),0,1))
 var ocean=MeshInstance3D.new()
 var water=PlaneMesh.new()
 water.size=Vector2(1300,1800)
 water.subdivide_width=48
 water.subdivide_depth=48
 ocean.mesh=water
 ocean.position=Vector3(850,-0.2,0)
 var shader=Shader.new()
 shader.code="""shader_type spatial;
 render_mode cull_disabled;
 varying float ripple;
 void vertex(){
  ripple=sin(VERTEX.x*0.035+TIME*0.6)*0.45+sin(VERTEX.z*0.05-TIME*0.8)*0.3;
  VERTEX.y+=ripple;
  NORMAL=normalize(vec3(-cos(VERTEX.x*0.035+TIME*0.6)*0.015,1.0,-cos(VERTEX.z*0.05-TIME*0.8)*0.015));
 }
 void fragment(){
  ALBEDO=mix(vec3(0.025,0.19,0.26),vec3(0.05,0.36,0.42),ripple*0.5+0.5);
  METALLIC=0.4;
  ROUGHNESS=0.18;
  SPECULAR=0.7;
 }"""
 var water_mat=ShaderMaterial.new()
 water_mat.shader=shader
 ocean.material_override=water_mat
 add_child(ocean)

func instance_mesh(mesh: Mesh,mat: Material,transforms: Array) -> void:
 var multi=MultiMesh.new()
 multi.transform_format=MultiMesh.TRANSFORM_3D
 multi.mesh=mesh
 multi.instance_count=transforms.size()
 for i in transforms.size():
  multi.set_instance_transform(i,transforms[i])
 var visual=MultiMeshInstance3D.new()
 visual.multimesh=multi
 visual.material_override=mat
 add_child(visual)

func build_scenery() -> void:
 # Palms are batched into two draw calls rather than hundreds of tree nodes.
 var trunks=[]
 var fronds=[]
 var trunk_mesh=CylinderMesh.new()
 trunk_mesh.top_radius=0.18
 trunk_mesh.bottom_radius=0.32
 trunk_mesh.height=8
 trunk_mesh.radial_segments=8
 var leaves=SurfaceTool.new()
 leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
 var verts=[Vector3.ZERO,Vector3(-0.45,-0.1,2.1),Vector3(0,-1.4,4.6),Vector3(0.45,-0.1,2.1)]
 for i in [0,1,2,0,2,3]:
  leaves.add_vertex(verts[i])
 leaves.generate_normals()
 var leaf_mesh=leaves.commit()
 var leaf_mat=CoastCarModel.material(Color("245a48"),0,0.9)
 leaf_mat.cull_mode=BaseMaterial3D.CULL_DISABLED
 for d in range(10,int(length),23):
  for side in [-1,1]:
   var p=sample(d)+right(d)*side*rng.randf_range(20,37)
   var yaw=rng.randf_range(0,TAU)
   trunks.append(Transform3D(Basis(Vector3.UP,yaw),p+Vector3.UP*4))
   for j in 7:
    var basis=Basis(Vector3.UP,yaw+j*TAU/7)*Basis(Vector3.RIGHT,0.12)
    fronds.append(Transform3D(basis,p+Vector3.UP*7.8))
 instance_mesh(trunk_mesh,CoastCarModel.material(Color("79624b"),0,0.95),trunks)
 instance_mesh(leaf_mesh,leaf_mat,fronds)
 var rock=CoastCarModel.material(Color("69797d"),0,0.95)
 var mountains=[]
 var rock_mesh=SphereMesh.new()
 rock_mesh.radial_segments=12
 rock_mesh.rings=8
 for i in 24:
  var p=Vector3(rng.randf_range(-620,-350),0,rng.randf_range(-550,520))
  var basis=Basis.IDENTITY.scaled(Vector3(rng.randf_range(35,90),rng.randf_range(20,65),rng.randf_range(35,90)))
  mountains.append(Transform3D(basis,p))
 instance_mesh(rock_mesh,rock,mountains)
 # Purposeful pit lane and spectators replace scattered placeholder towers.
 var concrete=CoastCarModel.material(Color("a7b7bd"),0.2,0.7)
 var dark=CoastCarModel.material(Color("1b3543"),0.5,0.3)
 var glass=CoastCarModel.material(Color("294e63"),0.65,0.15)
 for d in range(45,145,25):
  var building=Node3D.new()
  building.position=sample(d)-right(d)*26
  building.rotation.y=atan2(-direction(d).x,-direction(d).z)
  add_child(building)
  CoastCarModel.box(building,Vector3(12,5.5,23),Vector3(0,2.75,0),concrete)
  CoastCarModel.box(building,Vector3(0.06,2.4,21),Vector3(6.04,3.4,0),glass)
  CoastCarModel.box(building,Vector3(13,0.3,24),Vector3(0,5.6,0),dark)
  for z in [-7,0,7]:
   CoastCarModel.box(building,Vector3(0.08,2.3,4.3),Vector3(6.1,1.15,z),dark)
 var people=[]
 for d in [65,105,145]:
  var stand=Node3D.new()
  stand.position=sample(d)+right(d)*28
  stand.rotation.y=atan2(-direction(d).x,-direction(d).z)
  add_child(stand)
  for row in 6:
   CoastCarModel.box(stand,Vector3(2.2,0.55+row*0.6,30),Vector3(row*1.8,0.275+row*0.3,0),dark)
   for column in 18:
    var local=Vector3(row*1.8,1.15+row*0.6,-13+column*1.5)
    people.append(Transform3D(Basis.IDENTITY,stand.global_transform*local))
  CoastCarModel.box(stand,Vector3(15,0.25,33),Vector3(4.5,7.5,0),concrete)
  for z in [-15,15]:
   CoastCarModel.box(stand,Vector3(0.3,7.5,0.3),Vector3(10,3.75,z),concrete)
 var person=CapsuleMesh.new()
 person.radius=0.22
 person.height=0.85
 instance_mesh(person,CoastCarModel.material(Color("e0b095")),people)
 var sun=MeshInstance3D.new()
 var ball=SphereMesh.new()
 ball.radius=45
 ball.height=90
 sun.mesh=ball
 var sun_mat=CoastCarModel.material(Color("ffe6ab"))
 sun_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 sun.material_override=sun_mat
 sun.position=Vector3(180,150,-800)
 add_child(sun)

func build_race_landmarks() -> void:
 var dark=CoastCarModel.material(Color("132432"),0.55,0.4)
 var cyan=CoastCarModel.material(Color("35eed5"))
 cyan.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 var gold=CoastCarModel.material(Color("ffc373"))
 gold.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 # Illuminated, curved tunnel; road and collision boundaries stay the same width.
 for d in range(int(length*0.29),int(length*0.37),8):
  var segment=Node3D.new()
  segment.position=sample(d)
  segment.rotation.y=atan2(-direction(d).x,-direction(d).z)
  add_child(segment)
  CoastCarModel.box(segment,Vector3(25,0.5,8.6),Vector3(0,7.3,0),dark)
  for side in [-1,1]:
   CoastCarModel.box(segment,Vector3(0.5,7,8.6),Vector3(side*12,3.5,0),dark)
   CoastCarModel.box(segment,Vector3(0.07,0.16,8.2),Vector3(side*11.7,2,0),cyan if side<0 else gold)
  CoastCarModel.box(segment,Vector3(21,0.08,0.2),Vector3(0,7.01,0),cyan)
 # Track gates and chevrons communicate progress and upcoming corner direction.
 for index in range(1,4):
  var d=length*index/4.0
  var arch=Node3D.new()
  arch.position=sample(d)
  arch.rotation.y=atan2(-direction(d).x,-direction(d).z)
  add_child(arch)
  for x in [-11,11]:
   CoastCarModel.box(arch,Vector3(0.5,6.5,0.5),Vector3(x,3.25,0),dark)
   CoastCarModel.box(arch,Vector3(0.15,6,0.08),Vector3(x,3.25,0.3),cyan)
  CoastCarModel.box(arch,Vector3(23,0.65,0.8),Vector3(0,6.5,0),dark)
  var sign=Label3D.new()
  sign.text="SECTOR 0%d  /  MAZ RACING"%index
  sign.font_size=64
  sign.pixel_size=0.006
  sign.position=Vector3(0,6.5,0.45)
  sign.modulate=Color("84fff1")
  arch.add_child(sign)
 for d in range(100,int(length),65):
  var angle=direction(d).signed_angle_to(direction(d+45),Vector3.UP)
  if absf(angle)<0.2:
   continue
  var sign=Label3D.new()
  sign.text="› › ›" if angle<0 else "‹ ‹ ‹"
  sign.font_size=96
  sign.pixel_size=0.028
  sign.position=sample(d)+right(d)*(11 if angle<0 else -11)+Vector3.UP*2
  sign.rotation.y=atan2(-direction(d).x,-direction(d).z)
  sign.modulate=Color("ffe08d")
  add_child(sign)

func batch_boxes(size: Vector3,mat: Material,transforms: Array) -> void:
 var mesh=BoxMesh.new()
 mesh.size=size
 instance_mesh(mesh,mat,transforms)
