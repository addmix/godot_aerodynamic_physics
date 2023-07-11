@tool
extends AeroSurface3D
class_name ManualAeroSurface3D

@export var manual_config := ManualAeroSurfaceConfig.new()

func calculate_forces(_world_air_velocity : Vector3, _air_density : float, _air_pressure : float, _relative_position : Vector3, _altitude : float) -> PackedVector3Array:
	super.calculate_forces(_world_air_velocity, _air_density, _air_pressure, _relative_position, _altitude)

	var force := Vector3.ZERO
	var torque := Vector3.ZERO

	var aero_reference := dynamic_pressure * area

	var lift : float = aero_reference * manual_config.get_lift_coefficient(angle_of_attack)
	var drag_coefficient : float = manual_config.get_drag_coefficient(angle_of_attack) * wing_config.sweep_drag_multiplier_curve.sample(sweep_angle) * wing_config.get_drag_multiplier_at_mach(mach)
	var form_drag : float = aero_reference * drag_coefficient
	var induced_drag : float = (lift * lift) / (dynamic_pressure * PI * wing_config.span * wing_config.span)
	var skin_friction_drag : float = wing_config.skin_friction * dynamic_pressure
	var total_drag = form_drag + induced_drag + skin_friction_drag
#	print("Percentages of total drag:\nSkin friction: %s\nForm drag: %s\nInduced drag: %s" % [skin_friction_drag / total_drag, form_drag / total_drag, induced_drag / total_drag])

#	https://aviation.stackexchange.com/questions/84210/difference-in-lift-generation-for-a-swept-wing-and-straight-wing-in-subsonic-con
#	Since both the lift curve slope and the effective angle of attack are reduced
#	by the cosine of the sweep angle at quarter chord, the lift coefficient of a
#	swept wing at the same geometric angle of attack is reduced by the square of
#	the cosine of the sweep angle.

	var lift_vector : Vector3 = lift_direction * lift
	var drag_vector : Vector3 = drag_direction * total_drag

	#sum of all linear forces
	force = lift_vector + drag_vector
	#resultant torque from linear forces
	torque += relative_position.cross(force)

	#current values for debug
	_current_lift = lift_vector
	_current_drag = drag_vector
	_current_torque = torque

	return PackedVector3Array([force, torque])
