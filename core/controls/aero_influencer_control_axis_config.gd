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

@export_group("Advanced")

@export_subgroup("X")
@export_enum("None", "X", "Y", "Z") var axis_flip_x : int = 0
@export var expression_x : String = "":
	set(x):
		expression_x = x
		if Engine.is_editor_hint() or expression_x == "":
			return
		
		var error := exp_x.parse(expression_x)
		if not error == OK:
			print(exp_x.get_error_text())
var exp_x := Expression.new()
@export_subgroup("Y")
@export_enum("None", "X", "Y", "Z") var axis_flip_y : int = 0
@export var expression_y : String = "":
	set(x):
		expression_y = x
		if Engine.is_editor_hint() or expression_y == "":
			return
		
		var error := exp_y.parse(expression_y)
		if not error == OK:
			print(exp_y.get_error_text())
var exp_y := Expression.new()
@export_subgroup("Z")
@export_enum("None", "X", "Y", "Z") var axis_flip_z : int = 0
@export var expression_z : String = "":
	set(x):
		expression_z = x
		if Engine.is_editor_hint() or expression_z == "":
			return
		
		var error := exp_z.parse(expression_z)
		if not error == OK:
			print(exp_z.get_error_text())
var exp_z := Expression.new()


@export_group("")

func _init(_axis_name : String = "", _contribution : Vector3 = Vector3.ZERO) -> void:
	axis_name = _axis_name
	contribution = _contribution

func get_value(command : float, aero_influencer : AeroInfluencer3D, axis_sign : Vector3 = Vector3.ONE) -> Vector3:
	var running_contribution := contribution
	if not expression_x == "":
		running_contribution.x = exp_x.execute([], aero_influencer)
	if not expression_y == "":
		running_contribution.y = exp_y.execute([], aero_influencer)
	if not expression_z == "":
		running_contribution.z = exp_z.execute([], aero_influencer)
	
	return running_contribution * AeroMathUtils.improved_ease(command, easing) * get_axis_flip(axis_sign)

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
