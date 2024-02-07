# From https://github.com/addmix/godot_utils

@tool
extends MeshInstance3D
class_name AeroDebugVector3D

@export var value := Vector3.ZERO:
	set(x):
		value = x
		material.set_shader_parameter("_length", value.length())

		#prevent error when value is 0
		var length_squared := value.length_squared()
		if is_equal_approx(length_squared, 0.0):
			#reset rotation
			basis = Basis()
			return
		
		var up = Vector3(0, 1, 0)
		var dot := value.dot(up)
		var dot_squared := dot * dot
		
		if is_equal_approx(dot_squared, length_squared):
			up = Vector3(1, 0, 0)
		
		transform = transform.looking_at(value, up)
@export var color := Color(1, 1, 1):
	set(x):
		color = x
		material.set_shader_parameter("_color", color)
@export var width := 0.1:
	set(x):
		width = x
		material.set_shader_parameter("_width", width)
@export var checker := false:
	set(x):
		checker = x
		material.set_shader_parameter("checker_pattern", checker)

var material := ShaderMaterial.new()

var _mesh : Array[Vector3] = [Vector3(0, -1, 0), Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(1, 0, 0)]
var _verticies : Array[Vector3] = [Vector3(0, -1, 0), #index 0 bottom point
#go clockwise from -z position
Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0), #index 1-4 side poitns
#top
Vector3(0, 1, 0)] #index 5 top point

#   5
#
#   1
# 4   2
#   3
#
#   0

#bottom triangle order
#021
#032
#043
#014

#top triangle order
#512
#523
#534
#541

func _init(_color : Color = Color(), _width : float = 0.1, _checker : bool = false) -> void:
	material.shader = preload("./vector_3d.gdshader")
	material.render_priority = 100
	
	color = _color
	width = _width
	checker = _checker

	var st := SurfaceTool.new()

	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(material)
	#bottom 4 triangles
	st.add_vertex(_verticies[0])
	st.add_vertex(_verticies[2])
	st.add_vertex(_verticies[1])

	st.add_vertex(_verticies[0])
	st.add_vertex(_verticies[3])
	st.add_vertex(_verticies[2])

	st.add_vertex(_verticies[0])
	st.add_vertex(_verticies[4])
	st.add_vertex(_verticies[3])

	st.add_vertex(_verticies[0])
	st.add_vertex(_verticies[1])
	st.add_vertex(_verticies[4])

	#top 4 triangles
	st.add_vertex(_verticies[5])
	st.add_vertex(_verticies[1])
	st.add_vertex(_verticies[2])

	st.add_vertex(_verticies[5])
	st.add_vertex(_verticies[2])
	st.add_vertex(_verticies[3])

	st.add_vertex(_verticies[5])
	st.add_vertex(_verticies[3])
	st.add_vertex(_verticies[4])

	st.add_vertex(_verticies[5])
	st.add_vertex(_verticies[4])
	st.add_vertex(_verticies[1])

	st.generate_normals()
	mesh = st.commit()
	
	custom_aabb = AABB(Vector3.ZERO, Vector3(100, 100, 100))
