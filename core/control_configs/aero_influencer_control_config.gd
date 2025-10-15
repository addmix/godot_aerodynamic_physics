@tool
extends Resource
class_name AeroInfluencerControlConfig

const AeroMathUtils = preload("../../utils/math_utils.gd")

##If enabled, this AeroInfluencer3D node will automatically rotate to accommodate control inputs.
@export var enable_control : bool = true
@export var axis_configs : Array[AeroInfluencerControlAxisConfig] = []:
	set(x):
		# When a new element is added to the axis_configs array, automatically set it as 
		# an AeroInfluencerControlAxisConfig, for convenience
		if x.size() > 0 and x[-1] == null:
			x[-1] = AeroInfluencerControlAxisConfig.new()
		axis_configs = x
#X = pitch, Y = yaw, Z = roll

@export_subgroup("Limits")
var current_value := Vector3.ZERO

#@export var min_value := Vector3.ZERO
@export var use_separate_minmax : bool = false
##Maximum rotation (in radians) this AeroInfluencer can rotate for controls.
@export var max_value := Vector3.ZERO:
	set(x):
		max_value = x
		if not use_separate_minmax:
			min_value = -max_value
@export var min_value := Vector3.ZERO:
	set(x):
		if use_separate_minmax:
			min_value = x
		else:
			min_value = -max_value
@export_subgroup("Movement Speed")
@export var limit_movement_speed : bool = false
@export var movement_speed : float = 1.0
@export_subgroup("")

func update(aero_influencer : AeroInfluencer3D, delta : float) -> Vector3:
	if not enable_control:
		return current_value
	
	var local_relative_position : Vector3 = aero_influencer.relative_position * aero_influencer.aero_body.global_basis
	
	var axis_sign : Vector3 = Vector3(sign(local_relative_position.x), sign(local_relative_position.y), sign(local_relative_position.z))
	
	var total_control := Vector3.ZERO
	for axis_config : AeroInfluencerControlAxisConfig in axis_configs:
		total_control += get_value_safe(axis_config, aero_influencer, axis_sign)
	
	total_control = total_control.clamp(-Vector3.ONE, Vector3.ONE)
	var desired_control : Vector3 = total_control * AeroMathUtils.max_magnitude(min_value, max_value)
	desired_control = clamp(desired_control, min_value, max_value)
	
	if limit_movement_speed:
		current_value = current_value.move_toward(desired_control, movement_speed * delta)
	else:
		current_value = desired_control
	
	return current_value

static func get_value_safe(axis_config : AeroInfluencerControlAxisConfig, aero_influencer : AeroInfluencer3D, axis_sign : Vector3 = Vector3.ZERO) -> Vector3:
	if axis_config:
		var command : float = aero_influencer.get_control_command(axis_config.axis_name)
		return axis_config.get_value(command, aero_influencer, axis_sign)
	
	return Vector3.ZERO
