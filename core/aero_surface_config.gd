extends Reference
class_name AeroSurfaceConfig

export var auto_aspect_ratio : bool = true setget set_auto_aspect_ratio
export var aspect_ratio : float = 2.0 setget set_aspect_ratio
export var chord : float = 1.0 setget set_chord
export var flap_angle : float = 0.0 setget set_flap_angle
export var flap_fraction : float = 0.0 setget set_flap_fraction
export var lift_slope : float = 6.28 setget set_lift_slope
export var skin_friction : float = 0.02 setget set_skin_friction
export var span : float = 1.0 setget set_span
export var stall_angle_high : float = 15.0 setget set_stall_angle_high
export var stall_angle_low : float = -15.0 setget set_stall_angle_low
export var zero_lift_aoa : float = 0.0 setget set_zero_lift_aoa

func set_auto_aspect_ratio(value : bool) -> void:
	auto_aspect_ratio = value
	validate()
func set_aspect_ratio(value : float) -> void:
	aspect_ratio = value
	#conserve area?
func set_chord(value : float) -> void:
	chord = max(value, 0.001)
	validate()
func set_flap_angle(angle : float = 0.0) -> void:
	flap_angle = clamp(angle, -deg2rad(50.0), deg2rad(50.0))
func set_flap_fraction(value : float) -> void:
	flap_fraction = clamp(value, 0.0, 0.4)
func set_lift_slope(value : float) -> void:
	lift_slope = value
func set_skin_friction(value : float) -> void:
	skin_friction = value
func set_span(value : float) -> void:
	span = value
	validate()
func set_stall_angle_high(value : float) -> void:
	stall_angle_high = max(value, 0.0)
func set_stall_angle_low(value : float) -> void:
	stall_angle_low = min(value, 0.0)
func set_zero_lift_aoa(value : float) -> void:
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
