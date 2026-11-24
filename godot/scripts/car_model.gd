class_name CoastCarModel
extends Node3D

# Spectral GT RS (CC0): geometry is batched once by finish and moving assembly.
# Shared cached meshes avoid 258 draw calls per car and repeated mesh rebuilding.
static var geometry_cache: Dictionary={}
var wheels: Array[Node3D]=[]
var front_steering: Array[Node3D]=[]
var paint: StandardMaterial3D
var flames: Array[MeshInstance3D]=[]
var body: Node3D
var wing: Node3D
var smoke: CPUParticles3D
var sparks: CPUParticles3D
var drift_enabled: bool=false
var detailed_asset_loaded: bool=false
var underglow: MeshInstance3D

static func material(color: Color, metallic: float=0.0, roughness: float=0.6) -> StandardMaterial3D:
 var m=StandardMaterial3D.new()
 m.albedo_color=color
 m.metallic=metallic
 m.roughness=roughness
 return m

static func box(parent: Node3D,size: Vector3,at: Vector3,mat: Material) -> MeshInstance3D:
 var mesh=MeshInstance3D.new()
 var shape=BoxMesh.new()
 shape.size=size
 mesh.mesh=shape
 mesh.material_override=mat
 mesh.position=at
 parent.add_child(mesh)
 return mesh

func make_cache() -> void:
 if not geometry_cache.is_empty():
  return
 var packed=load("res://assets/spectral/spectral.glb") as PackedScene
 assert(packed!=null,"Fetch the pinned Spectral asset before importing the project")
 var source=packed.instantiate() as Node3D
 add_child(source)
 var data: Dictionary={}
 var pivots={"body":Vector3.ZERO,"Front_Left":Vector3(1.37,0.53,1.015),"Front_Right":Vector3(1.37,0.53,-1.015),"Rear_Left":Vector3(-1.48,0.53,1.015),"Rear_Right":Vector3(-1.48,0.53,-1.015),"wing":Vector3(-2,1.1,0)}
 for node in source.find_children("*","MeshInstance3D",true,false):
  var group="body"
  for wheel_name in ["Front_Left","Front_Right","Rear_Left","Rear_Right"]:
   if str(node.name).begins_with(wheel_name+"_") and not "Caliper" in str(node.name):
    group=wheel_name
  if str(node.name).begins_with("Active_Wing") or str(node.name).begins_with("Wing_Endplate"):
   group="wing"
  var transform=Transform3D(Basis.IDENTITY,-pivots[group])*source.global_transform.affine_inverse()*node.global_transform
  var normal_basis=transform.basis.inverse().transposed()
  if not data.has(group):
   data[group]={}
  for surface_index in node.mesh.get_surface_count():
   var mat=node.mesh.surface_get_material(surface_index)
   var key=mat.resource_name if mat else "default"
   if not data[group].has(key):
    data[group][key]={"v":PackedVector3Array(),"n":PackedVector3Array(),"uv":PackedVector2Array(),"i":PackedInt32Array(),"mat":mat}
   var target: Dictionary=data[group][key]
   var arrays=node.mesh.surface_get_arrays(surface_index)
   var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
   var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
   var uvs=arrays[Mesh.ARRAY_TEX_UV]
   var base=target.v.size()
   for i in vertices.size():
    target.v.append(transform*vertices[i])
    target.n.append((normal_basis*normals[i]).normalized())
    target.uv.append(uvs[i] if uvs!=null and i<uvs.size() else Vector2.ZERO)
   var indices=arrays[Mesh.ARRAY_INDEX]
   if indices!=null and indices.size()>0:
    for index in indices:
     target.i.append(base+index)
   else:
    for i in vertices.size():
     target.i.append(base+i)
 for group in data:
  var mesh=ArrayMesh.new()
  var mats=[]
  for key in data[group]:
   var target: Dictionary=data[group][key]
   var arrays=[]
   arrays.resize(Mesh.ARRAY_MAX)
   arrays[Mesh.ARRAY_VERTEX]=target.v
   arrays[Mesh.ARRAY_NORMAL]=target.n
   arrays[Mesh.ARRAY_TEX_UV]=target.uv
   arrays[Mesh.ARRAY_INDEX]=target.i
   mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
   mats.append(target.mat)
  geometry_cache[group]={"mesh":mesh,"mats":mats,"pivot":pivots[group]}
 source.queue_free()

