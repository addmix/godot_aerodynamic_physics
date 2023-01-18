@tool
extends EditorPlugin

var gizmo_plugin : EditorNode3DGizmoPlugin = preload("./core/spatial_gizmo/aero_surface_gizmo.gd").new()
var base_dir : String = "res://addons/godot_aerodynamic_physics/"

func _enter_tree():
	SettingsUtils.ifndef("physics/3d/aerodynamics/substeps", 1)
	add_custom_type("AeroSurface3D", "Node3D", load(base_dir + "core/aero_surface_3d.gd"), load(base_dir + "icons/node3d.svg"))
	add_custom_type("AeroBody3D", "RigidBody3D", load(base_dir + "core/aero_body_3d.gd"), load(base_dir + "icons/node3d.svg"))

	#register units singleton
	add_autoload_singleton("AeroUnits", base_dir + "core/singletons/units.gd")

#	print(InputMap.has_action("toggle_aerodynamic_debug"))
#	InputMap.add_action("toggle_aerodynamic_debug")
#	var debug_key := InputEventKey.new()
#	debug_key.set_keycode(KEY_F10)
#	InputMap.action_add_event("toggle_aerodynamic_debug", debug_key)

	add_node_3d_gizmo_plugin(gizmo_plugin)

func _exit_tree():
	remove_custom_type("AeroSurface")
	remove_custom_type("AeroBody")

	remove_node_3d_gizmo_plugin(gizmo_plugin)
