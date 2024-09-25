@tool
extends Resource
class_name ManualAeroSurfaceConfig

##Lift coefficient used where the lift_aoa_curve has a value of -1.
@export_range(0.0, 100.0, 0.001, "or_greater", "exp", "suffix:cL") var min_lift_coefficient : float = -2.0
##Lift coefficient used where the lift_aoa_curve has a value of 1.
@export_range(0.0, 100.0, 0.001, "or_greater", "exp", "suffix:cL") var max_lift_coefficient : float = 2.0
##Curve that determines the ManualAeroSurface3D's lift coefficient, depending on the ManualAeroSurface3D's angle of attack.
@export var lift_aoa_curve : Curve = preload("../../../resources/default_lift_aoa_curve.tres").duplicate()
##Drag coefficient used where the drag_aoa_curve has a value of 0.
@export_range(0.0, 100.0, 0.001, "or_greater", "exp", "suffix:cD") var min_drag_coefficient : float = 0.0
##Drag coefficient used where the drag_aoa_curve has a value of 1.
@export_range(0.0, 100.0, 0.001, "or_greater", "exp", "suffix:cD") var max_drag_coefficient : float = 1.0
@export var drag_aoa_curve : Curve = preload("../../../resources/default_drag_aoa_curve.tres").duplicate()
##Multiplier curve that modifies drag depending on the sweep angle of the AeroSurface3D.
@export var sweep_drag_multiplier_curve : Curve = preload("../../../resources/default_sweep_drag_multiplier.tres").duplicate()
func get_drag_at_sweep_angle(sweep_angle : float) -> float:
	return sweep_drag_multiplier_curve.sample_baked(abs(sweep_angle / PI))
##Multiplier curve that modifies drag depending on the AeroBody3D's Mach number.
@export var drag_at_mach_multiplier_curve : Curve = preload("../../../resources/default_drag_at_mach_curve.tres").duplicate()
func get_drag_multiplier_at_mach(mach : float) -> float:
	return drag_at_mach_multiplier_curve.sample_baked(mach / 10.0)
##Evaluation curve for turbulent movements based on AeroSurface3D's angle of attack. (Unused)
@export var buffet_aoa_curve : Curve #unused

const MathUtils = preload("../../../../utils/math_utils.gd")

func get_lift_coefficient(aoa : float) -> float:
	var sample : float = lift_aoa_curve.sample_baked(aoa / PI / 2.0 + 0.5)
	return sample * MathUtils.float_toggle(sign(sample) == 1.0, max_lift_coefficient, abs(min_lift_coefficient))

func get_drag_coefficient(aoa : float) -> float:
	return remap(drag_aoa_curve.sample_baked(aoa / PI / 2.0 + 0.5), 0, 1, min_drag_coefficient, max_drag_coefficient)
