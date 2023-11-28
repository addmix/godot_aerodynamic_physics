@tool
extends VehicleBody3D
class_name AeroBody3D

@export_category("Debug")
@export var show_debug : bool = false:
	set(x):
		show_debug = x
		_update_debug_visibility()
@export_group("Options")
@export var show_center_of_mass : bool = true:
	set(x):
		show_center_of_mass = x
		_update_debug_visibility()
@export var show_center_of_lift : bool = true:
	set(x):
		show_center_of_lift = x
		_update_debug_visibility()
@export var show_center_of_thrust : bool = true:
	set(x):
		show_center_of_thrust = x
		_update_debug_visibility()
@export var show_wing_debug_vectors : bool = true:
	set(x):
		show_wing_debug_vectors = x
		_update_debug_visibility()
@export var show_lift : bool = true:
	set(x):
		show_lift = x
		_update_debug_visibility()
@export var show_drag : bool = true:
	set(x):
		show_drag = x
		_update_debug_visibility()
@export var show_airflow : bool = true:
	set(x):
		show_airflow = x
		_update_debug_visibility()
@export_group("")
@export_category("")

# ~constant
var SUBSTEPS = ProjectSettings.get_setting("physics/3d/aerodynamics/substeps", 0)
var PREDICTION_TIMESTEP_FRACTION = 1.0 / float(SUBSTEPS)

var aero_surfaces = []

var current_force := Vector3.ZERO
var current_torque := Vector3.ZERO
var current_gravity := Vector3.ZERO
var wind := Vector3.ZERO
var air_velocity := Vector3.ZERO
var local_air_velocity := Vector3.ZERO
var local_angular_velocity := Vector3.ZERO
var air_speed := 0.0
var mach := 0.0
var air_density : float = 0.0
var air_pressure : float = 0.0
var angle_of_attack := 0.0
var sideslip_angle := 0.0
var altitude := 0.0
var bank_angle := 0.0
var heading := 0.0
var inclination := 0.0

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()
		return

	for i in get_children():
		if i is AeroSurface3D:
			aero_surfaces.append(i)

func _ready() -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()
		return
	_update_debug_visibility()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray([])
	var default_linear_damp : float = ProjectSettings.get_setting("physics/3d/default_linear_damp", 0.0)
	if linear_damp_mode == DAMP_MODE_COMBINE:
		if default_linear_damp + linear_damp > 0.0:
			warnings.append("Linear damping is greater than 0. Unexpected aerodynamic characteristics will be present.")
	else:
		if linear_damp > 0.0:
			warnings.append("Linear damping is greater than 0. Unexpected aerodynamic characteristics will be present.")

	var default_angular_damp : float = ProjectSettings.get_setting("physics/3d/default_angular_damp", 0.0)
	if angular_damp_mode == DAMP_MODE_COMBINE:
		if default_angular_damp + angular_damp > 0.0:
			warnings.append("Angular damping is greater than 0. Unexpected aerodynamic characteristics will be present.")
	else:
		if angular_damp > 0.0:
			warnings.append("Angular damping is greater than 0. Unexpected aerodynamic characteristics will be present.")

	return warnings

func _integrate_forces(state : PhysicsDirectBodyState3D) -> void:
	current_gravity = state.total_gravity
	var total_force_and_torque := calculate_forces(state)
	apply_central_force(total_force_and_torque[0])
	apply_torque(total_force_and_torque[1])

func calculate_forces(state : PhysicsDirectBodyState3D) -> PackedVector3Array:
	#eventually implement wind
	wind = Vector3.ZERO
	air_velocity = -linear_velocity + wind
	air_speed = air_velocity.length()
	altitude = AeroUnits.get_altitude(self)
	mach = AeroUnits.speed_to_mach_at_altitude(air_speed, altitude)
	air_density = AeroUnits.get_density_at_altitude(position.y)
	air_pressure = AeroUnits.get_pressure_at_altitude(position.y)
	local_air_velocity = global_transform.basis.inverse() * air_velocity
	local_angular_velocity = global_transform.basis.inverse() * angular_velocity
	angle_of_attack = atan2(local_air_velocity.y, local_air_velocity.z)
	sideslip_angle = atan2(-local_air_velocity.x, local_air_velocity.z)
	bank_angle = rotation.z
	heading = rotation.y
	inclination = rotation.x
	

	var last_force_and_torque := calculate_aerodynamic_forces(air_velocity, angular_velocity, air_density, air_pressure)
	var total_force_and_torque := last_force_and_torque

	for i in SUBSTEPS:
		var linear_velocity_prediction : Vector3 = predict_linear_velocity(last_force_and_torque[0] + state.total_gravity * mass)
		var angular_velocity_prediction : Vector3 = predict_angular_velocity(last_force_and_torque[1])
		var force_and_torque_prediction : PackedVector3Array = calculate_aerodynamic_forces(linear_velocity_prediction, angular_velocity_prediction, air_density, air_pressure)
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

func calculate_aerodynamic_forces(_velocity : Vector3, _angular_velocity : Vector3, air_density : float, air_pressure : float) -> PackedVector3Array:
	var force : Vector3
	var torque : Vector3

	for surface in aero_surfaces:
		#relative_position is the position of the surface, centered on the AeroBody's origin, with the global rotation
		var relative_position : Vector3 = global_transform.basis * (surface.transform.origin - center_of_mass)

		var force_and_torque : PackedVector3Array = surface.calculate_forces(-(_velocity + _angular_velocity.cross(relative_position)), air_density, air_pressure, relative_position, position.y)
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

func _update_debug_visibility():
	for surface in aero_surfaces:
		surface.update_debug_visibility(show_debug and show_wing_debug_vectors, show_lift, show_drag, show_airflow)
