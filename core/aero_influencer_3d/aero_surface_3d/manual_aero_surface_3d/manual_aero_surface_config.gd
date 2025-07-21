@tool
extends Resource
class_name ManualAeroSurfaceConfig

##Lift coefficient used where the lift_aoa_curve has a value of -1.
@export_range(-100.0, 0.0, 0.001, "or_greater", "exp", "suffix:cL") var min_lift_coefficient : float = -1.6
##Lift coefficient used where the lift_aoa_curve has a value of 1.
@export_range(0.0, 100.0, 0.001, "or_greater", "exp", "suffix:cL") var max_lift_coefficient : float = 1.6
##Curve that determines the ManualAeroSurface3D's lift coefficient, depending on the ManualAeroSurface3D's angle of attack.
@export var lift_aoa_curve : Curve = preload("../../../resources/default_lift_aoa_curve.tres").duplicate()
##Drag coefficient used where the drag_aoa_curve has a value of 0.
@export_range(0.0, 100.0, 0.001, "or_greater", "exp", "suffix:cD") var min_drag_coefficient : float = 0.02
##Drag coefficient used where the drag_aoa_curve has a value of 1.
@export_range(0.0, 100.0, 0.001, "or_greater", "exp", "suffix:cD") var max_drag_coefficient : float = 0.8
##Curve that determines the ManualAeroSurface3D's drag coefficient, depending on the ManualAeroSurface3D's angle of attack.
@export var drag_aoa_curve : Curve = preload("../../../resources/default_drag_aoa_curve.tres").duplicate()
##Multiplier curve that modifies drag depending on the sweep angle of the AeroSurface3D.
@export var sweep_drag_multiplier_curve : Curve = preload("../../../resources/default_sweep_drag_multiplier.tres").duplicate()
func get_drag_at_sweep_angle(sweep_angle : float) -> float:
	return sweep_drag_multiplier_curve.sample_baked(abs(remap(sweep_angle, 0.0, PI, sweep_drag_multiplier_curve.min_domain, sweep_drag_multiplier_curve.max_domain)))
##Multiplier curve that modifies drag depending on the AeroBody3D's Mach number.
@export var drag_at_mach_multiplier_curve : Curve = preload("../../../resources/default_drag_at_mach_curve.tres").duplicate()
func get_drag_multiplier_at_mach(mach : float) -> float:
	return drag_at_mach_multiplier_curve.sample_baked(mach)
##Evaluation curve for turbulent movements based on AeroSurface3D's angle of attack. (Unused)
#@export var buffet_aoa_curve : Curve #unused

const MathUtils = preload("../../../../utils/math_utils.gd")

func get_lift_coefficient(aoa : float) -> float:
	var sample : float = lift_aoa_curve.sample_baked(remap(aoa, -PI, PI, lift_aoa_curve.min_domain, lift_aoa_curve.max_domain))
	return sample * MathUtils.float_toggle(sign(sample) == 1.0, max_lift_coefficient / lift_aoa_curve.max_value, abs(min_lift_coefficient / lift_aoa_curve.min_value))

func get_drag_coefficient(aoa : float) -> float:
	var sample : float = drag_aoa_curve.sample_baked(remap(aoa, -PI, PI, drag_aoa_curve.min_domain, drag_aoa_curve.max_domain))
	return remap(sample, drag_aoa_curve.min_value, drag_aoa_curve.max_value, min_drag_coefficient, max_drag_coefficient)
