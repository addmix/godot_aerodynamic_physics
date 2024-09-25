extends Resource
class_name AeroInfluencerControlConfig

const AeroMathUtils = preload("../../utils/math_utils.gd")

var pitch_command : float = 0.0
var yaw_command : float = 0.0
var roll_command : float = 0.0
var brake_command : float = 0.0
var throttle_command : float = 0.0
var collective_command : float = 0.0

##If enabled, this AeroInfluencer3D node will automatically rotate to accommodate control inputs.
@export var enable_control : bool = true
#X = pitch, Y = yaw, Z = roll

@export_subgroup("Limits")
var current_value := Vector3.ZERO

#@export var min_value := Vector3.ZERO
## Maximum rotation (in radians) this AeroInfluencer can rotate for controls.
@export var max_value := Vector3.ZERO
@export var limit_movement_speed : bool = false
@export var movement_speed : float = 1.0

@export_subgroup("Axis Configs")
@export var pitch_config : AeroInfluencerControlAxisConfig
@export var yaw_config : AeroInfluencerControlAxisConfig
@export var roll_config : AeroInfluencerControlAxisConfig
@export var brake_config : AeroInfluencerControlAxisConfig
@export var throttle_config : AeroInfluencerControlAxisConfig
@export var collective_config : AeroInfluencerControlAxisConfig

func update(delta : float) -> Vector3:
	if not enable_control:
		return current_value
	
	var pitch : Vector3 = get_value_safe(pitch_config, pitch_command)
	var yaw : Vector3 = get_value_safe(yaw_config, yaw_command)
	var roll : Vector3 = get_value_safe(roll_config, roll_command)
	var brake : Vector3 = get_value_safe(brake_config, brake_command)
	var throttle : Vector3 = get_value_safe(throttle_config, throttle_command)
	var collective : Vector3 = get_value_safe(collective_config, collective_command)
	
	var total_control : Vector3 = pitch + yaw + roll + brake + throttle + collective
	total_control = total_control.clamp(-Vector3.ONE, Vector3.ONE)
	var desired_control : Vector3 = total_control * max_value
	
	if limit_movement_speed:
		current_value = current_value.move_toward(desired_control, movement_speed * delta)
	else:
		current_value = desired_control
	
	return current_value

static func get_value_safe(axis_config : AeroInfluencerControlAxisConfig, command : float = 0.0) -> Vector3:
	if axis_config:
		return axis_config.get_value(command)
	return Vector3.ZERO
