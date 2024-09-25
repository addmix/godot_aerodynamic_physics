@tool
extends Resource
class_name AeroControlConfig

const AeroMathUtils = preload("../../utils/math_utils.gd")


## If enabled, this AeroControlComponent will read player inputs
@export var use_bindings : bool = true
## Control input value read from player controls.
@export var input : float = 0.0
var command : float = 0.0
var cumulative_input : float = 0.0
var cumulative_command : float = 0.0

@export_category("Limits")
## Minimum control limit
@export var min_limit : float = -1.0
## Maximum control limit
@export var max_limit : float = 1.0

## InputMap action for positive control.
@export var positive_event : StringName = ""
## InputMap action for negative control.
@export var negative_event : StringName = ""
## If enabled, input will change smoothly at `smoothing_rate` per second.
@export var enable_smoothing : bool = false
@export var smoothing_rate : float = 1.0
## Cumulative inputs don't reset to 0 automatically. This would be similar to trim, or throttle that stays in place when not interacted with.
@export var cumulative_positive_event : StringName = ""
## Cumulative inputs don't reset to 0 automatically. This would be similar to trim, or throttle that stays in place when not interacted with.
@export var cumulative_negative_event : StringName = ""
## Rate at which cumulative inputs change control value.
@export var cumulative_rate : float = 1.0
@export_exp_easing("inout") var easing := 1.0

@export_subgroup("")
@export_group("")

func _init(_min_limit : float = -1.0, _max_limit : float = 1.0, default_increase_event : StringName = "", default_decrease_event : StringName = "") -> void:
	min_limit = _min_limit
	max_limit = _max_limit
	positive_event = default_increase_event
	negative_event = default_decrease_event
	pass

func update(delta : float) -> float:
	var total_input : float = input + get_axis(negative_event, positive_event)
	var total_cumulative_input : float = cumulative_input + get_axis(cumulative_negative_event, cumulative_positive_event)
	
	cumulative_command = update_cumulative_control(delta, total_cumulative_input, cumulative_command, cumulative_rate, min_limit, max_limit)
	
	var total_desired_command : float = clamp(total_input + cumulative_command, min_limit, max_limit)
	
	#undo easing
	command = AeroMathUtils.improved_ease(command, 1.0 / easing)
	#input smoothing
	command = calculate_smoothing(command, total_desired_command, enable_smoothing, smoothing_rate, delta)
	#add easing
	command = AeroMathUtils.improved_ease(command, easing)
	
	return command

static func update_cumulative_control(delta : float, input : float, current_value : float, cumulative_rate : float = 1.0, min_value : float = -1.0, max_value : float = 1.0) -> float:
	current_value += input * cumulative_rate * delta
	return clamp(current_value, min_value, max_value)

static func calculate_smoothing(current_value : float, target : float, smoothing_enabled : bool = false, smoothing_rate : float = 1.0, delta : float = 1.0/60.0) -> float:
	if smoothing_enabled:
		return move_toward(current_value, target, smoothing_rate * delta)
	else:
		return target

static func get_axis(negative_event : StringName, positive_event : StringName) -> float:
	var input : float = 0.0
	
	if not negative_event == "":
		input -= Input.get_action_strength(negative_event)
	if not positive_event == "":
		input += Input.get_action_strength(positive_event)
	
	return input
