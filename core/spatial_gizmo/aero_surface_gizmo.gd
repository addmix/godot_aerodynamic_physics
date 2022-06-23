tool
extends EditorSpatialGizmoPlugin

var wing_opacity : float = 0.2
var wing_material := SpatialMaterial.new()
var wing_color := Color(1, 1, 1, wing_opacity)
var flap_color := Color(1, 1, 0, wing_opacity)

func _init():
	wing_material.flags_unshaded = true
	wing_material.flags_transparent = true
	wing_material.set_cull_mode(SpatialMaterial.CULL_DISABLED)
	wing_material.vertex_color_use_as_albedo = true
	wing_material.flags_no_depth_test = true

func has_gizmo(spatial : Spatial) -> bool:
	return spatial is AeroSurface

func redraw(gizmo : EditorSpatialGizmo) -> void:
	gizmo.clear()
	var spatial = gizmo.get_spatial_node()
	var st := SurfaceTool.new()

	#origin
	var half_chord : float = spatial.config.chord / 2.0
	var quater_chord : float = spatial.config.chord / 4.0
	var half_span : float = spatial.config.span / 2.0
	var flap_fraction : float = spatial.config.flap_fraction
	var flap_angle : float = deg2rad(spatial.flap_angle)

	var axis_z : float = half_chord * (1.0 - flap_fraction * 2.0)

	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	#flap section
	var tl := Vector3(-half_span, 0, half_chord - axis_z + quater_chord).rotated(Vector3(-1, 0, 0), flap_angle)
	var tr := Vector3(half_span, 0, half_chord - axis_z + quater_chord).rotated(Vector3(-1, 0, 0), flap_angle)
	tl.z += axis_z
	tr.z += axis_z
	var bl := Vector3(-half_span, 0, axis_z + quater_chord)
	var br := Vector3(half_span, 0, axis_z + quater_chord)

	#first triangle
	st.add_color(flap_color)
	st.add_vertex(tl)
	st.add_vertex(tr)
	st.add_vertex(bl)
	#second triangle
	st.add_vertex(bl)
	st.add_vertex(tr)
	st.add_vertex(br)

	#wing section
	tl = Vector3(-half_span, 0, axis_z + quater_chord)
	tr = Vector3(half_span, 0, axis_z + quater_chord)
	bl = Vector3(-half_span, 0, -half_chord + quater_chord)
	br = Vector3(half_span, 0, -half_chord + quater_chord)

	#first triangle
	st.add_color(wing_color)
	st.add_vertex(tl)
	st.add_vertex(tr)
	st.add_vertex(bl)
	#second triangle
	st.add_vertex(bl)
	st.add_vertex(tr)
	st.add_vertex(br)

	var mesh : ArrayMesh = st.commit()
	gizmo.add_collision_triangles(mesh.generate_triangle_mesh())
	gizmo.add_mesh(st.commit(), false, null, wing_material)