func build(color: Color,_variant: int=0) -> void:
 make_cache()
 body=Node3D.new()
 body.rotation.y=PI/2
 body.scale=Vector3.ONE*0.9
 body.position.y=0.06
 add_child(body)
 for group in geometry_cache:
  var data: Dictionary=geometry_cache[group]
  var pivot=Node3D.new()
  pivot.position=data.pivot
  body.add_child(pivot)
  var visual=MeshInstance3D.new()
  visual.mesh=data.mesh
  pivot.add_child(visual)
  for i in data.mats.size():
   var source_mat=data.mats[i] as StandardMaterial3D
   if source_mat:
    var copy=source_mat.duplicate() as StandardMaterial3D
    if "Clearcoat" in source_mat.resource_name:
     copy.albedo_color=color
     copy.metallic=0.72
     copy.roughness=0.22
     paint=copy
    visual.set_surface_override_material(i,copy)
  if group in ["Front_Left","Front_Right","Rear_Left","Rear_Right"]:
   wheels.append(visual)
   if str(group).begins_with("Front"):
    front_steering.append(pivot)
  elif group=="wing":
   wing=pivot
 detailed_asset_loaded=true
 var flame_mat=material(Color("52cfff"))
 flame_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 flame_mat.emission_enabled=true
 flame_mat.emission=Color("24bfff")
 for x in [-0.46,0.46]:
  var flame=MeshInstance3D.new()
  var cone=CylinderMesh.new()
  cone.top_radius=0.015
  cone.bottom_radius=0.15
  cone.height=1.3
  cone.radial_segments=10
  flame.mesh=cone
  flame.material_override=flame_mat
  flame.rotation.x=PI/2
  flame.position=Vector3(x,0.4,2.75)
  flame.visible=false
  add_child(flame)
  flames.append(flame)
 underglow=MeshInstance3D.new()
 var quad=QuadMesh.new()
 quad.size=Vector2(3.1,5.7)
 underglow.mesh=quad
 underglow.rotation.x=-PI/2
 underglow.position.y=0.04
 var glow=material(Color(color.r,color.g,color.b,0.23))
 glow.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 glow.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 glow.albedo_texture=radial_texture()
 glow.cull_mode=BaseMaterial3D.CULL_DISABLED
 underglow.material_override=glow
 add_child(underglow)

static func radial_texture() -> ImageTexture:
 var image=Image.create(64,64,false,Image.FORMAT_RGBA8)
 for y in 64:
  for x in 64:
   var d=Vector2(x-31.5,y-31.5).length()/31.5
   image.set_pixel(x,y,Color(1,1,1,pow(clampf(1-d,0,1),1.5)))
 return ImageTexture.create_from_image(image)

func particle_material(color: Color) -> StandardMaterial3D:
 var mat=material(color)
 mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 mat.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
 mat.albedo_texture=radial_texture()
 mat.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_DISABLED
 return mat

func enable_player_fx() -> void:
 smoke=CPUParticles3D.new()
 smoke.amount=56
 smoke.lifetime=1.3
 smoke.emitting=false
 smoke.local_coords=false
 smoke.position=Vector3(0,0.3,1.6)
 smoke.emission_shape=CPUParticles3D.EMISSION_SHAPE_BOX
 smoke.emission_box_extents=Vector3(0.85,0.03,0.25)
 smoke.direction=Vector3(0,0.4,1)
 smoke.spread=50
 smoke.initial_velocity_min=1
 smoke.initial_velocity_max=3
 smoke.gravity=Vector3(0,0.4,0)
 smoke.scale_amount_min=0.5
 smoke.scale_amount_max=1.5
 var ramp=Gradient.new()
 ramp.colors=PackedColorArray([Color(0.8,0.86,0.9,0.4),Color(0.55,0.62,0.7,0)])
 smoke.color_ramp=ramp
 var mesh=QuadMesh.new()
 mesh.size=Vector2(1.8,1.8)
 mesh.material=particle_material(Color.WHITE)
 smoke.mesh=mesh
 add_child(smoke)
 sparks=CPUParticles3D.new()
 sparks.amount=28
 sparks.lifetime=0.55
 sparks.one_shot=true
 sparks.explosiveness=1
 sparks.local_coords=false
 sparks.emitting=false
 sparks.direction=Vector3(0,1,0)
 sparks.spread=85
 sparks.initial_velocity_min=3
 sparks.initial_velocity_max=8
 sparks.gravity=Vector3(0,-6,0)
 sparks.scale_amount_min=0.04
 sparks.scale_amount_max=0.1
 var spark_mesh=SphereMesh.new()
 spark_mesh.radial_segments=4
 spark_mesh.rings=2
 spark_mesh.material=particle_material(Color("ffd376"))
 sparks.mesh=spark_mesh
 add_child(sparks)

func emit_sparks() -> void:
 if sparks:
  sparks.restart()
  sparks.emitting=true

func set_drift(value: bool) -> void:
 drift_enabled=value
 if smoke:
  smoke.emitting=value

func animate(delta: float,speed: float,steering: float,boosting: bool) -> void:
 for wheel in wheels:
  wheel.rotation.z-=speed*delta/0.49
 for pivot in front_steering:
  pivot.rotation.y=-steering*0.36
 if body:
  body.rotation.x=lerpf(body.rotation.x,-steering*0.035,delta*10)
  body.position.y=0.06+sin(Time.get_ticks_msec()*0.024)*0.008*speed/60.0
 if wing:
  wing.rotation.z=lerpf(wing.rotation.z,0.22 if boosting else -0.05,delta*4)
 for flame in flames:
  flame.visible=boosting
  flame.scale.y=randf_range(0.75,1.5)
 if underglow:
  underglow.visible=boosting or drift_enabled
