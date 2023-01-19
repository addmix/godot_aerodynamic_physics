@tool
extends AeroSurface3D
class_name ManualAeroSurface3D

@export var manual_config := ManualAeroSurfaceConfig.new()

func calculate_forces(_world_air_velocity : Vector3, _air_density : float, _air_pressure : float, _relative_position : Vector3, _altitude : float) -> PackedVector3Array:
	super.calculate_forces(_world_air_velocity, _air_density, _air_pressure, _relative_position, _altitude)

	var force := Vector3.ZERO
	var torque := Vector3.ZERO

	var aerodynamic_coefficients : Vector3 = calculate_curve_coefficients()
	var lift : float = manual_config.lift_aoa_curve.sample(angle_of_attack / PI / 2.0 + 0.5) * dynamic_pressure * projected_wing_area * sign(angle_of_attack)
	var form_drag : float = manual_config.drag_aoa_curve.sample(angle_of_attack / PI / 2.0 + 0.5) * dynamic_pressure * projected_wing_area  * wing_config.drag_at_mach_multiplier_curve.sample(mach / 10.0) * wing_config.sweep_drag_multiplier_curve.sample(sweep_angle)
	var induced_drag : float = lift * lift / (0.5 * dynamic_pressure * PI * wing_config.span * wing_config.span)
#	this still needs a lot of work. Reynolds number is relevant here
#	https://en.wikipedia.org/wiki/Skin_friction_drag
	var skin_friction_drag : float = wing_config.skin_friction * dynamic_pressure



	var _torque : Vector3 = global_transform.basis.x * aerodynamic_coefficients.z * dynamic_pressure * area * wing_config.chord


	var total_drag = form_drag + induced_drag + skin_friction_drag
#	print("Percentages of total drag:\nSkin friction: %s\nForm drag: %s\nInduced drag: %s" % [skin_friction_drag / total_drag, form_drag / total_drag, induced_drag / total_drag])

	var lift_vector : Vector3 = lift * lift_direction
	var drag_vector : Vector3 = drag_direction * (form_drag + induced_drag + skin_friction_drag)

	force = lift_vector + drag_vector
	torque += relative_position.cross(force)
	torque += _torque

	_current_lift = lift_vector
	_current_drag = drag_vector
	_current_torque = torque

	return PackedVector3Array([force, torque])

func calculate_curve_coefficients() -> Vector3:
	var aerodynamic_coefficients : Vector3

	#lift
	aerodynamic_coefficients.x = manual_config.lift_aoa_curve.sample(angle_of_attack)
	#drag
	aerodynamic_coefficients.y = manual_config.drag_aoa_curve.sample(angle_of_attack)
	#torque

	return aerodynamic_coefficients
