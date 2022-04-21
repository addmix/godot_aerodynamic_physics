extends RigidBody
class_name AeroBody

# ~constant
var SUBSTEPS = ProjectSettings.get_setting("physics/3d/aerodynamics/substeps")
var PREDICTION_TIMESTEP_FRACTION = 1.0 / (1 + SUBSTEPS)

var aero_surfaces = []

export var max_force : float = 10000.0
export var max_torque : float = 10000.0

var current_force := Vector3.ZERO
var current_torque := Vector3.ZERO

func _enter_tree() -> void:
	for i in get_children():
		if i is AeroSurface:
			aero_surfaces.append(i)

func _integrate_forces(state : PhysicsDirectBodyState) -> void:
	var force_and_torque_this_frame : PoolVector3Array = calculate_aerodynamic_forces(linear_velocity, angular_velocity, Vector3.ZERO, 1.2, global_transform.origin)
	#clamp forces to avoid explosions
	force_and_torque_this_frame[0] = v3_clamp_length(force_and_torque_this_frame[0], max_force)
	force_and_torque_this_frame[1] = v3_clamp_length(force_and_torque_this_frame[1], max_torque)
	
	var velocity_prediction : Vector3 = predict_velocity(force_and_torque_this_frame[0] + state.total_gravity * mass)
	var angular_velocity_prediction : Vector3 = predict_angular_velocity(force_and_torque_this_frame[1])
	
	
	### TODO: allow custom substeps
	
#	for i in SUBSTEPS:
	var force_and_torque_prediction : PoolVector3Array = calculate_aerodynamic_forces(velocity_prediction, angular_velocity_prediction, Vector3.ZERO, 1.2, global_transform.origin)
	
	current_force = (force_and_torque_this_frame[0] + force_and_torque_prediction[0]) * 0.5
	current_torque = (force_and_torque_this_frame[1] + force_and_torque_prediction[1]) * 0.5
	
	apply_central_impulse(current_force * get_physics_process_delta_time())
	apply_torque_impulse(current_torque * get_physics_process_delta_time())

static func v3_clamp_length(v : Vector3, length : float) -> Vector3:
	if v.length_squared() == 0:
		return v

	return v.normalized() * min(length, v.length())

func calculate_aerodynamic_forces(vel : Vector3, ang_vel : Vector3, wind : Vector3, air_density : float, center_of_mass : Vector3) -> PoolVector3Array:
	var force : Vector3
	var torque : Vector3
	
	for surface in aero_surfaces:
		var relative_position : Vector3 = global_transform.basis.xform(surface.transform.origin)
		#ang_vel.cross(transform.origin) might cause errors, not sure if unity does transforms the same as godot
		var force_and_torque : PoolVector3Array = surface.calculate_forces(-vel + wind - (ang_vel.cross(relative_position)), air_density, relative_position)
		
		force += force_and_torque[0]
		torque += force_and_torque[1]
	
	return PoolVector3Array([force, torque])

func predict_velocity(force : Vector3) -> Vector3:
	return linear_velocity + get_physics_process_delta_time() * PREDICTION_TIMESTEP_FRACTION * force / mass

#error somewhere here, causing exploding
func predict_angular_velocity(torque : Vector3) -> Vector3:
	var torque_in_diagonal_space : Vector3 = get_inverse_inertia_tensor().xform(torque)
	
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
