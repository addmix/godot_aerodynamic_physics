@tool
extends Node
class_name AeroControlComponent
## Component that provides high-level input and control mapping features for the [AeroBody3D].


## Include for the AeroMathUtils library.
const AeroMathUtils = preload("../utils/math_utils.gd")

## Reference to the parent [AeroBody3D].
@onready var aero_body : AeroBody3D = get_parent()
## FlightAssist resource used to configure flight assist features.
@export var flight_assist : FlightAssist
## Control configuration resource used to define control axes and key bindings.
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

## Used internally to update the FlightAssist resource, and receive the resulting control command.
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

## Can be used to inject inputs into the control system. Any value set here will go through the
## input system where smoothing, easing, and other effects are applied.[br]
## In-game control methods (like in-game throttle or control sticks) should use this function
## to interface with the control system, while retaining features such as FlightAssist.
func set_control_input(axis_name : String = "", value : float = 0.0) -> void:
	control_config.set_control_input(axis_name, value)

## Returns the control input of the given axis before any modifications have been applied.
func get_control_input(axis_name : String = "") -> float:
	return control_config.get_control_input(axis_name)

## Used to set the final control value. This is used for systems like FlightAssist that might need 
## to modify the controls.
func set_control_command(axis_name : String = "", value : float = 0.0) -> void:
	control_config.set_control_command(axis_name, value)

## Used to get the final control value, after modifications have been applied. This is the value 
## used by AeroInfluencer3Ds for controls.
func get_control_command(axis_name : String = "") -> float:
	if control_config:
		#if axis_name == "throttle":
			#print(control_config.get_control_command(axis_name))
		return control_config.get_control_command(axis_name)
	return 0.0
