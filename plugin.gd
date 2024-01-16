@tool
extends EditorPlugin

var path := PluginUtils.get_plugin_path("Godot Aerodynamic Physics")

#icons
const object_icon = preload("./icons/object.svg")
const node_icon = preload("./icons/node.svg")
const node2d_icon = preload("./icons/node2d.svg")
const node3d_icon = preload("./icons/node3d.svg")

#plugin gizmos
const gizmo_plugin = preload("./core/spatial_gizmo/aero_surface_gizmo.gd")
var gizmo_plugin_instance = gizmo_plugin.new()

#nodes
const aero_body_3d = preload("./core/aero_body_3d.gd")
const aero_influencer_3d = preload("./core/aero_influencer_3d/aero_influencer_3d.gd")
const aero_rotator_3d = preload("./core/aero_influencer_3d/aero_rotator_3d/aero_rotator_3d.gd")
const aero_propeller_3d = preload("./core/aero_influencer_3d/aero_rotator_3d/aero_propeller_3d.gd")
const aero_variable_propeller_3d = preload("./core/aero_influencer_3d/aero_rotator_3d/aero_variable_propeller_3d.gd")
const aero_cyclic_propeller_3d = preload("./core/aero_influencer_3d/aero_rotator_3d/aero_cyclic_propeller_3d.gd")
const aero_surface_3d = preload("./core/aero_influencer_3d/aero_surface_3d/aero_surface_3d.gd")
const aero_surface_config = preload("./core/aero_influencer_3d/aero_surface_3d/aero_surface_config.gd")
const manual_aero_surface_3d = preload("./core/aero_influencer_3d/aero_surface_3d/manual_aero_surface_3d/manual_aero_surface_3d.gd")
const manual_aero_surface_config = preload("./core/aero_influencer_3d/aero_surface_3d/manual_aero_surface_3d/manual_aero_surface_config.gd")
#const procedural_aero_surface_3d = preload("./core/aero_influencer_3d/aero_surface_3d/procedural_aero_surface_3d/procedural_aero_surface_3d.gd")
#const procedural_aero_surface_config = preload("./core/aero_influencer_3d/aero_surface_3d/procedural_aero_surface_3d/procedural_aero_surface_config.gd")

func _enter_tree():
	SettingsUtils.ifndef("physics/3d/aerodynamics/substeps", 1)
	add_autoload_singleton("AeroUnits", path + "/core/singletons/aero_units.gd")
	add_node_3d_gizmo_plugin(gizmo_plugin_instance)
	
	add_custom_type("AeroBody3D", "VehicleBody3D", aero_body_3d, node3d_icon)
	add_custom_type("AeroInfluencer3D", "Node3D", aero_influencer_3d, node3d_icon)
	add_custom_type("AeroRotator3D", "Node3D", aero_rotator_3d, node3d_icon)
	add_custom_type("AeroPropeller3D", "Node3D", aero_propeller_3d, node3d_icon)
	add_custom_type("AeroVariablePropeller3D", "Node3D", aero_variable_propeller_3d, node3d_icon)
	add_custom_type("AeroCyclicPropeller3D", "Node3D", aero_cyclic_propeller_3d, node3d_icon)
	add_custom_type("AeroSurface3D", "Node3D", aero_surface_3d, node3d_icon)
	add_custom_type("AeroSurfaceConfig", "Resource", aero_surface_config, object_icon)
	add_custom_type("ManualAeroSurface3D", "Node3D", manual_aero_surface_3d, node3d_icon)
	add_custom_type("ManualAeroSurfaceConfig", "Resource", manual_aero_surface_config, object_icon)

func _exit_tree():
	remove_custom_type("AeroBody3D")
	remove_custom_type("AeroInfluencer3D")
	remove_custom_type("AeroRotator3D")
	remove_custom_type("AeroPropeller3D")
	remove_custom_type("AeroVariablePropeller3D")
	remove_custom_type("AeroCyclicPropeller3D")
	remove_custom_type("AeroSurface3D")
	remove_custom_type("AeroSurfaceConfig")
	remove_custom_type("ManualAeroSurface3D")
	remove_custom_type("ManualAeroSurfaceConfig")

	remove_autoload_singleton("AeroUnits")
	remove_node_3d_gizmo_plugin(gizmo_plugin_instance)
