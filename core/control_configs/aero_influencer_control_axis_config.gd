extends Resource
class_name AeroInfluencerControlAxisConfig

const AeroMathUtils = preload("../../utils/math_utils.gd")
##Amount of rotation that throttle commands contribute to this node's rotation.
@export var contribution := Vector3.ZERO
@export_exp_easing("inout") var easing : float = 1.0

@export_group("Advanced")

@export_subgroup("X")
@export_enum("None", "X", "Y", "Z") var axis_flip_x : int = 0
## Unimplemented
@export var expression_x : String = ""
@export_subgroup("Y")
@export_enum("None", "X", "Y", "Z") var axis_flip_y : int = 0
## Unimplemented
@export var expression_y : String = ""
@export_subgroup("Z")
@export_enum("None", "X", "Y", "Z") var axis_flip_z : int = 0
## Unimplemented
@export var expression_z : String = ""


@export_group("")

func _init(_contribution : Vector3 = Vector3.ZERO) -> void:
	contribution = _contribution

func get_value(command : float, axis_sign : Vector3 = Vector3.ONE) -> Vector3:
	#do some other expression stuff
	return contribution * AeroMathUtils.improved_ease(command, easing) * get_axis_flip(axis_sign)

func get_axis_flip(axis_sign : Vector3 = Vector3.ONE) -> Vector3:
	return Vector3(get_axis_flip_axis(axis_sign, axis_flip_x), get_axis_flip_axis(axis_sign, axis_flip_y), get_axis_flip_axis(axis_sign, axis_flip_z))

static func get_axis_flip_axis(axis_sign : Vector3 = Vector3.ONE, axis : int = 0) -> float:
	match axis:
		1:
			return axis_sign.x
		2:
			return axis_sign.y
		3:
			return axis_sign.z
		
		_:
			return 1.0
