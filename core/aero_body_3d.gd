@tool
extends VehicleBody3D
class_name AeroBody3D

@export_category("Debug")
@export var show_debug : bool = false:
	set(x):
		show_debug = x
		_update_debug_visibility()
@export var update_debug : bool = false

@export_group("Options")
@export var show_wing_debug_vectors : bool = true:
	set(x):
		show_wing_debug_vectors = x
		_update_debug_visibility()
@export var debug_scale : float = 0.001:
	set(x):
		debug_scale = x
		_update_debug_scale()
@export var debug_width : float = 0.05:
	set(x):
		debug_width = x
		_update_debug_scale()
@export var debug_center_width : float = 0.2:
	set(x):
		debug_center_width = x
		_update_debug_scale()
@export_subgroup("Vectors")
@export var show_lift : bool = true:
	set(x):
		show_lift = x
		_update_debug_visibility()
@export var show_drag : bool = true:
	set(x):
		show_drag = x
		_update_debug_visibility()


@export_group("Physics")
@export var show_linear_velocity : bool = true:
	set(x):
		show_linear_velocity = x
		_update_debug_visibility()
@export var show_angular_velocity : bool = true:
	set(x):
		show_angular_velocity = x
		_update_debug_visibility()

@export_subgroup("Centers")

@export var show_center_of_lift : bool = true:
	set(x):
		show_center_of_lift = x
		_update_debug_visibility()
@export var show_center_of_drag : bool = true:
	set(x):
		show_center_of_drag = x
		_update_debug_visibility()
@export var show_center_of_mass : bool = true:
	set(x):
		show_center_of_mass = x
		_update_debug_visibility()
@export var show_center_of_thrust : bool = true:
	set(x):
		show_center_of_thrust = x
		_update_debug_visibility()

@export_group("")
@export_category("")

# ~constant
var SUBSTEPS = ProjectSettings.get_setting("physics/3d/aerodynamics/substeps", 0)
var PREDICTION_TIMESTEP_FRACTION = 1.0 / float(SUBSTEPS)

var aero_influencers : Array[AeroInfluencer3D] = []
var aero_surfaces : Array[AeroSurface3D] = []

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


#debug
var linear_velocity_vector : Vector3D
var angular_velocity_vector : Vector3D

var lift_debug_vector : Vector3D
var drag_debug_vector : Vector3D

var mass_debug_point : Point3D
var thrust_debug_vector : Vector3D

func _init():
	mass_debug_point = Point3D.new(Color(1, 1, 0), debug_center_width, true)
	mass_debug_point.visible = false
	mass_debug_point.sorting_offset = 0.0
	add_child(mass_debug_point, INTERNAL_MODE_FRONT)
	
	lift_debug_vector = Vector3D.new(Color(0, 1, 1), debug_center_width, true)
	lift_debug_vector.visible = false
	lift_debug_vector.sorting_offset = 0.0
	add_child(lift_debug_vector, INTERNAL_MODE_FRONT)
	
	drag_debug_vector = Vector3D.new(Color(1, 0, 0), debug_width, true)
	drag_debug_vector.visible = false
	drag_debug_vector.sorting_offset = -0.01
	add_child(drag_debug_vector, INTERNAL_MODE_FRONT)
	
	thrust_debug_vector = Vector3D.new(Color(1, 0, 1), debug_width, true)
	thrust_debug_vector.visible = false
	thrust_debug_vector.sorting_offset = -0.02
	add_child(thrust_debug_vector, INTERNAL_MODE_FRONT)
	
	linear_velocity_vector = Vector3D.new(Color(0, 0.5, 0.5), debug_width, false)
	linear_velocity_vector.visible = false
	linear_velocity_vector.sorting_offset = -0.03
	mass_debug_point.add_child(linear_velocity_vector, INTERNAL_MODE_FRONT)
	
	angular_velocity_vector = Vector3D.new(Color(0, 0.333, 0), debug_width, false)
	angular_velocity_vector.visible = false
	angular_velocity_vector.sorting_offset = -0.04
	mass_debug_point.add_child(angular_velocity_vector, INTERNAL_MODE_FRONT)

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()
	
	for i in get_children():
		if i is AeroInfluencer3D:
			aero_influencers.append(i)

func _ready() -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()

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

func _physics_process(delta):
	if show_debug and update_debug:
		_update_debug()

func _integrate_forces(state : PhysicsDirectBodyState3D) -> void:
	current_gravity = state.total_gravity
	var total_force_and_torque := calculate_forces(state)
	current_force = total_force_and_torque[0]
	current_torque = total_force_and_torque[1]
	apply_central_force(current_force)
	apply_torque(current_torque)

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

	var substep_delta : float = state.step / SUBSTEPS + 1
	var last_force_and_torque := calculate_aerodynamic_forces(air_velocity, angular_velocity, air_density)
	var total_force_and_torque := last_force_and_torque
	
	for i : int in SUBSTEPS:
		var linear_velocity_prediction : Vector3 = predict_linear_velocity(last_force_and_torque[0] + state.total_gravity * mass)
		var angular_velocity_prediction : Vector3 = predict_angular_velocity(last_force_and_torque[1])
		var force_and_torque_prediction : PackedVector3Array = calculate_aerodynamic_forces(linear_velocity_prediction, angular_velocity_prediction, air_density, substep_delta)
		
		#add to total forces
		total_force_and_torque[0] += force_and_torque_prediction[0]
		total_force_and_torque[1] += force_and_torque_prediction[1]

	total_force_and_torque[0] = total_force_and_torque[0] / (SUBSTEPS + 1)
	total_force_and_torque[1] = total_force_and_torque[1] / (SUBSTEPS + 1)
	return total_force_and_torque

