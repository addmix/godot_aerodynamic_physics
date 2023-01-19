@tool
extends Resource
class_name ManualAeroSurfaceConfig

@export var lift_aoa_curve : Curve
@export var drag_aoa_curve : Curve

func _init(_lift_aoa_curve : Curve = load("res://addons/godot_aerodynamic_physics/core/resources/default_lift_aoa_curve.tres").duplicate(), _drag_aoa_curve : Curve = load("res://addons/godot_aerodynamic_physics/core/resources/default_drag_aoa_curve.tres").duplicate()) -> void:
	lift_aoa_curve = _lift_aoa_curve
	drag_aoa_curve = _drag_aoa_curve

	if lift_aoa_curve == null:
		lift_aoa_curve = load("res://addons/godot_aerodynamic_physics/core/resources/default_lift_aoa_curve.tres").duplicate()
	if drag_aoa_curve == null:
		drag_aoa_curve = load("res://addons/godot_aerodynamic_physics/core/resources/default_drag_aoa_curve.tres").duplicate()
