# From https://github.com/addmix/godot_utils
extends Resource
class_name aero_PID

const aeroMathUtils = preload("../utils/math_utils.gd")

@export var p : float = 0.2
@export var i : float = 0.05
@export var d : float = 1.0

@export_category("Clamp Integral")
@export var clamp_integral : bool = false
@export var min_integral : float = -1
@export var max_integral : float = 1
@export_category("")

var output : float = 0

var _last_error : float
var _integral_error : float

var proportional_output : float = 0.0
var integral_output : float = 0.0
var derivative_output : float = 0.0

func _init(_p : float = p, _i : float = i, _d : float = d, _clamp_integral : bool = clamp_integral, _min_integral : float = min_integral, _max_integral : float = max_integral) -> void:
	self.p = _p
	self.i = _i
	self.d = _d
	self.clamp_integral = _clamp_integral
	self.min_integral = _min_integral
	self.max_integral = _max_integral

func update(delta : float, error : float) -> float:
	var derivative : float = (error - _last_error) / delta
	_integral_error += error * delta
	_integral_error = aeroMathUtils.float_toggle(clamp_integral, clamp(_integral_error, min_integral, max_integral), _integral_error)
	_last_error = error
	
	proportional_output = p * error
	integral_output = i * _integral_error
	derivative_output = d * derivative
	
	output = proportional_output + integral_output + derivative_output
	return output
