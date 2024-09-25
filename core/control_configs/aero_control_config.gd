@tool
extends Resource
class_name AeroControlConfig

const AeroMathUtils = preload("../../utils/math_utils.gd")

@export var axis_configs : Array[AeroControlConfigAxis] = []

func _init() -> void:
	axis_configs = [
		AeroControlConfigAxis.new("pitch", -1.0, 1.0, "ui_up", "ui_down"),
		AeroControlConfigAxis.new("yaw"),
		AeroControlConfigAxis.new("roll", -1.0, 1.0, "ui_left", "ui_right"),
		AeroControlConfigAxis.new("throttle", 0.0, 1.0),
		AeroControlConfigAxis.new("brake", 0.0, 1.0),
		AeroControlConfigAxis.new("collective"),
	]

func update(delta : float) -> void:
	for config : AeroControlConfigAxis in axis_configs:
		config.update(delta)

func set_control_command(axis_name : String = "", value : float = 0.0) -> void:
	var axis := get_axis_config_with_name(axis_name)
	if axis:
		axis.command = value

func get_control_command(axis_name : String = "") -> float:
	var axis := get_axis_config_with_name(axis_name)
	if axis:
		#if axis_name == "throttle":
			#print(axis.command)
		return axis.command
	return 0.0

func set_control_input(axis_name : String = "", value : float = 0.0) -> void:
	var axis := get_axis_config_with_name(axis_name)
	if axis:
		axis.input = value

func get_control_input(axis_name : String = "") -> float:
	var axis := get_axis_config_with_name(axis_name)
	if axis:
		return axis.input
	return 0.0

func get_axis_config_with_name(name : String = "") -> AeroControlConfigAxis:
	for config : AeroControlConfigAxis in axis_configs:
		if config.axis_name == name:
			return config
	#can't find axis with name
	return null
