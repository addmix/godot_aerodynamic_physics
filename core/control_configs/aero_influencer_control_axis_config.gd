extends Resource
class_name AeroInfluencerControlAxisConfig

const AeroMathUtils = preload("../../utils/math_utils.gd")
##Amount of rotation that throttle commands contribute to this node's rotation.
@export var contribution := Vector3.ZERO
@export_exp_easing("inout") var easing : float = 1.0

func _init(_contribution : Vector3 = Vector3.ZERO) -> void:
	contribution = _contribution

func get_value(command : float) -> Vector3:
	return contribution * AeroMathUtils.improved_ease(command, easing)
