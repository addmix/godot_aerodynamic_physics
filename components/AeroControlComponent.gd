@tool
extends Node
class_name AeroControlComponent

const AeroMathUtils = preload("../utils/math_utils.gd")

@onready var aero_body : AeroBody3D = get_parent()
@export var flight_assist : FlightAssist
@export var control_config : AeroControlConfig = AeroControlConfig.new()

func _ready() -> void:
	#resource_local_to_scene impacts editability in some cases, so we manually duplicate the flight_assist resource.
	if not Engine.is_editor_hint():
		#if proportional_navigation: proportional_navigation = proportional_navigation.duplicate(true)
		if flight_assist:
			flight_assist = flight_assist.duplicate(true)
		
		if control_config:
			control_config = control_config.duplicate(true)

func _physics_process(delta : float) -> void:
	if Engine.is_editor_hint():
		return
	
	control_config.update(delta)
	update_flight_assist(delta)

func update_flight_assist(delta : float) -> void:
	if not flight_assist:
		return
	
	#input and pids
	flight_assist.control_input = Vector3(get_control_command("pitch"), get_control_command("yaw"), get_control_command("roll"))
	flight_assist.throttle_command = get_control_command("throttle")
	flight_assist.air_speed = aero_body.air_speed
	flight_assist.air_density = aero_body.air_density
	flight_assist.angle_of_attack = aero_body.angle_of_attack
	flight_assist.altitude = aero_body.altitude
	flight_assist.heading = aero_body.heading
	flight_assist.bank_angle = aero_body.bank_angle
	flight_assist.inclination = aero_body.inclination
	flight_assist.linear_velocity = aero_body.linear_velocity
	flight_assist.local_angular_velocity = aero_body.local_angular_velocity
	flight_assist.global_transform = aero_body.global_transform
	flight_assist.update(delta)
	
	set_control_command("pitch", flight_assist.control_command.x)
	set_control_command("yaw", flight_assist.control_command.y)
	set_control_command("roll", flight_assist.control_command.z)
	set_control_command("throttle", flight_assist.throttle_command)

func set_control_input(axis_name : String = "", value : float = 0.0) -> void:
	control_config.set_control_input(axis_name, value)

func get_control_input(axis_name : String = "") -> float:
	return control_config.get_control_input(axis_name)

func set_control_command(axis_name : String = "", value : float = 0.0) -> void:
	control_config.set_control_command(axis_name, value)

func get_control_command(axis_name : String = "") -> float:
	if control_config:
		#if axis_name == "throttle":
			#print(control_config.get_control_command(axis_name))
		return control_config.get_control_command(axis_name)
	return 0.0

#func set_control_input(value : Vector3) -> void:
	#pitch_control_config.input = value.x
	#yaw_control_config.input = value.y
	#roll_control_config.input = value.z
#
#func get_control_command() -> Vector3:
	#return Vector3(pitch_control_config.command, yaw_control_config.command, roll_control_config.command)
#
#@onready var updated_properties := get_property_conversion_info()
#func get_property_conversion_info() -> Dictionary:
	##super.get_property_conversion_info().merge()
	#
	#return {
	##input
	#"control_input" : [TYPE_VECTOR3, \
	#func(value) -> void:
		#pitch_control_config.input = value.x
		#yaw_control_config.input = value.y
		#roll_control_config.input = value.z
	#],
#
	#"throttle_input": [TYPE_FLOAT, \
	#func(value) -> void:
		#throttle_control_config.input = value
	#],
#
	#"brake_input": [TYPE_FLOAT, \
	#func(value) -> void:
		#brake_control_config.input = value
	#],
#
	##limits
	#"min_control": [TYPE_VECTOR3],
	#"max_control": [TYPE_VECTOR3],
	#"min_throttle": [TYPE_FLOAT, \
	#func(value) -> void:
		#throttle_control_config.min_limit = value
	#],
	#"max_throttle": [TYPE_FLOAT, \
	#func(value) -> void:
		#throttle_control_config.max_limit = value
	#],
	#"min_brake": [TYPE_FLOAT, \
	#func(value) -> void:
		#brake_control_config.min_limit = value
	#],
	#"max_brake": [TYPE_FLOAT, \
	#func(value) -> void:
		#brake_control_config.max_limit = value
	#],
#
	##bindings
	#"use_bindings": [TYPE_BOOL, \
	#func(value : bool) -> void:
		#pitch_control_config.use_bindings = value
		#yaw_control_config.use_bindings = value
		#roll_control_config.use_bindings = value
		#throttle_control_config.use_bindings = value
		#brake_control_config.use_bindings = value
		#collective_control_config.use_bindings = value
	#],
#
	##pitch control
	#"pitch_up_event": [TYPE_STRING_NAME, \
	#func(value) -> void:
		#pitch_control_config.positive_event = value
	#],
	#"pitch_down_event": [TYPE_STRING_NAME, \
	#func(value) -> void:
		#pitch_control_config.negative_event = value
	#],
	#"enable_pitch_smoothing": [TYPE_BOOL, \
	#func(value) -> void:
		#pitch_control_config.enable_smoothing = value
	#],
	#"pitch_smoothing_rate": [TYPE_FLOAT, \
	#func(value) -> void:
		#pitch_control_config.smoothing_rate = value
	#],
	#"cumulative_pitch_up_event": [TYPE_STRING_NAME, \
	#func(value) -> void:
		#pitch_control_config.cumulative_positive_event = value
	#],
	#"cumulative_pitch_down_event": [TYPE_STRING_NAME, \
	#func(value) -> void:
		#pitch_control_config.cumulative_negative_event = value
	#],
	#"cumulative_pitch_rate": [TYPE_FLOAT, \
	#func(value) -> void:
		#pitch_control_config.cumulative_rate = value
	#],
	#"pitch_easing": [TYPE_FLOAT, \
	#func(value) -> void:
		#pitch_control_config.easing = value
	#],
