class_name CoastCarModel
extends Node3D

var wheels: Array[Node3D] = []
var paint: StandardMaterial3D
var flames: Array[MeshInstance3D] = []
var body: Node3D

static func material(color: Color, metallic: float = 0.0, roughness: float = 0.6) -> StandardMaterial3D:
 var m = StandardMaterial3D.new()
 m.albedo_color = color
 m.metallic = metallic
 m.roughness = roughness
 return m

static func box(parent: Node3D, size: Vector3, at: Vector3, mat: Material) -> MeshInstance3D:
 var mesh = MeshInstance3D.new()
 var shape = BoxMesh.new()
 shape.size = size
 mesh.mesh = shape
 mesh.material_override = mat
 mesh.position = at
 parent.add_child(mesh)
 return mesh

func build(color: Color, variant: int = 0) -> void:
 paint = material(color, 0.72, 0.27)
 body = Node3D.new()
 add_child(body)
 var black = material(Color("111820"), 0.3, 0.4)
 var glass = material(Color("172d3c"), 0.8, 0.12)
 var rim = material(Color("bec7ca"), 0.85, 0.25)
 var tire = material(Color("101216"), 0.05, 0.95)
 # Original wedge body mesh: sculpted shoulders, hood, cabin and rear deck.
 var rings = [Vector3(0.78, 0.58, -2.18), Vector3(0.94, 0.85, -1.45), Vector3(0.97, 0.91, 0.85), Vector3(0.9, 0.72, 2.05)]
 var vertices = PackedVector3Array()
 var normals = PackedVector3Array()
 for i in range(rings.size() - 1):
  var a: Vector3 = rings[i]
  var b: Vector3 = rings[i + 1]
  var a1 = Vector3(-a.x, a.y, a.z)
  var a2 = Vector3(a.x, a.y, a.z)
  var b1 = Vector3(-b.x, b.y, b.z)
  var b2 = Vector3(b.x, b.y, b.z)
  for triangle in [[a1,b1,a2],[a2,b1,b2],[a1,Vector3(-a.x,0.38,a.z),b1],[b1,Vector3(-a.x,0.38,a.z),Vector3(-b.x,0.38,b.z)],[a2,b2,Vector3(a.x,0.38,a.z)],[b2,Vector3(b.x,0.38,b.z),Vector3(a.x,0.38,a.z)]]:
   var n: Vector3 = (triangle[1]-triangle[0]).cross(triangle[2]-triangle[0]).normalized()
   for v in triangle:
    vertices.append(v)
    normals.append(n)
 var array = []
 array.resize(Mesh.ARRAY_MAX)
 array[Mesh.ARRAY_VERTEX] = vertices
 array[Mesh.ARRAY_NORMAL] = normals
 var mesh = ArrayMesh.new()
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,array)
 var shell = MeshInstance3D.new()
 shell.mesh = mesh
 shell.material_override = paint
 body.add_child(shell)
 box(body,Vector3(1.85,0.25,4.1),Vector3(0,0.51,0),paint)
 box(body,Vector3(1.91,0.12,4.26),Vector3(0,0.35,0),black)
 var cabin = box(body,Vector3(1.48,0.5,1.65),Vector3(0,1.07,0.1),glass)
 cabin.rotation.x = -0.06
 box(body,Vector3(1.47,0.07,1.0),Vector3(0,1.34,0.25),paint)
 for x in [-0.77,0.77]:
  box(body,Vector3(0.075,0.52,1.6),Vector3(x,1.05,0.1),paint)
  box(body,Vector3(0.25,0.12,0.23),Vector3(x*1.34,1.0,-0.64),paint)
 var white = material(Color("d9f3ec"))
 white.emission_enabled = true
 white.emission = Color("c5e9ee")
 white.emission_energy_multiplier = 0.5
 var red = material(Color("ff2248"))
 red.emission_enabled = true
 red.emission = Color("ff1135")
 for x in [-0.5,0.5]:
  box(body,Vector3(0.6,0.09,0.05),Vector3(x,0.65,-2.12),white)
  box(body,Vector3(0.6,0.08,0.05),Vector3(x,0.69,2.08),red)
  box(body,Vector3(0.14,0.1,0.2),Vector3(x,0.44,2.15),rim)
  var flame_mat = material(Color("5ef0ff"))
  flame_mat.emission_enabled = true
  flame_mat.emission = Color("39a7ff")
  flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
  var flame = box(body,Vector3(0.12,0.1,0.8),Vector3(x,0.44,2.5),flame_mat)
  flame.visible = false
  flames.append(flame)
 # Twin racing stripes and carbon spoiler.
 for x in [-0.26,0.26]:
  var stripe = box(body,Vector3(0.1,0.018,1.2),Vector3(x,0.83,-1.42),black)
  stripe.rotation.x = 0.18
 if variant != 1:
  box(body,Vector3(2.05,0.08,0.42),Vector3(0,1.12,1.72),black)
  for x in [-0.66,0.66]:
   box(body,Vector3(0.08,0.3,0.09),Vector3(x,0.97,1.72),black)
 for x in [-0.98,0.98]:
  for z in [-1.32,1.32]:
   var wheel = Node3D.new()
   wheel.position = Vector3(x,0.4,z)
   add_child(wheel)
   wheels.append(wheel)
   var cylinder = CylinderMesh.new()
   cylinder.top_radius = 0.38
   cylinder.bottom_radius = 0.38
   cylinder.height = 0.24
   cylinder.radial_segments = 16
   var rubber = MeshInstance3D.new()
   rubber.mesh = cylinder
   rubber.material_override = tire
   rubber.rotation.z = PI/2
   wheel.add_child(rubber)
   var hub = CylinderMesh.new()
   hub.top_radius = 0.25
   hub.bottom_radius = 0.25
   hub.height = 0.26
   hub.radial_segments = 10
   var hub_mesh = MeshInstance3D.new()
   hub_mesh.mesh = hub
   hub_mesh.material_override = rim
   hub_mesh.rotation.z = PI/2
   wheel.add_child(hub_mesh)

func animate(delta: float, speed: float, steering: float, boosting: bool) -> void:
 for wheel in wheels:
  wheel.rotation.x -= speed * delta / 0.38
 if body:
  body.rotation.z = lerpf(body.rotation.z,steering*0.045,delta*9)
 for flame in flames:
  flame.visible = boosting
  flame.scale.z = randf_range(0.7,1.35)
