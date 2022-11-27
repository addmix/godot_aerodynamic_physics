extends Resource
class_name AeroSurfaceConfig


@export_group("Wing Properties")


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


@export_group("Curves")


@export var use_curves : bool = false

#@export_subgroup("Angle of attack")
#
#@export var lift_aoa_curve : Curve
#@export var drag_aoa_curve : Curve
#@export var buffet_aoa_curve : Curve

@export_subgroup("Sweep")
@export var sweep_curve := Curve.new()

@export var drag_at_mach_multiplier_curve := Curve.new()
func get_drag_multiplier_at_mach(mach : float) -> float:
	var lerp : float = AeroUnits.range_to_lerp(mach, AeroUnits.min_mach, AeroUnits.max_mach)
	return drag_at_mach_multiplier_curve.sample(lerp)

@export_group("")

func validate() -> void:
	#optimize out
	if auto_aspect_ratio:
		aspect_ratio = span / chord
