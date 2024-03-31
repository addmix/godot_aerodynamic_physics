@tool
extends AeroSurface3D
#class_name ProceduralAeroSurface3D

var flap_angle : float = 0.0
#@export var procedural_config = ProceduralAeroSurfaceConfig.new()
var procedural_config #this line is only here to avoid compilation error. This class does not work

func flap_effectiveness_correction(_flap_angle : float = 0.0) -> float:
	return lerp(0.8, 0.4, (rad_to_deg(abs(_flap_angle)) - 10.0) / 50.0)

func lift_coefficient_max_friction(fraction : float = 0.0) -> float:
	return clamp(1.0 - 0.5 * (fraction - 0.1) / 0.3, 0, 1)

func _calculate_forces(_world_air_velocity : Vector3, _world_angular_velocity : Vector3, _air_density : float, _altitude : float, substep_delta : float = 0.0) -> PackedVector3Array:
	super._calculate_forces(_world_air_velocity, _world_angular_velocity, _air_density, _relative_position, _altitude, substep_delta)

	var force := Vector3.ZERO
	var torque := Vector3.ZERO

	var corrected_lift_slope = procedural_config.lift_slope * wing_config.aspect_ratio / (wing_config.aspect_ratio + 2.0 * (wing_config.aspect_ratio + 4.0) / (wing_config.aspect_ratio + 2.0))
	var theta : float = acos(2.0 * wing_config.flap_fraction - 1.0)
	var flap_effectiveness : float = 1.0 - (theta - sin(theta)) / PI
	var delta_lift : float = corrected_lift_slope * flap_effectiveness * flap_effectiveness_correction(flap_angle) * flap_angle
	var zero_lift_aoa_base : float = deg_to_rad(wing_config.zero_lift_aoa)
	var zero_lift_aoa : float = zero_lift_aoa_base - delta_lift / corrected_lift_slope
	var stall_angle_high_base : float = deg_to_rad(procedural_config.stall_angle_high)
	var stall_angle_low_base : float = deg_to_rad(procedural_config.stall_angle_low)
	var cl_max_high : float = corrected_lift_slope * (stall_angle_high_base - zero_lift_aoa_base) + delta_lift * lift_coefficient_max_friction(wing_config.flap_fraction)
	var cl_max_low : float = corrected_lift_slope * (stall_angle_low_base - zero_lift_aoa_base) + delta_lift * lift_coefficient_max_friction(wing_config.flap_fraction)
	var stall_angle_high = zero_lift_aoa + cl_max_high / corrected_lift_slope
	var stall_angle_low = zero_lift_aoa + cl_max_low / corrected_lift_slope


	#this is here because somehow, at some point, the angle of attack value
	#got flipped so that PI was equivalent to 0 AOA, with higher AOA values
	#being equal to PI - AOA, and low AOA values beginning with -PI and
	#being equal to -PI - AOA. This entire script needs a rewrite
	var temp_angle = PI - angle_of_attack
	if temp_angle > PI:
		temp_angle = -PI + fmod(temp_angle, PI)

	var aerodynamic_coefficients : Vector3 = calculate_procedural_coefficients(temp_angle, corrected_lift_slope, zero_lift_aoa, stall_angle_high, stall_angle_low)

	var lift : float = aerodynamic_coefficients.x * dynamic_pressure * area
	var drag : float = aerodynamic_coefficients.y * dynamic_pressure * area * wing_config.sweep_drag_multiplier_curve.sample(sweep_angle) * wing_config.drag_at_mach_multiplier_curve.sample(mach / 10.0)
	var induced_drag : float = lift * lift / (0.5 * dynamic_pressure * PI * wing_config.span * wing_config.span)

	var _torque : Vector3 = global_transform.basis.x * aerodynamic_coefficients.z * dynamic_pressure * area * wing_config.chord

	var lift_vector : Vector3 = lift_direction * lift
	var drag_vector : Vector3 = drag_direction * (drag + induced_drag)

	force = lift_vector + drag_vector
	torque += relative_position.cross(force)
	torque += _torque

	_current_lift = lift_vector
	_current_drag = drag_vector
	_current_torque = torque

	return PackedVector3Array([force, torque])