func calculate_aerodynamic_forces(_velocity : Vector3, _angular_velocity : Vector3, air_density : float, substep_delta : float = 0.0) -> PackedVector3Array:
	var force : Vector3
	var torque : Vector3

	for influencer : AeroInfluencer3D in aero_influencers:
		#relative_position is the position of the surface, centered on the AeroBody's origin, with the global rotation
		var relative_position : Vector3 = global_transform.basis * (influencer.transform.origin - center_of_mass)
		var force_and_torque : PackedVector3Array = influencer._calculate_forces(-(_velocity + _angular_velocity.cross(relative_position)), air_density, relative_position, position.y, substep_delta)
		
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


#debug


func _update_debug() -> void:
	aero_surfaces = []
	for i in get_children():
		if i is AeroSurface3D:
			aero_surfaces.append(i)
	
	_update_debug_visibility()
	_update_debug_scale()
	
	mass_debug_point.position = center_of_mass
	#thrust_debug_vector.position = center of thrust
	
	linear_velocity_vector.value = global_transform.basis.inverse() * linear_velocity * 0.01
	angular_velocity_vector.value = global_transform.basis.inverse() * angular_velocity
	
	if is_equal_approx(linear_velocity.length_squared(), 0.0):
		return
	
	var calculated_force_and_torque : PackedVector3Array
	if Engine.is_editor_hint():
		var last_force_and_torque := calculate_aerodynamic_forces(linear_velocity, angular_velocity, AeroUnits.get_density_at_altitude(position.y))
		var total_force_and_torque := last_force_and_torque
		
		for i : int in SUBSTEPS:
			
			var linear_velocity_prediction : Vector3 = predict_linear_velocity(last_force_and_torque[0] + current_gravity * Vector3(0, -1, 0) * mass)
			var angular_velocity_prediction : Vector3 = predict_angular_velocity(last_force_and_torque[1])
			var force_and_torque_prediction : PackedVector3Array = calculate_aerodynamic_forces(linear_velocity_prediction, angular_velocity_prediction, AeroUnits.get_density_at_altitude(position.y))
			#add to total forces
			total_force_and_torque[0] += force_and_torque_prediction[0]
			total_force_and_torque[1] += force_and_torque_prediction[1]
			
			total_force_and_torque[0] = total_force_and_torque[0] / (SUBSTEPS + 1)
			total_force_and_torque[1] = total_force_and_torque[1] / (SUBSTEPS + 1)
		
		calculated_force_and_torque = total_force_and_torque
	
	
	#force and torque debug
	if aero_influencers.size() > 0:
		var force_sum := 0.0
		var force_vector_sum := Vector3.ZERO
		
		for influencers : AeroInfluencer3D in aero_influencers:
			force_vector_sum += influencers._current_force
		
		
	
	#lift and drag debug
	if aero_surfaces.size() > 0:
		var lift_sum := 0.0
		var lift_sum_vector := Vector3.ZERO
		var drag_sum := 0.0
		var drag_sum_vector := Vector3.ZERO
		var lift_position_sum := Vector3.ZERO
		var drag_position_sum := Vector3.ZERO
		for surface : AeroSurface3D in aero_surfaces:
			lift_sum += surface.lift_force
			lift_sum_vector += surface._current_lift
			drag_sum += surface.drag_force
			drag_sum_vector += surface._current_drag
			lift_position_sum += surface.transform.origin * surface.lift_force
			drag_position_sum += surface.transform.origin * surface.drag_force
		
		if lift_sum_vector.is_finite() and drag_sum_vector.is_finite():
			lift_debug_vector.value = global_transform.basis.inverse() * lift_sum_vector / aero_surfaces.size()
			drag_debug_vector.value = global_transform.basis.inverse() * drag_sum_vector / aero_surfaces.size()
			
			if is_equal_approx(lift_sum, 0.0):
				lift_sum = 1.0
			lift_debug_vector.position = lift_position_sum / lift_sum / aero_surfaces.size()
			if is_equal_approx(drag_sum, 0.0):
				drag_sum = 1.0
			drag_debug_vector.position = drag_position_sum / drag_sum / aero_surfaces.size()
	

func _update_debug_visibility() -> void:
	#update aerosurface visibility
	for influencer : AeroInfluencer3D in aero_influencers:
		influencer.update_debug_visibility(show_debug and show_wing_debug_vectors)
	
	#update self visibility
	linear_velocity_vector.visible = show_debug and show_linear_velocity
	angular_velocity_vector.visible = show_debug and show_angular_velocity

	lift_debug_vector.visible = show_debug and show_lift
	drag_debug_vector.visible = show_debug and show_drag

	mass_debug_point.visible = show_debug and show_center_of_mass
	thrust_debug_vector.visible = show_debug and show_center_of_thrust

func _update_debug_scale() -> void:
	for influencer : AeroInfluencer3D in aero_influencers:
		influencer.update_debug_scale(debug_scale, debug_width)
	
	lift_debug_vector.width = debug_center_width
	mass_debug_point.width = debug_center_width
	thrust_debug_vector.width = debug_width
	
	linear_velocity_vector.width = debug_width
	angular_velocity_vector.width = debug_width
	drag_debug_vector.width = debug_width
	thrust_debug_vector.width = debug_width
