@tool
extends EditorPlugin

var gizmo_plugin : EditorNode3DGizmoPlugin = preload("./core/spatial_gizmo/aero_surface_gizmo.gd").new()
var base_dir : String = "res://addons/godot_aerodynamic_physics/"

func _enter_tree():
	SettingsUtils.ifndef("physics/3d/aerodynamics/substeps", 1)
	add_custom_type("AeroSurface", "Node3D", load(base_dir + "core/aero_surface_3d.gd"), load(base_dir + "icons/node3d.svg"))
	add_custom_type("AeroBody", "RigidDynamicBody3D", load(base_dir + "core/aero_body_3d.gd"), load(base_dir + "icons/node3d.svg"))

	#register units singleton
	add_autoload_singleton("AeroUnits", base_dir + "core/singletons/units.gd")

	add_node_3d_gizmo_plugin(gizmo_plugin)

func _exit_tree():
	remove_custom_type("AeroSurface")
	remove_custom_type("AeroBody")

	remove_node_3d_gizmo_plugin(gizmo_plugin)
