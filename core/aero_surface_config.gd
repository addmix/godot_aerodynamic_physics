extends Resource
class_name AeroSurfaceConfig

@export var auto_aspect_ratio : bool = true :
	set(value):
		auto_aspect_ratio = value
		validate()
@export var aspect_ratio : float = 2.0 :
	set(value):
		aspect_ratio = value
@export var chord : float = 1.0 : 
	set(value):
		chord = max(value, 0.001)
		validate()
@export var flap_angle : float = 0.0 :
	set(value):
		flap_angle = clamp(value, -deg_to_rad(50.0), deg_to_rad(50.0))
@export var flap_fraction : float = 0.0 :
	set(value):
		flap_fraction = clamp(value, 0.0, 0.4)
@export var lift_slope : float = 6.28 :
	set(value):
		lift_slope = value
@export var skin_friction : float = 0.02 :
	set(value):
		skin_friction = value
@export var span : float = 1.0 :
	set(value):
		span = value
		validate()
@export var stall_angle_high : float = 15.0 :
	set(value):
		stall_angle_high = max(value, 0.0)
@export var stall_angle_low : float = -15.0 :
	set(value):
		stall_angle_low = min(value, 0.0)
@export var zero_lift_aoa : float = 0.0 :
	set(value):
		zero_lift_aoa = value

func _init(_lift_slope : float, _skin_friction : float, _zero_lift_aoa : float, _stall_angle_high : float, _stall_angle_low : float, _chord : float, _flap_fraction : float, _span : float, _auto_aspect_ratio : bool, _aspect_ratio : float) -> void:
	lift_slope = _lift_slope
	skin_friction = _skin_friction
	zero_lift_aoa = _zero_lift_aoa
	stall_angle_high = _stall_angle_high
	stall_angle_low = _stall_angle_low
	chord = _chord
	flap_fraction = _flap_fraction
	span = _span
	auto_aspect_ratio = _auto_aspect_ratio
	aspect_ratio = _aspect_ratio
	
	validate()

func validate() -> void:
	#optimize out
	if auto_aspect_ratio:
		aspect_ratio = span / chord
