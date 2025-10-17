@tool
extends AeroSurface3D
class_name ManualAeroSurface3D

##Config resource used to define the aerodynamic profile of the ManualAeroSurface3D. This includes lift-aoa and drag-aoa evaluation curves.
@export var manual_config := ManualAeroSurfaceConfig.new()

func _calculate_forces(substep_delta : float = 0.0) -> PackedVector3Array:
	var force_and_torque : PackedVector3Array = super._calculate_forces(substep_delta)
	
	lift_force = aero_reference * manual_config.get_lift_coefficient(angle_of_attack)
	var drag_coefficient : float = manual_config.get_drag_coefficient(angle_of_attack) * manual_config.get_drag_at_sweep_angle(sweep_angle) * manual_config.get_drag_multiplier_at_mach(mach)
	var form_drag : float = aero_reference * drag_coefficient
	var induced_drag : float = (lift_force * lift_force) / (dynamic_pressure * PI * wing_config.span * wing_config.span) if not wing_config.span == 0.0 else 0.0
	
	
	#dynamic pressure causes divide by zero when airspeed is 0, which results in NAN.
	if is_equal_approx(air_speed, 0.0):
		induced_drag = 0.0
	
	drag_force = form_drag + induced_drag
#	print("Percentages of total drag:\nSkin friction: %s\nForm drag: %s\nInduced drag: %s" % [skin_friction_drag / total_drag, form_drag / total_drag, induced_drag / total_drag])
	
#	https://aviation.stackexchange.com/questions/84210/difference-in-lift-generation-for-a-swept-wing-and-straight-wing-in-subsonic-con
#	Since both the lift curve slope and the effective angle of attack are reduced
#	by the cosine of the sweep angle at quarter chord, the lift coefficient of a
#	swept wing at the same geometric angle of attack is reduced by the square of
#	the cosine of the sweep angle.
	
	var lift_vector : Vector3 = lift_direction * lift_force
	var drag_vector : Vector3 = drag_direction * drag_force
	
	#sum of all linear forces
	_current_force = lift_vector + drag_vector
	#resultant torque from linear forces
	_current_torque += relative_position.cross(_current_force)
	
	return PackedVector3Array([force_and_torque[0] + _current_force, force_and_torque[1] + _current_torque])