func calculate_procedural_coefficients(angle_of_attack : float, corrected_lift_slope : float, zero_lift_aoa : float, stall_angle_high : float, stall_angle_low : float) -> Vector3:
	var aerodynamic_coefficients : Vector3
	
	var padding_angle_high : float = deg_to_rad(lerp(15.0, 5.0, rad_to_deg(flap_angle + 50.0) / 100.0))
	var padding_angle_low : float = deg_to_rad(lerp(15.0, 5.0, -rad_to_deg(flap_angle + 50.0) / 100.0))
	var padded_stall_angle_high : float = stall_angle_high + padding_angle_high
	var padded_stall_angle_low : float = stall_angle_low + padding_angle_low

	if angle_of_attack < stall_angle_high and angle_of_attack > stall_angle_low:

		#low angle of attack mode
		aerodynamic_coefficients = calculate_coefficients_at_low_aoa(angle_of_attack, corrected_lift_slope, zero_lift_aoa)
	else:
		if angle_of_attack > padded_stall_angle_high or angle_of_attack < padded_stall_angle_low:
			#stall mode
			aerodynamic_coefficients = calculate_coefficients_at_stall(angle_of_attack, corrected_lift_slope, zero_lift_aoa, stall_angle_high, stall_angle_low)
		else:
			#Linear stitching in-between stall and low angles of attack modes.
			var aerodynamic_coefficients_low : Vector3
			var aerodynamic_coefficients_stall : Vector3
			var lerp_param : float

			if angle_of_attack > stall_angle_high:
				aerodynamic_coefficients_low = calculate_coefficients_at_low_aoa(stall_angle_high, corrected_lift_slope, zero_lift_aoa)
				aerodynamic_coefficients_stall = calculate_coefficients_at_stall(padded_stall_angle_high, corrected_lift_slope, zero_lift_aoa, stall_angle_high, stall_angle_low)
				lerp_param = (angle_of_attack - stall_angle_high) / (padded_stall_angle_high - stall_angle_high)
			else:
				aerodynamic_coefficients_low = calculate_coefficients_at_low_aoa(stall_angle_low, corrected_lift_slope, zero_lift_aoa)
				aerodynamic_coefficients_stall = calculate_coefficients_at_stall(padded_stall_angle_low, corrected_lift_slope, zero_lift_aoa, stall_angle_high, stall_angle_low)
				lerp_param = (angle_of_attack - stall_angle_low) / (padded_stall_angle_low - stall_angle_low)

			aerodynamic_coefficients = aerodynamic_coefficients_low.lerp(aerodynamic_coefficients_stall, lerp_param)
	
	#this is a really bad fix, but the lift direction was in the wrong orientation.
	aerodynamic_coefficients.x *= -1
	return aerodynamic_coefficients

func calculate_coefficients_at_low_aoa(angle_of_attack : float, corrected_lift_slope : float, zero_lift_aoa : float) -> Vector3:
	var lift_coefficient : float = corrected_lift_slope * (angle_of_attack - zero_lift_aoa)
	var induced_angle : float = lift_coefficient / (PI * wing_config.aspect_ratio)
	var effective_angle : float = angle_of_attack - zero_lift_aoa - induced_angle

	var sin_effective : float = sin(effective_angle)
	var cos_effective : float = cos(effective_angle)

	var tangential_coefficient : float = wing_config.skin_friction * cos_effective
	var normal_coefficient : float = (lift_coefficient + sin_effective * tangential_coefficient) / cos_effective

	var drag_coefficient : float = normal_coefficient * sin_effective + tangential_coefficient * cos_effective
	var torque_coefficient : float = -normal_coefficient * torque_coefficient_proportion(effective_angle)

	return Vector3(lift_coefficient, drag_coefficient, torque_coefficient)

func calculate_coefficients_at_stall(angle_of_attack : float, corrected_lift_slope : float, zero_lift_aoa : float, stall_angle_high : float, stall_angle_low : float) -> Vector3:
	var lift_coefficient_low_aoa : float

	if angle_of_attack > stall_angle_high:
		lift_coefficient_low_aoa = corrected_lift_slope * (stall_angle_high - zero_lift_aoa)
	else:
		lift_coefficient_low_aoa = corrected_lift_slope * (stall_angle_low - zero_lift_aoa)

	var induced_angle : float = lift_coefficient_low_aoa / (PI * wing_config.aspect_ratio)

	var lerp_param : float
	var half_pi : float = PI / 2.0
	if angle_of_attack > stall_angle_high:
		lerp_param = (half_pi - clamp(angle_of_attack, -half_pi, half_pi)) / (half_pi - stall_angle_high)

	else:
		lerp_param = (-half_pi - clamp(angle_of_attack, -half_pi, half_pi)) / (-half_pi - stall_angle_low)

	induced_angle = lerp(0.0, induced_angle, lerp_param)

	var effective_angle : float = angle_of_attack - zero_lift_aoa - induced_angle

	var sin_effective : float = sin(effective_angle)
	var cos_effective : float = cos(effective_angle)
	var normal_coefficient : float = friction_at_90_degrees(flap_angle) * sin_effective * (1.0 / (0.56 + 0.44 * abs(sin_effective)) - 0.41 * (1.0 - exp(-17.0 / wing_config.aspect_ratio)))
	var tangential_coefficient : float = 0.5 * wing_config.skin_friction * cos_effective
	var lift_coefficient : float = normal_coefficient * cos_effective - tangential_coefficient * sin_effective
	var drag_coefficient : float = normal_coefficient * sin_effective + tangential_coefficient * cos_effective
	var torque_coefficient : float = -normal_coefficient * torque_coefficient_proportion(effective_angle)

	return Vector3(lift_coefficient, drag_coefficient, torque_coefficient)

func friction_at_90_degrees(flap_angle : float) -> float:
	return 1.98 - 0.0426 * flap_angle * flap_angle + 0.21 * flap_angle

func torque_coefficient_proportion(effective_angle : float) -> float:
	return 0.25 - 0.175 * (1.0 - 2.0 * abs(effective_angle) / PI)
