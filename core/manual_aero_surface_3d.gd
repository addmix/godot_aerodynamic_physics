extends AeroSurface3D
class_name ManualAeroSurface3D

@export_group("Curves")

@export_subgroup("Angle of attack")

@export var lift_aoa_curve : Curve
@export var drag_aoa_curve : Curve


func _ready() -> void:
	super._ready()
	if lift_aoa_curve == null:
		lift_aoa_curve = load("res://addons/godot_aerodynamic_physics/core/resources/default_lift_aoa_curve.tres")
	if drag_aoa_curve == null:
		drag_aoa_curve = load("res://addons/godot_aerodynamic_physics/core/resources/default_drag_aoa_curve.tres")


func calculate_forces(_world_air_velocity : Vector3, _air_density : float, _air_pressure : float, _relative_position : Vector3, _altitude : float) -> PackedVector3Array:
	super.calculate_forces(_world_air_velocity, _air_density, _air_pressure, _relative_position, _altitude)

	var force := Vector3.ZERO
	var torque := Vector3.ZERO

	var aerodynamic_coefficients : Vector3 = calculate_curve_coefficients()

	var lift : Vector3 = lift_direction * lift_aoa_curve.sample(angle_of_attack / PI / 2.0 + 1.0) * dynamic_pressure * area
	var drag : Vector3 = drag_direction * drag_aoa_curve.sample(angle_of_attack / PI / 2.0 + 1.0) * dynamic_pressure * area * wing_config.drag_at_mach_multiplier_curve.sample(mach / 10.0) * wing_config.sweep_curve.sample(sweep_angle)
	var _torque : Vector3 = global_transform.basis.x * aerodynamic_coefficients.z * dynamic_pressure * area * wing_config.chord

	force = lift + drag
	torque += relative_position.cross(force)
	torque += _torque

	_current_lift = lift
	_current_drag = drag
	_current_torque = torque

	return PackedVector3Array([force, torque])

func calculate_curve_coefficients() -> Vector3:
	var aerodynamic_coefficients : Vector3

	#lift
	aerodynamic_coefficients.x = lift_aoa_curve.sample(angle_of_attack)
	#drag
	aerodynamic_coefficients.y = drag_aoa_curve.sample(angle_of_attack)
	#torque

	return aerodynamic_coefficients
