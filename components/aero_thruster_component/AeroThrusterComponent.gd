@icon("../../icons/JetThrusterComponent.svg")
extends Marker3D
class_name AeroThrusterComponent

const AeroNodeUtils = preload("../../utils/node_utils.gd")

@onready var rigid_body : RigidBody3D = AeroNodeUtils.get_first_parent_of_type(self, RigidBody3D)
##Enables simulation of the JetThrusterComponent.
@export var enabled : bool = true
@export_group("Control")
##If enabled, throttle is automatically read from the ancestor AeroBody3D.
@export var get_throttle_from_aero_body : bool = true
##Throttle value used to simulate the JetThrusterComponent
@export var throttle : float = 1.0

@export_group("Simulation Parameters")
@export var max_thrust_force : float = 1000.0

func _physics_process(delta : float) -> void:
	if not enabled:
		return
	
	if rigid_body is AeroBody3D and get_throttle_from_aero_body:
		throttle = rigid_body.throttle_command
	
	var force_magnitude : float = get_thrust_magnitude() * delta
	
	var force := -global_transform.basis.z * force_magnitude
	var relative_position := global_position - rigid_body.global_position
	if rigid_body:
		#rigid_body.apply_force(-global_transform.basis.z * force_magnitude, rigid_body.global_transform.basis * position)
		rigid_body.apply_central_force(-global_transform.basis.z * force_magnitude)
		rigid_body.apply_torque(relative_position.cross(force))

func get_thrust_magnitude() -> float:
	return max_thrust_force * throttle
