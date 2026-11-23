# From https://github.com/addmix/godot_utils
@tool
extends Resource
class_name aero_PID

const aeroMathUtils = preload("../utils/math_utils.gd")

## A Resource class used to calculate PID control responses. [br]
## Resources behave as shared instances. For most cases, be sure that PID resources have [code]local_to_scene[/code] set to true, or creating and assigning a duplicate (example: inside _init() or _ready() [code]pid = pid.duplicate()[/code])

## Proportional gain. (Applies a factor based on the error magnitude.)
@export var p : float = 1.0:
	set(value):
		p = value
		emit_changed()
## Integral gain. (Applies a factor based on the sum of the error over time.)
@export var i : float = 0.0:
	set(value):
		i = value
		emit_changed()
## Derivative gain. (Applies a factor based on the measured velocity of the error.)
@export var d : float = 0.0:
	set(value):
		d = value
		emit_changed()

@export_category("Clamp Integral")
## If true, [code]_integral_error[/code] is clamped between [code]min_integral[/code] and [code]max_integral[/code]
@export var clamp_integral : bool = false:
	set(value):
		clamp_integral = value
		emit_changed()
## The minimum value used when [code]clamp_integral[/code] is enabled.
@export var min_integral : float = -1:
	set(value):
		min_integral = value
		emit_changed()
## The maximum value used when [code]clamp_integral[/code] is enabled.
@export var max_integral : float = 1:
	set(value):
		max_integral = value
		emit_changed()
@export_category("")

## The output value of the PID algorithm. This value is also returned by [code]update()[/code]. [br]
var output : float = 0

## The error measured during the last call to [code]update()[/code]
var _last_error : float
## Sum of error over time. (see: [code]clamp_integral[/code])
var _integral_error : float

## Proportional output component of the PID. Equal to [code]p * error[/code]
var proportional_output : float = 0.0
## Integral output component of the PID. Equal to [code]i * _integral_error[/code]
var integral_output : float = 0.0
## Derivative output component of the PID. Equal to [code]d * error velocity[/code]
var derivative_output : float = 0.0

func _init(_p : float = p, _i : float = i, _d : float = d) -> void:
	self.p = _p
	self.i = _i
	self.d = _d

## Updates the PID and returns a corrective input. [br]
## This does not have to be called every frame, however [code]delta[/code] must be the time elapsed since the last call. [br]
## [code]error[/code] is the error that is trying to be corrected. 
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
