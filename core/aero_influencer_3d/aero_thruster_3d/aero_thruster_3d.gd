@tool
extends AeroInfluencer3D
class_name AeroThruster3D


@export_group("Thrust Control")
@export var throttle_control_config := create_throttle_control_config()
func create_throttle_control_config() -> AeroInfluencerControlConfig:
	var config := AeroInfluencerControlConfig.new()
	config.use_separate_minmax = true
	#this sets the thrust direction
	config.min_value.z = -1.0
	config.max_value.z = 0.0
	
	config.axis_configs.append(AeroInfluencerControlAxisConfig.new("throttle", -Vector3.ONE))
	return config

##Throttle value used to simulate the JetThrusterComponent
@export var throttle : Vector3 = Vector3.ZERO

@export_group("Simulation Parameters")
@export var max_thrust_force : float = 10000.0

func _ready():
	super._ready()
	if not Engine.is_editor_hint():
		if throttle_control_config:
			throttle_control_config = throttle_control_config.duplicate(true)

func _calculate_forces(substep_delta : float = 0.0) -> PackedVector3Array:
	var force_and_torque : PackedVector3Array = super._calculate_forces(substep_delta)
	
	_current_force = global_transform.basis * get_thrust_force()
	_current_torque = relative_position.cross(_current_force)
	
	force_and_torque[0] += _current_force
	force_and_torque[1] += _current_torque
	
	return force_and_torque

func _update_control_transform(substep_delta : float) -> void:
	super._update_control_transform(substep_delta)
	
	if throttle_control_config:
		throttle = throttle_control_config.update(self, substep_delta)

func get_thrust_force() -> Vector3:
	if Engine.is_editor_hint() and throttle_control_config:
		return max_thrust_force * throttle_control_config.min_value
	return max_thrust_force * throttle

func is_overriding_body_sleep() -> bool:
	return throttle.length_squared() > 0.0 or super()
