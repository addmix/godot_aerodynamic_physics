tool
extends EditorPlugin

var gizmo_plugin : EditorSpatialGizmoPlugin = preload("./core/spatial_gizmo/aero_surface_gizmo.gd").new()

func _enter_tree():
	PluginUtils.ifndef("physics/3d/aerodynamics/substeps", 1)
	PluginUtils.ifndef("physics/3d/aerodynamics/substeps", 1)
	add_custom_type("AeroSurface", "Spatial", load("./core/aero_surface.gd"), preload("./icons/node3d.svg"))
	add_custom_type("AeroBody", "RigidBody", load("./core/aero_body.gd"), preload("./icons/node3d.svg"))
#	add_custom_type("AeroSurfaceConfig", "Reference", load("./core/aero_surface.gd"), preload("./icons/node3d.svg"))
	
	add_spatial_gizmo_plugin(gizmo_plugin)

func _exit_tree():
	remove_custom_type("AeroSurface")
	remove_custom_type("AeroBody")
	
	remove_spatial_gizmo_plugin(gizmo_plugin)
