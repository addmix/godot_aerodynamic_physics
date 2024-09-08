@tool
extends Node
class_name AeroControlComponent

@onready var aero_body : AeroBody3D = get_parent()

@export var flight_assist : FlightAssist
##Control input value read from player controls.
@export var control_input : Vector3 = Vector3.ZERO
var cumulative_control_input : Vector3 = Vector3.ZERO
var control_value : Vector3 = Vector3.ZERO
var control_command := Vector3.ZERO
##Throttle input value read from player controls.
@export var throttle_input : float = 0.0
var cumulative_throttle_input : float = 0.0
var throttle_value : float = 0.0
var throttle_command : float = 0.0
##Brake input value read from player controls.
@export var brake_input : float = 0.0
var cumulative_brake_input : float = 0.0
var brake_value : float = 0.0
var brake_command : float = 0.0

@export_group("Control Limits")
@export_subgroup("Control")
##Minimum control value limit
@export var min_control : Vector3 = -Vector3.ONE
##Maximum control value limit
@export var max_control : Vector3 = Vector3.ONE
@export_subgroup("Throttle")
##Minimum throttle limit
@export var min_throttle : float = 0.0
##Maximum throttle limit
@export var max_throttle : float = 1.0
@export_subgroup("Brakes")
##Minimum brake limit
@export var min_brake : float = 0.0
##Maximum brake limit
@export var max_brake : float = 1.0
@export_subgroup("")

@export_group("Control")
##If enabled, this AeroControlComponent will automatically read player inputs, and apply those inputs to control, throttle, and brake input values.
@export var use_bindings : bool = true

@export_subgroup("Pitch")
##InputMap action which controls pitching up.
@export var pitch_up_event : StringName = "ui_down"
##InputMap action which controls pitching down.
@export var pitch_down_event : StringName = "ui_up"
##If enabled, inputs will change smoothly at `pitch_smoothing_rate` per second.
@export var enable_pitch_smoothing : bool = false
@export var pitch_smoothing_rate : float = 1.0
##Cumulative inputs don't reset to 0 automatically. This would be similar to trim, or throttle that stays in place when not interacted with.
@export var cumulative_pitch_up_event : StringName = ""
##Cumulative inputs don't reset to 0 automatically. This would be similar to trim, or throttle that stays in place when not interacted with.
@export var cumulative_pitch_down_event : StringName = ""
##Rate at which Cumulative inputs change control value.
@export var cumulative_pitch_rate : float = 1.0

@export_subgroup("Yaw")
##InputMap action which controls yawing left.
@export var yaw_left_event : StringName = ""
##InputMap action which controls yawing right.
@export var yaw_right_event : StringName = ""
##If enabled, inputs will change smoothly at `pitch_smoothing_rate` per second.
@export var enable_yaw_smoothing : bool = false
@export var yaw_smoothing_rate : float = 1.0
##Cumulative inputs don't reset to 0 automatically. This would be similar to trim, or throttle that stays in place when not interacted with.
@export var cumulative_yaw_left_event : StringName = ""
##Cumulative inputs don't reset to 0 automatically. This would be similar to trim, or throttle that stays in place when not interacted with.
@export var cumulative_yaw_right_event : StringName = ""
##Rate at which Cumulative inputs change control value.
@export var cumulative_yaw_rate : float = 1.0

@export_subgroup("Roll")
##InputMap action which controls rolling left.
@export var roll_left_event : StringName = "ui_left"
##InputMap action which controls rolling right.
@export var roll_right_event : StringName = "ui_right"
##If enabled, inputs will change smoothly at `pitch_smoothing_rate` per second.
@export var enable_roll_smoothing : bool = false
@export var roll_smoothing_rate : float = 1.0
##Cumulative inputs don't reset to 0 automatically. This would be similar to trim, or throttle that stays in place when not interacted with.
@export var cumulative_roll_left_event : StringName = ""
##Cumulative inputs don't reset to 0 automatically. This would be similar to trim, or throttle that stays in place when not interacted with.
@export var cumulative_roll_right_event : StringName = ""
##Rate at which Cumulative inputs change control value.
@export var cumulative_roll_rate : float = 1.0

@export_subgroup("Throttle")
##InputMap action which controls throttling up.
@export var throttle_up_event : StringName = ""
##InputMap action which controls throttling down.
@export var throttle_down_event : StringName = ""
##If enabled, inputs will change smoothly at `pitch_smoothing_rate` per second.
@export var enable_throttle_smoothing : bool = false
@export var throttle_smoothing_rate : float = 1.0
##Cumulative inputs don't reset to 0 automatically. This would be similar to trim, or throttle that stays in place when not interacted with.
@export var cumulative_throttle_up_event : StringName = ""
##Cumulative inputs don't reset to 0 automatically. This would be similar to trim, or throttle that stays in place when not interacted with.
@export var cumulative_throttle_down_event : StringName = ""
##Rate at which Cumulative inputs change control value.
@export var cumulative_throttle_rate : float = 1.0

@export_subgroup("Brake")
##InputMap action which controls brake increase.
@export var brake_up_event : StringName = ""
##InputMap action which controls brake decrease.
@export var brake_down_event : StringName = ""
##If enabled, inputs will change smoothly at `pitch_smoothing_rate` per second.
@export var enable_brake_smoothing : bool = false
@export var brake_smoothing_rate : float = 1.0
##Cumulative inputs don't reset to 0 automatically. This would be similar to trim, or throttle that stays in place when not interacted with.
@export var cumulative_brake_up_event : StringName = ""
##Cumulative inputs don't reset to 0 automatically. This would be similar to trim, or throttle that stays in place when not interacted with.
@export var cumulative_brake_down_event : StringName = ""
##Rate at which Cumulative inputs change control value.
@export var cumulative_brake_rate : float = 1.0

