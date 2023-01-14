extends RigidBody3D
class_name AeroBody3D

# ~constant
var SUBSTEPS = ProjectSettings.get_setting("physics/3d/aerodynamics/substeps")
var PREDICTION_TIMESTEP_FRACTION = 1.0 / float(SUBSTEPS + 1)

var aero_surfaces = []

var current_force := Vector3.ZERO
var current_torque := Vector3.ZERO

func _enter_tree() -> void:
	for i in get_children():
		if i is AeroSurface3D or i is ProceduralAeroSurface3D or i is ManualAeroSurface3D:
			aero_surfaces.append(i)

func _integrate_forces(state : PhysicsDirectBodyState3D) -> void:
	var total_force_and_torque := calculate_forces(state)
	apply_central_impulse(total_force_and_torque[0] * get_physics_process_delta_time())
	apply_torque_impulse(total_force_and_torque[1] * get_physics_process_delta_time())

func calculate_forces(state : PhysicsDirectBodyState3D) -> PackedVector3Array:
	var air_density : float = AeroUnits.get_density_at_altitude(position.y)
	var air_pressure : float = AeroUnits.get_pressure_at_altitude(position.y)
	var wind : Vector3

	var last_force_and_torque := calculate_aerodynamic_forces(linear_velocity, angular_velocity, Vector3.ZERO, air_density, air_pressure)
	var total_force_and_torque := last_force_and_torque

	for i in SUBSTEPS:
		var linear_velocity_prediction : Vector3 = predict_linear_velocity(last_force_and_torque[0] + state.total_gravity * mass)
		var angular_velocity_prediction : Vector3 = predict_angular_velocity(last_force_and_torque[1])
		var force_and_torque_prediction : PackedVector3Array = calculate_aerodynamic_forces(linear_velocity_prediction, angular_velocity_prediction, Vector3.ZERO, air_density, air_pressure)
		#add to total forces
		total_force_and_torque[0] += force_and_torque_prediction[0]
		total_force_and_torque[1] += force_and_torque_prediction[1]

	total_force_and_torque[0] = total_force_and_torque[0] / (SUBSTEPS + 1)
	total_force_and_torque[1] = total_force_and_torque[1] / (SUBSTEPS + 1)
	return total_force_and_torque

static func v3_clamp_length(v : Vector3, length : float) -> Vector3:
	if v.length_squared() == 0:
		return v

	return v.normalized() * min(length, v.length())

func calculate_aerodynamic_forces(vel : Vector3, ang_vel : Vector3, wind : Vector3, air_density : float, air_pressure : float) -> PackedVector3Array:
	var force : Vector3
	var torque : Vector3

	for surface in aero_surfaces:
		#relative_position is the position of the surface, centered on the AeroBody's origin, with the global rotation
		var relative_position : Vector3 = global_transform.basis * (surface.transform.origin - center_of_mass)
		var force_and_torque : PackedVector3Array = surface.calculate_forces(-vel + wind - (ang_vel.cross(relative_position)), air_density, air_pressure, relative_position, position.y)

		force += force_and_torque[0]
		torque += force_and_torque[1]

	return PackedVector3Array([force, torque])

func predict_linear_velocity(force : Vector3) -> Vector3:
	return linear_velocity + get_physics_process_delta_time() * PREDICTION_TIMESTEP_FRACTION * force / mass

func predict_angular_velocity(torque : Vector3) -> Vector3:
	var torque_in_diagonal_space : Vector3 = get_inverse_inertia_tensor() * torque

	var angular_velocity_change_in_diagonal_space : Vector3
	angular_velocity_change_in_diagonal_space.x = torque_in_diagonal_space.x / get_inverse_inertia_tensor().x.length()
	angular_velocity_change_in_diagonal_space.y = torque_in_diagonal_space.y / get_inverse_inertia_tensor().y.length()
	angular_velocity_change_in_diagonal_space.z = torque_in_diagonal_space.z / get_inverse_inertia_tensor().z.length()

	return angular_velocity + get_physics_process_delta_time() * PREDICTION_TIMESTEP_FRACTION * (get_inverse_inertia_tensor() * angular_velocity_change_in_diagonal_space)

#pitch authority
#control surface local transform cross local Y axis, X value of vector is relevant
#roll authority
#control surface local transform cross local Z axis, Z value of vector is relevant
#yaw authority
#control surface local transform cross local Y axis, X value of vector is relevant
func control(input : Vector3) -> void:
	pass
