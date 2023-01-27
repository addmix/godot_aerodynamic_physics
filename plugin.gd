@tool
extends EditorPlugin
#icons
const node_icon = preload("./icons/node.svg")
const node2d_icon = preload("./icons/node2d.svg")
const node3d_icon = preload("./icons/node3d.svg")

#plugin gizmos
const gizmo_plugin = preload("./core/spatial_gizmo/aero_surface_gizmo.gd")
var gizmo_plugin_instance = gizmo_plugin.new()

#singletons
const aero_units = "./core/singletons/units.gd"

#nodes
const aero_body_3d = preload("./core/aero_body_3d.gd")
const aero_surface_3d = preload("./core/aero_surface_3d.gd")
const manual_aero_surface_3d = preload("./core/manual_aero_surface_3d.gd")
const manual_aero_surface_config = preload("./core/manual_aero_surface_config.gd")
const procedural_aero_surface_3d = preload("./core/procedural_aero_surface_3d.gd")
const procedural_aero_surface_config = preload("./core/procedural_aero_surface_config.gd")

func _enter_tree():
	SettingsUtils.ifndef("physics/3d/aerodynamics/substeps", 1)
	add_custom_type("AeroBody3D", "RigidBody3D", aero_body_3d, node3d_icon)
	add_custom_type("AeroSurface3D", "Node3D", aero_surface_3d, node3d_icon)
	add_custom_type("ManualAeroSurface3D", "AeroSurface3D", manual_aero_surface_3d, node3d_icon)
	add_custom_type("ManualAeroSurfaceConfig", "ManualAeroSurfaceConfig", manual_aero_surface_config, node3d_icon)
	add_custom_type("ProceduralAeroSurface3D", "AeroSurface3D", procedural_aero_surface_3d, node3d_icon)
	add_custom_type("ProceduralAeroSurfaceConfig", "ProceduralAeroSurfaceConfig", procedural_aero_surface_config, node3d_icon)

	add_autoload_singleton("AeroUnits", aero_units)
	add_node_3d_gizmo_plugin(gizmo_plugin_instance)

func _exit_tree():
	remove_custom_type("AeroBody3D")
	remove_custom_type("AeroSurface3D")
	remove_custom_type("ManualAeroSurface3D")
	remove_custom_type("ManualAeroSurfaceConfig")
	remove_custom_type("ProceduralAeroSurface3D")
	remove_custom_type("ProceduralAeroSurfaceConfig")

	remove_autoload_singleton("AeroUnits")
	remove_node_3d_gizmo_plugin(gizmo_plugin_instance)
