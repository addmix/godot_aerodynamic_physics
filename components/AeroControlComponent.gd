extends Node
class_name AeroControlComponent

@onready var aero_body : AeroBody3D = get_parent()

@export var flight_assist : FlightAssist = preload("../core/resources/flight_assist/flight_assist.tres").duplicate()

@export var control_input : Vector3 = Vector3.ZERO
var control_command := Vector3.ZERO
@export var throttle_input : float = 0.0
var throttle_command : float = 0.0
@export var brake_input : float = 0.0
var brake_command : float = 0.0

@export_subgroup("Bindings")
@export var use_bindings : bool = true
@export var pitch_up_event : String = "ui_down"
@export var pitch_down_event : String = "ui_up"
@export var yaw_left_event : String = ""
@export var yaw_right_event : String = ""
@export var roll_left_event : String = "ui_left"
@export var roll_right_event : String = "ui_right"
@export var throttle_up_event : String = ""
@export var throttle_down_event : String = ""
@export var brake_up_event : String = ""
@export var brake_down_event : String = ""
@export_subgroup("")

func _ready() -> void:
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
	if not use_bindings:
		control_command = control_input
		throttle_command = throttle_input
		brake_command = brake_input
		return
	
	#prevent error spam when an axis is unassigned
	var _pitch_input : float = control_input.x
	if not (pitch_up_event == "" or pitch_down_event == ""):
		_pitch_input = Input.get_axis(pitch_down_event, pitch_up_event)
		_pitch_input = clamp(_pitch_input, -1.0, 1.0)
		control_input.x = _pitch_input
	
	var _yaw_input : float = control_input.y
	if not (yaw_left_event == "" or yaw_right_event == ""):
		_yaw_input = Input.get_axis(yaw_right_event, yaw_left_event)
		_yaw_input = clamp(_yaw_input, -1.0, 1.0)
		control_input.y = _yaw_input
	
	var _roll_input : float = control_input.z
	if not (roll_left_event == "" or roll_right_event == ""):
		_roll_input = Input.get_axis(roll_right_event, roll_left_event)
		_roll_input = clamp(_roll_input, -1.0, 1.0)
		control_input.z = _roll_input
	
	var _throttle_input : float = throttle_input
	if not (throttle_up_event == "" or throttle_down_event == ""):
		_throttle_input = Input.get_axis(throttle_down_event, throttle_up_event)
		throttle_input += _throttle_input * delta
		throttle_input = clamp(throttle_input, 0.0, 1.0)
	
	var _brake_input : float = brake_input
	if not (brake_up_event == "" or brake_down_event == ""):
		_brake_input = Input.get_axis(brake_down_event, brake_up_event)
		brake_input += _brake_input * delta
		brake_input = clamp(brake_input, 0.0, 1.0)
	
	control_command = control_input
	throttle_command = throttle_input
	brake_command = brake_input

func update_flight_assist(delta : float) -> void:
	if not flight_assist:
		return
	
	#input and pids
	flight_assist.input = control_input
	flight_assist.throttle = throttle_input
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
	
	control_command = flight_assist.control_value
	throttle_command = flight_assist.throttle

