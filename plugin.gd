@tool
extends EditorPlugin

var gizmo_plugin : EditorNode3DGizmoPlugin = preload("./core/spatial_gizmo/aero_surface_gizmo.gd").new()
var base_dir : String = "res://addons/godot_aerodynamic_physics/"

func _enter_tree():
	PluginUtils.ifndef("physics/3d/aerodynamics/substeps", 1)
	add_custom_type("AeroSurface3D", "Node3D", preload("./core/aero_surface_3d.gd"), preload("./icons/node3d.svg"))
	add_custom_type("AeroBody3D", "VehicleBody3D", preload("./core/aero_body_3d.gd"), preload("./icons/node3d.svg"))
#	add_custom_type("AeroSurfaceConfig", "Reference", load("./core/aero_surface.gd"), preload("./icons/node3d.svg"))
	
	#register units singleton
	add_autoload_singleton("AeroUnits", base_dir + "core/singletons/units.gd")
	
	add_spatial_gizmo_plugin(gizmo_plugin)

func _exit_tree():
	remove_custom_type("AeroSurface3D")
	remove_custom_type("AeroBody3D")
	
	remove_spatial_gizmo_plugin(gizmo_plugin)
