@tool
extends Resource
class_name ManualAeroSurfaceConfig

@export var min_lift_coefficient : float = -1.0
@export var max_lift_coefficient : float = 1.0
@export var lift_aoa_curve : Curve = preload("../../../resources/default_lift_aoa_curve.tres")
@export var min_drag_coefficient : float = 0.0
@export var max_drag_coefficient : float = 1.0
@export var drag_aoa_curve : Curve = preload("../../../resources/default_drag_aoa_curve.tres")

const MathUtils = preload("../../../../utils/math_utils.gd")

func _init(_lift_aoa_curve : Curve = null, _drag_aoa_curve : Curve = null) -> void:
	if _lift_aoa_curve:
		lift_aoa_curve = _lift_aoa_curve
	if _drag_aoa_curve:
		drag_aoa_curve = _drag_aoa_curve

	if lift_aoa_curve == null:
		lift_aoa_curve = preload("../../../resources/default_lift_aoa_curve.tres").duplicate()
	if drag_aoa_curve == null:
		drag_aoa_curve = preload("../../../resources/default_drag_aoa_curve.tres").duplicate()

func get_lift_coefficient(aoa : float) -> float:
	var sample : float = lift_aoa_curve.sample_baked(aoa / PI / 2.0 + 0.5)
	return sample * MathUtils.float_toggle(sign(sample) == 1.0, max_lift_coefficient, abs(min_lift_coefficient))

func get_drag_coefficient(aoa : float) -> float:
	return remap(drag_aoa_curve.sample_baked(aoa / PI / 2.0 + 0.5), 0, 1, min_drag_coefficient, max_drag_coefficient)
