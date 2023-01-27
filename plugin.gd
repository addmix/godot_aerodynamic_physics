@tool
extends EditorPlugin

var gizmo_plugin : EditorNode3DGizmoPlugin = preload("./core/spatial_gizmo/aero_surface_gizmo.gd").new()
var base_dir : String = "res://addons/godot_aerodynamic_physics/"

func _enter_tree():
	SettingsUtils.ifndef("physics/3d/aerodynamics/substeps", 1)
	add_custom_type("AeroBody3D", "RigidBody3D", load(base_dir + "core/aero_body_3d.gd"), load(base_dir + "icons/node3d.svg"))
	add_custom_type("AeroSurface3D", "Node3D", load(base_dir + "core/aero_surface_3d.gd"), load(base_dir + "icons/node3d.svg"))
	add_custom_type("ManualAeroSurface3D", "AeroSurface3D", load(base_dir + "core/manual_aero_surface_3d.gd"), load(base_dir + "icons/node3d.svg"))
	add_custom_type("ManualAeroSurfaceConfig", "ManualAeroSurfaceConfig", load(base_dir + "core/manual_aero_surface_config.gd"), load(base_dir + "icons/node3d.svg"))
	add_custom_type("ProceduralAeroSurface3D", "AeroSurface3D", load(base_dir + "core/procedural_aero_surface_3d.gd"), load(base_dir + "icons/node3d.svg"))
	add_custom_type("ProceduralAeroSurfaceConfig", "ProceduralAeroSurfaceConfig", load(base_dir + "core/procedural_aero_surface_config.gd"), load(base_dir + "icons/node3d.svg"))


	#register units singleton
	add_autoload_singleton("AeroUnits", base_dir + "core/singletons/units.gd")
	add_node_3d_gizmo_plugin(gizmo_plugin)

func _exit_tree():
	remove_custom_type("AeroSurface")
	remove_custom_type("AeroBody")

	remove_node_3d_gizmo_plugin(gizmo_plugin)
