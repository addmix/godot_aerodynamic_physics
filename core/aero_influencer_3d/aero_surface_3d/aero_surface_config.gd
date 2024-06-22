@tool
extends Resource
class_name AeroSurfaceConfig

@export_group("Wing profile")
##Represents the length of the AeroSurface3D on the Z axis.
@export var chord : float = 1.0:
	set(value):
		chord = max(value, 0.001)
		if auto_aspect_ratio:
			aspect_ratio = span / chord
		emit_changed()
##Represents the width of the AeroSurface3D on the X axis.
@export var span : float = 2.0:
	set(value):
		span = value
		if auto_aspect_ratio:
			aspect_ratio = span / chord
		emit_changed()
##Parasitic drag coefficient.
@export var skin_friction : float = 0.02 :
	set(value):
		skin_friction = value
		emit_changed()
##If enabled, span or chord will be modified to maintain the given aspect ratio.
@export var auto_aspect_ratio : bool = true:
	set(value):
		auto_aspect_ratio = value
		if auto_aspect_ratio:
			aspect_ratio = span / chord
		emit_changed()
##Aspect ratio of the AeroSurface. This is the ratio of span and chord.
@export var aspect_ratio : float = 2.0:
	set(value):
		aspect_ratio = value
		if !auto_aspect_ratio:
			#keep area
			var current_area : float = span * chord
		emit_changed()
##Angle of attack (degrees) where AeroSurface3D experiences no lift force. (Unused)
@export var zero_lift_aoa : float = 0.0:
	set(value):
		zero_lift_aoa = value
		emit_changed()

@export_group("Control")

##Amount of the AeroSurface3D that is used as a control surface (flap). (Unused)
@export var flap_fraction : float = 0.0:
	set(value):
		flap_fraction = clamp(value, 0.0, 0.4)
		emit_changed()
##If enabled, AeroSurface3D is used as a control surface (flap). (Unused)
@export var is_control_surface : bool = false:
	set(value):
		is_control_surface = value
		emit_changed()

@export_group("Curves")
##Multiplier curve that modifies drag depending on the sweep angle of the AeroSurface3D.
@export var sweep_drag_multiplier_curve : Curve = preload("../../resources/default_sweep_drag_multiplier.tres"):
	set(value):
		sweep_drag_multiplier_curve = value
		emit_changed()
func get_drag_at_sweep_angle(sweep_angle : float) -> float:
	return sweep_drag_multiplier_curve.sample_baked(abs(sweep_angle / PI))
##Multiplier curve that modifies drag depending on the AeroBody3D's Mach number.
@export var drag_at_mach_multiplier_curve : Curve = preload("../../resources/default_drag_at_mach_curve.tres"):
	set(value):
		drag_at_mach_multiplier_curve = value
		emit_changed()
func get_drag_multiplier_at_mach(mach : float) -> float:
	return drag_at_mach_multiplier_curve.sample_baked(mach / 10.0)
##Evaluation curve for turbulent movements based on AeroSurface3D's angle of attack. (Unused)
@export var buffet_aoa_curve : Curve:
	set(value):
		buffet_aoa_curve = value
		emit_changed()

@export_group("")

func _init(_chord : float = 1.0, _span : float = 2.0, _skin_friction : float = 0.001, _auto_aspect_ratio : bool = true, _aspect_ratio : float = 2.0, _zero_lift_aoa : float = 0.0, _flap_fraction : float = 0.0, _is_control_surface : bool = false, _sweep_drag_multiplier_curve : Curve = preload("../../resources/default_sweep_drag_multiplier.tres").duplicate(), _drag_at_mach_multiplier_curve : Curve = preload("../../resources/default_drag_at_mach_curve.tres").duplicate(), _buffet_aoa_curve : Curve = Curve.new().duplicate()) -> void:
	chord = _chord
	span = _span
	skin_friction = _skin_friction
	auto_aspect_ratio = _auto_aspect_ratio
	aspect_ratio = _aspect_ratio
	zero_lift_aoa = _zero_lift_aoa

	flap_fraction = _flap_fraction
	is_control_surface = _is_control_surface

	sweep_drag_multiplier_curve = _sweep_drag_multiplier_curve
	drag_at_mach_multiplier_curve = _drag_at_mach_multiplier_curve
	buffet_aoa_curve = _buffet_aoa_curve

	if sweep_drag_multiplier_curve == null:
		sweep_drag_multiplier_curve = preload("../../resources/default_sweep_drag_multiplier.tres").duplicate()
	if drag_at_mach_multiplier_curve == null:
		drag_at_mach_multiplier_curve = preload("../../resources/default_drag_at_mach_curve.tres").duplicate()
