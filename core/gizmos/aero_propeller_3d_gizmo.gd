@tool
extends EditorNode3DGizmoPlugin

var opacity : float = 0.2
var material := StandardMaterial3D.new()
var color := Color(1, 0, 1, opacity)
var disabled_color := Color.from_hsv(0.0, 0.0, 1.0, opacity * 0.1)

func _init():
	material.flags_unshaded = true
	#material.flags_transparent = true
	material.cull_mode = StandardMaterial3D.CULL_DISABLED
	material.vertex_color_use_as_albedo = true
	#material.flags_no_depth_test = true
	material.render_priority = 100

func _get_gizmo_name() -> String:
	return "AeroPropeller3DGizmo"

func _has_gizmo(for_node_3d : Node3D) -> bool:
	return for_node_3d is AeroPropeller3D

func _redraw(gizmo : EditorNode3DGizmo) -> void:
	gizmo.clear()
	var propeller : AeroPropeller3D = gizmo.get_node_3d()
	
	var arrow_shaft_width : float = 0.2
	var arrow_shaft_length : float = 0.6
	var arrow_point_width : float = 0.4
	
	var arrow_total_length := arrow_shaft_length + arrow_point_width / 2
	#base vertices for arrow profile shape
	var arrow_vertices := PackedVector3Array([
		Vector3(0, arrow_total_length, 0),
		Vector3(0, arrow_shaft_length, arrow_point_width / 2),
		Vector3(0, arrow_shaft_length, arrow_shaft_width / 2),
		Vector3(0, 0, arrow_shaft_width / 2),
		Vector3(0, 0, arrow_shaft_width / 2),
	])
	
	#create vertices for the second half of the propeller, mirrored on the Z axis
	var duplicate_vertices := arrow_vertices.duplicate()
	duplicate_vertices.reverse()
	for vertex : Vector3 in duplicate_vertices:
		arrow_vertices.append(vertex * Vector3(1, 1, -1))
	
	#duplicate vertices, and rotate
	duplicate_vertices = arrow_vertices.duplicate()
	for vertex : Vector3 in duplicate_vertices:
		arrow_vertices.append(Vector3(vertex.z, vertex.y, vertex.x))
	
	var circle_radius : float = 0.7
	var circle_arrow_width : float = 0.1
	var circle_arrow_size : float = 0.2
	var circle_count : int = 3
	var circle_segment_count : int = 6
	var circle_segment_arc : float = deg_to_rad(60.0)
	var circle_height : float = 0.1
	var circle_vertices := PackedVector3Array()
	
	#make arrow
	
	circle_vertices.append(Vector3(0, 0, circle_radius - circle_arrow_width / 2))
	circle_vertices.append(Vector3(0, 0, circle_radius - circle_arrow_size))
	circle_vertices.append(Vector3(0, 0, circle_radius - circle_arrow_size))
	circle_vertices.append(Vector3(circle_arrow_size, 0, circle_radius))
	circle_vertices.append(Vector3(circle_arrow_size, 0, circle_radius))
	circle_vertices.append(Vector3(0, 0, circle_radius + circle_arrow_size))
	circle_vertices.append(Vector3(0, 0, circle_radius + circle_arrow_size))
	circle_vertices.append(Vector3(0, 0, circle_radius + circle_arrow_width / 2))
	
	var rotation : float = 0.0
	for segment_count in circle_segment_count:
		rotation -= circle_segment_arc / circle_segment_count
		circle_vertices.append(Vector3(0, 0, circle_radius + circle_arrow_width / 2).rotated(Vector3(0, 1, 0), rotation))
		circle_vertices.append(Vector3(0, 0, circle_radius + circle_arrow_width / 2).rotated(Vector3(0, 1, 0), rotation + circle_segment_arc / circle_segment_count))
		circle_vertices.append(Vector3(0, 0, circle_radius - circle_arrow_width / 2).rotated(Vector3(0, 1, 0), rotation))
		circle_vertices.append(Vector3(0, 0, circle_radius - circle_arrow_width / 2).rotated(Vector3(0, 1, 0), rotation + circle_segment_arc / circle_segment_count))
	
	#cap end
	circle_vertices.append(Vector3(0, 0, circle_radius + circle_arrow_width / 2).rotated(Vector3(0, 1, 0), rotation))
	circle_vertices.append(Vector3(0, 0, circle_radius - circle_arrow_width / 2).rotated(Vector3(0, 1, 0), rotation))
	
	for index : int in circle_vertices.size():
		circle_vertices[index] += Vector3(0, circle_height, 0)
	
	duplicate_vertices = circle_vertices.duplicate()
	rotation = 0.0
	for circle : int in circle_count - 1:
		rotation += deg_to_rad(360.0) / circle_count
		for vertex : Vector3 in duplicate_vertices: #should always be a duplicate of 2, as the array was doubled in size in the previous step
			circle_vertices.append(vertex.rotated(Vector3(0, 1, 0), rotation))
	
	
	#i could store a point mesh resource in the plugin, but this is a little bit of fun
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	
	#set color for vertices
	st.set_color(color)
	if propeller.disabled:
		st.set_color(disabled_color)
	
	#add arrow vertices to surface tool
	st.add_vertex(arrow_vertices[0])
	for index : int in arrow_vertices.size() - 1:
		st.add_vertex(arrow_vertices[index + 1])
		st.add_vertex(arrow_vertices[index + 1])
	st.add_vertex(arrow_vertices[-1])
	
	
	#add circle vertices to surface tool
	for vertex : Vector3 in circle_vertices:
		st.add_vertex(vertex)
	
	
	
	#turn surface tool into mesh, and assign mesh to the gizmo
	var mesh : ArrayMesh = st.commit()
	gizmo.add_mesh(mesh, material)
	gizmo.add_collision_triangles(mesh.generate_triangle_mesh())
