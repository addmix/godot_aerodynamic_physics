@tool
extends AeroInfluencer3D
class_name AeroSurface3D

##Config resource used to define the size of the AeroSurface3D node.
@export var wing_config : AeroSurfaceConfig = AeroSurfaceConfig.new():
	set(value):
		wing_config = value
		if wing_config == null:
			return
		if not wing_config.is_connected("changed", update_gizmos):
			wing_config.changed.connect(update_gizmos)
			update_gizmos()

var angle_of_attack : float = 0.0
var sweep_angle := 0.0

var area : float = wing_config.chord * wing_config.span
var projected_wing_area : float = 0.0

var lift_direction := Vector3.ZERO
var lift_force : float = 0.0
var drag_force : float = 0.0

func _enter_tree() -> void:
	super._enter_tree()
	#initialize signal connections from resources
	if wing_config:
		if not wing_config.is_connected("changed", update_gizmos):
			wing_config.changed.connect(update_gizmos)
			update_gizmos()

func _calculate_forces(substep_delta : float = 0.0) -> PackedVector3Array:
	var force_and_torque : PackedVector3Array = super._calculate_forces(substep_delta)
	#calculate some common values, some necessary for debugging
	#air velocity in local space
	angle_of_attack = global_basis.y.angle_to(-world_air_velocity) - (PI / 2.0)
	sweep_angle = global_basis.x.angle_to(-world_air_velocity) - (PI / 2.0)
	
	area = wing_config.chord * wing_config.span
	projected_wing_area = abs(wing_config.span * wing_config.chord * sin(angle_of_attack))
	
	var right_facing_air_vector : Vector3 = world_air_velocity.cross(-global_transform.basis.y).normalized()
	lift_direction = drag_direction.cross(right_facing_air_vector).normalized()
	
	return force_and_torque
