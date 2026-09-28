@tool
extends EditorNode3DGizmoPlugin

var opacity : float = 0.2
var material := StandardMaterial3D.new()
var wing_color := Color(1, 1, 1, opacity)
var flap_color := Color(1, 1, 0, opacity)
var disabled_color := Color.from_hsv(0.0, 0.0, 1.0, opacity * 0.1)


func _init():
	material.flags_unshaded = true
	material.flags_transparent = true
	material.cull_mode = StandardMaterial3D.CULL_DISABLED
	material.vertex_color_use_as_albedo = true
	material.flags_no_depth_test = true
	material.render_priority = 100

func _get_gizmo_name() -> String:
	return "AeroSurface3DGizmo"

func _has_gizmo(for_node_3d : Node3D) -> bool:
	return for_node_3d is AeroSurface3D

func _redraw(gizmo : EditorNode3DGizmo) -> void:
	gizmo.clear()
	var aero_surface : AeroSurface3D = gizmo.get_node_3d()
	
	var st := SurfaceTool.new()
	
	#origin
	var half_chord : float = aero_surface.wing_config.chord / 2.0
	var quater_chord : float = aero_surface.wing_config.chord / 4.0
	var half_span : float = aero_surface.wing_config.span / 2.0
	
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	#flap section
	var tl := Vector3(-half_span, 0, half_chord)#.rotated(Vector3(-1, 0, 0), flap_angle)
	var tr := Vector3(half_span, 0, half_chord)#.rotated(Vector3(-1, 0, 0), flap_angle)
	tl.z += quater_chord
	tr.z += quater_chord
	var bl := Vector3(-half_span, 0, quater_chord)
	var br := Vector3(half_span, 0, quater_chord)
	
	var adjusted_flap_color : Color = flap_color
	if aero_surface.disabled:
		adjusted_flap_color = disabled_color
	
	#first triangle
	st.set_color(adjusted_flap_color)
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

	var adjusted_wing_color : Color = wing_color
	if aero_surface.disabled:
		adjusted_wing_color = disabled_color
	
	#first triangle
	st.set_color(adjusted_wing_color)
	st.add_vertex(tl)
	st.add_vertex(tr)
	st.add_vertex(bl)
	#second triangle
	st.add_vertex(bl)
	st.add_vertex(tr)
	st.add_vertex(br)

	var mesh : ArrayMesh = st.commit()
	gizmo.add_mesh(mesh, material)
	gizmo.add_collision_triangles(mesh.generate_triangle_mesh())