@export_subgroup("")
@export_group("")

func _ready() -> void:
	#resource_local_to_scene impacts editability in some cases, so we manually duplicate the flight_assist resource.
	if flight_assist and not Engine.is_editor_hint():
		flight_assist = flight_assist.duplicate(true)

func _physics_process(delta : float) -> void:
	if Engine.is_editor_hint():
		return
	
	update_controls(delta)
	update_flight_assist(delta)
	
	#update aerobody controls.
	aero_body.control_command = control_command
	aero_body.throttle_command = throttle_command
	aero_body.brake_command = brake_command

func update_controls(delta : float) -> void:
	if use_bindings:
		control_input.x = get_input(delta, control_input.x, pitch_down_event, pitch_up_event)
		control_input.y = get_input(delta, control_input.y, yaw_right_event, yaw_left_event)
		control_input.z = get_input(delta, control_input.z, roll_right_event, roll_left_event)
		throttle_input = get_input(delta, throttle_input, throttle_down_event, throttle_up_event)
		brake_input = get_input(delta, brake_input, brake_down_event, brake_up_event)
		
		cumulative_control_input.x = update_cumulative_control(delta, cumulative_control_input.x, cumulative_pitch_down_event, cumulative_pitch_up_event, cumulative_pitch_rate, min_control.x, max_control.x)
		cumulative_control_input.y = update_cumulative_control(delta, cumulative_control_input.y, cumulative_yaw_right_event, cumulative_yaw_left_event, cumulative_yaw_rate, min_control.y, max_control.y)
		cumulative_control_input.z = update_cumulative_control(delta, cumulative_control_input.z, cumulative_roll_right_event, cumulative_roll_left_event, cumulative_roll_rate, min_control.z, max_control.z)
		cumulative_throttle_input = update_cumulative_control(delta, cumulative_throttle_input, cumulative_throttle_down_event, cumulative_throttle_up_event, cumulative_throttle_rate, min_throttle, max_throttle)
		cumulative_brake_input = update_cumulative_control(delta, cumulative_brake_input, cumulative_brake_down_event, cumulative_brake_up_event, cumulative_brake_rate, min_brake, max_brake)
	
	control_input = clamp(control_input + cumulative_control_input, min_control, max_control)
	throttle_input = clamp(throttle_input + cumulative_throttle_input, min_throttle, max_throttle)
	brake_input = clamp(brake_input + cumulative_brake_input, min_brake, max_brake)
	
	control_value.x = calculate_smoothing(control_value.x, control_input.x, enable_pitch_smoothing, pitch_smoothing_rate, delta)
	control_value.y = calculate_smoothing(control_value.y, control_input.y, enable_yaw_smoothing, yaw_smoothing_rate, delta)
	control_value.z = calculate_smoothing(control_value.z, control_input.z, enable_roll_smoothing, roll_smoothing_rate, delta)
	throttle_value = calculate_smoothing(throttle_value, throttle_input, enable_throttle_smoothing, throttle_smoothing_rate, delta)
	brake_value = calculate_smoothing(brake_value, brake_input, enable_brake_smoothing, brake_smoothing_rate, delta)

static func update_cumulative_control(delta : float, cumulative_value : float, negative_event : StringName, positive_event : StringName, cumulative_rate : float, min_value : float, max_value : float) -> float:
	var input : float = get_axis(0.0, negative_event, positive_event)
	cumulative_value += input * cumulative_rate * delta
	return clamp(cumulative_value, min_value, max_value)

static func calculate_smoothing(current_value : float, new_value : float, smoothing_enabled : bool = false, smoothing_rate : float = 1.0, delta : float = 1.0/60.0) -> float:
	if smoothing_enabled:
		return move_toward(current_value, new_value, smoothing_rate * delta)
	else:
		return new_value

static func get_input(delta : float, default_value : float, negative_event : StringName, positive_event : StringName) -> float:
	return get_axis(default_value, negative_event, positive_event)

static func get_axis(default_value : float, negative_event : StringName, positive_event : StringName) -> float:
	var input : float = default_value
	
	if not negative_event == "":
		input -= Input.get_action_strength(negative_event)
	if not positive_event == "":
		input += Input.get_action_strength(positive_event)
	
	if not (negative_event == "" or positive_event == ""):
		input -= default_value
	
	return input

func update_flight_assist(delta : float) -> void:
	if not flight_assist:
		return
	
	#input and pids
	flight_assist.control_input = control_value
	flight_assist.throttle_command = throttle_value
	flight_assist.air_speed = aero_body.air_speed
	flight_assist.air_density = aero_body.air_density
	flight_assist.angle_of_attack = aero_body.angle_of_attack
	flight_assist.altitude = aero_body.altitude
	flight_assist.heading = aero_body.heading
	flight_assist.bank_angle = aero_body.bank_angle
	flight_assist.linear_velocity = aero_body.linear_velocity
	flight_assist.local_angular_velocity = aero_body.local_angular_velocity
	flight_assist.global_transform = aero_body.global_transform
	flight_assist.update(delta)
	
	control_command = flight_assist.control_command
	throttle_command = flight_assist.throttle_command
