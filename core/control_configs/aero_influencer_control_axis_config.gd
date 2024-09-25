@tool
extends Resource
class_name AeroInfluencerControlAxisConfig

const AeroMathUtils = preload("../../utils/math_utils.gd")
@export_placeholder("Control axis") var axis_name : String = "":
	set(x):
		axis_name = x
		resource_name = axis_name
##Amount of rotation that throttle commands contribute to this node's rotation.
@export var contribution := Vector3.ZERO
@export_exp_easing("inout") var easing : float = 1.0

func _init(_axis_name : String = "", _contribution : Vector3 = Vector3.ZERO) -> void:
	axis_name = _axis_name
	contribution = _contribution

func get_value(command : float) -> Vector3:
	return contribution * AeroMathUtils.improved_ease(command, easing)
