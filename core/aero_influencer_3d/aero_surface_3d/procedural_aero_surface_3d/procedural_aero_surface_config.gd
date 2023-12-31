@tool
extends Resource
#class_name ProceduralAeroSurfaceConfig

@export var stall_angle_high : float = 15.0 :
	set(value):
		stall_angle_high = max(value, 0.0)
		emit_changed()
@export var stall_angle_low : float = -15.0 :
	set(value):
		stall_angle_low = min(value, 0.0)
		emit_changed()
@export var lift_slope : float = 6.28 :
	set(value):
		lift_slope = value
		emit_changed()

func _init(_stall_angle_high : float = 15.0, _stall_angle_low : float = -15.0, _lift_slope : float = 6.28) -> void:
	stall_angle_high = _stall_angle_high
	stall_angle_low = _stall_angle_low
	lift_slope = _lift_slope
