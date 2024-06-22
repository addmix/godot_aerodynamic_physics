@tool
extends EditorNode3DGizmoPlugin

var wing_opacity : float = 0.2
var wing_material := StandardMaterial3D.new()
var wing_color := Color(1, 1, 1, wing_opacity)
var flap_color := Color(1, 1, 0, wing_opacity)

func _init():
	wing_material.flags_unshaded = true
	wing_material.flags_transparent = true
	wing_material.cull_mode = StandardMaterial3D.CULL_DISABLED
	wing_material.vertex_color_use_as_albedo = true
	wing_material.flags_no_depth_test = true

func _get_gizmo_name() -> String:
	return "AeroSurfaceGizmo"

func _has_gizmo(for_node_3d : Node3D) -> bool:
	return for_node_3d is AeroSurface3D

func _redraw(gizmo : EditorNode3DGizmo) -> void:
	gizmo.clear()
	var spatial = gizmo.get_node_3d()

	var st := SurfaceTool.new()

	#origin
	var half_chord : float = spatial.wing_config.chord / 2.0
	var quater_chord : float = spatial.wing_config.chord / 4.0
	var half_span : float = spatial.wing_config.span / 2.0

	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	#flap section
	var tl := Vector3(-half_span, 0, half_chord)#.rotated(Vector3(-1, 0, 0), flap_angle)
	var tr := Vector3(half_span, 0, half_chord)#.rotated(Vector3(-1, 0, 0), flap_angle)
	tl.z += quater_chord
	tr.z += quater_chord
	var bl := Vector3(-half_span, 0, quater_chord)
	var br := Vector3(half_span, 0, quater_chord)

	#first triangle
	st.set_color(flap_color)
	st.add_vertex(tl)
	st.add_vertex(tr)
	st.add_vertex(bl)
	#second triangle
	st.add_vertex(bl)
	st.add_vertex(tr)
	st.add_vertex(br)

	#wing section
	tl = Vector3(-half_span, 0, quater_chord)
	tr = Vector3(half_span, 0, quater_chord)
	bl = Vector3(-half_span, 0, -half_chord + quater_chord)
	br = Vector3(half_span, 0, -half_chord + quater_chord)

	#first triangle
	st.set_color(wing_color)
	st.add_vertex(tl)
	st.add_vertex(tr)
	st.add_vertex(bl)
	#second triangle
	st.add_vertex(bl)
	st.add_vertex(tr)
	st.add_vertex(br)

	var mesh : ArrayMesh = st.commit()
	gizmo.add_mesh(mesh, wing_material)
	gizmo.add_collision_triangles(mesh.generate_triangle_mesh())
