@tool
extends Resource
class_name ManualAeroSurfaceConfig

@export var min_lift_coefficient : float = -1.0
@export var max_lift_coefficient : float = 1.0
@export var lift_aoa_curve : Curve
@export var min_drag_coefficient : float = 0.0
@export var max_drag_coefficient : float = 1.0
@export var drag_aoa_curve : Curve

func _init(_lift_aoa_curve : Curve = load("res://addons/godot_aerodynamic_physics/core/resources/default_lift_aoa_curve.tres").duplicate(), _drag_aoa_curve : Curve = load("res://addons/godot_aerodynamic_physics/core/resources/default_drag_aoa_curve.tres").duplicate()) -> void:
	lift_aoa_curve = _lift_aoa_curve
	drag_aoa_curve = _drag_aoa_curve

	if lift_aoa_curve == null:
		lift_aoa_curve = load("res://addons/godot_aerodynamic_physics/core/resources/default_lift_aoa_curve.tres").duplicate()
	if drag_aoa_curve == null:
		drag_aoa_curve = load("res://addons/godot_aerodynamic_physics/core/resources/default_drag_aoa_curve.tres").duplicate()

func get_lift_coefficient(aoa : float) -> float:
	return remap(lift_aoa_curve.sample(aoa / PI / 2.0 + 0.5), -1, 1, min_lift_coefficient, max_lift_coefficient)

func get_drag_coefficient(aoa : float) -> float:
	return remap(drag_aoa_curve.sample(aoa / PI / 2.0 + 0.5), 0, 1, min_drag_coefficient, max_drag_coefficient)
