extends Resource
class_name AeroInfluencerControlConfig

const AeroMathUtils = preload("../../utils/math_utils.gd")

##If enabled, this AeroInfluencer3D node will automatically rotate to accommodate control inputs.
@export var enable_control : bool = true
@export var axis_configs : Array[AeroInfluencerControlAxisConfig] = []
#X = pitch, Y = yaw, Z = roll
@export_subgroup("Limits")
var current_value := Vector3.ZERO
#@export var min_value := Vector3.ZERO
## Maximum rotation (in radians) this AeroInfluencer can rotate for controls.
@export var max_value := Vector3.ZERO
@export var limit_movement_speed : bool = false
@export var movement_speed : float = 1.0
@export_subgroup("")


func _init() -> void:
	axis_configs = [
		AeroInfluencerControlAxisConfig.new()
	]

func update(delta : float, aero_influencer : AeroInfluencer3D) -> Vector3:
	if not enable_control:
		return current_value
	
	var total_control := Vector3.ZERO
	for axis_config : AeroInfluencerControlAxisConfig in axis_configs:
		total_control += get_value_safe(axis_config, aero_influencer)
	total_control = total_control.clamp(-Vector3.ONE, Vector3.ONE)
	var desired_control : Vector3 = total_control * max_value
	
	if limit_movement_speed:
		current_value = current_value.move_toward(desired_control, movement_speed * delta)
	else:
		current_value = desired_control
	
	return current_value

static func get_value_safe(axis_config : AeroInfluencerControlAxisConfig, aero_influencer : AeroInfluencer3D) -> Vector3:
	if axis_config:
		var command : float = aero_influencer.get_control_command(axis_config.axis_name)
		#if axis_config.axis_name == "throttle":
			#print(command)
		
		return axis_config.get_value(command)
	
	return Vector3.ZERO