#
	##yaw control
	#"yaw_left_event": [TYPE_STRING_NAME, \
	#func(value) -> void:
		#yaw_control_config.positive_event = value
	#],
	#"yaw_right_event": [TYPE_STRING_NAME, \
	#func(value) -> void:
		#yaw_control_config.negative_event = value
	#],
	#"enable_yaw_smoothing": [TYPE_BOOL, \
	#func(value) -> void:
		#yaw_control_config.enable_smoothing = value
	#],
	#"yaw_smoothing_rate": [TYPE_FLOAT, \
	#func(value) -> void:
		#yaw_control_config.smoothing_rate = value
	#],
	#"cumulative_yaw_left_event": [TYPE_STRING_NAME, \
	#func(value) -> void:
		#yaw_control_config.cumulative_positive_event = value
	#],
	#"cumulative_yaw_right_event": [TYPE_STRING_NAME, \
	#func(value) -> void:
		#yaw_control_config.cumulative_negative_event = value
	#],
	#"cumulative_yaw_rate": [TYPE_FLOAT, \
	#func(value) -> void:
		#yaw_control_config.cumulative_rate = value
	#],
	#"yaw_easing": [TYPE_FLOAT, \
	#func(value) -> void:
		#yaw_control_config.easing = value
	#],
#
	##roll control
	#"roll_left_event": [TYPE_STRING_NAME, \
	#func(value) -> void:
		#roll_control_config.positive_event = value
	#],
	#"roll_right_event": [TYPE_STRING_NAME, \
	#func(value) -> void:
		#roll_control_config.negative_event = value
	#],
	#"enable_roll_smoothing": [TYPE_BOOL, \
	#func(value) -> void:
		#roll_control_config.enable_smoothing = value
	#],
	#"roll_smoothing_rate": [TYPE_FLOAT, \
	#func(value) -> void:
		#roll_control_config.smoothing_rate = value
	#],
	#"cumulative_roll_left_event": [TYPE_STRING_NAME, \
	#func(value) -> void:
		#roll_control_config.cumulative_positive_event = value
	#],
	#"cumulative_roll_right_event": [TYPE_STRING_NAME, \
	#func(value) -> void:
		#roll_control_config.cumulative_negative_event = value
	#],
	#"cumulative_roll_rate": [TYPE_FLOAT, \
	#func(value) -> void:
		#roll_control_config.cumulative_rate = value
	#],
	#"roll_easing": [TYPE_FLOAT, \
	#func(value) -> void:
		#roll_control_config.easing = value
	#],
#
	##throttle control
	#"throttle_up_event": [TYPE_STRING_NAME, \
	#func(value) -> void:
		#throttle_control_config.positive_event = value
	#],
	#"throttle_down_event": [TYPE_STRING_NAME, \
	#func(value) -> void:
		#throttle_control_config.negative_event = value
	#],
	#"enable_throttle_smoothing": [TYPE_BOOL, \
	#func(value) -> void:
		#throttle_control_config.enable_smoothing = value
	#],
	#"throttle_smoothing_rate": [TYPE_FLOAT, \
	#func(value) -> void:
		#throttle_control_config.smoothing_rate = value
	#],
	#"cumulative_throttle_up_event": [TYPE_STRING_NAME, \
	#func(value) -> void:
		#throttle_control_config.cumulative_positive_event = value
	#],
	#"cumulative_throttle_down_event": [TYPE_STRING_NAME, \
	#func(value) -> void:
		#throttle_control_config.cumulative_negative_event = value
	#],
	#"cumulative_throttle_rate": [TYPE_FLOAT, \
	#func(value) -> void:
		#throttle_control_config.cumulative_rate = value
	#],
	#"throttle_easing": [TYPE_FLOAT, \
	#func(value) -> void:
		#throttle_control_config.easing = value
	#],
#
	##brake control
	#"brake_up_event": [TYPE_STRING_NAME, \
	#func(value) -> void:
		#brake_control_config.positive_event = value
	#],
	#"brake_down_event": [TYPE_STRING_NAME, \
	#func(value) -> void:
		#brake_control_config.negative_event = value
	#],
	#"enable_brake_smoothing": [TYPE_BOOL, \
	#func(value) -> void:
		#brake_control_config.enable_smoothing = value
	#],
	#"brake_smoothing_rate": [TYPE_FLOAT, \
	#func(value) -> void:
		#brake_control_config.smoothing_rate = value
	#],
	#"cumulative_brake_up_event": [TYPE_STRING_NAME, \
	#func(value) -> void:
		#brake_control_config.cumulative_positive_event = value
	#],
	#"cumulative_brake_down_event": [TYPE_STRING_NAME, \
	#func(value) -> void:
		#brake_control_config.cumulative_negative_event = value
	#],
	#"cumulative_brake_rate": [TYPE_FLOAT, \
	#func(value) -> void:
		#brake_control_config.cumulative_rate = value
	#],
	#"brake_easing": [TYPE_FLOAT, \
	#func(value) -> void:
		#brake_control_config.easing = value
	#],
	#}
#
#func _get_property_list() -> Array[Dictionary]:
	#var array : Array[Dictionary] = []
	#
	#for property in updated_properties.keys():
		#var property_info : Array = updated_properties[property]
		#array.append({
			#"name" : property,
			#"type" : property_info[0],
			#"usage" : 0,
		#})
	#
	#return array
#
#func _set(property: StringName, value: Variant) -> bool:
	#if property in updated_properties.keys():
		#var property_info : Array = updated_properties[property]
		#if property_info.size() >= 2:
			#property_info[1].call(value)
		#
		#return true
	#return false
