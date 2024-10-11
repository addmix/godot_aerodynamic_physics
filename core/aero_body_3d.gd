@tool
extends VehicleBody3D
class_name AeroBody3D

const AeroMathUtils = preload("../utils/math_utils.gd")
const AeroNodeUtils = preload("../utils/node_utils.gd")

##Overrides the amount of simulation substeps are used when calculating aerodynamic effects on this body.
@export var substeps_override : int = -1:
	set(x):
		substeps_override = x
		PREDICTION_TIMESTEP_FRACTION = 1.0 / float(SUBSTEPS)

@export_group("Control")
## Value used by AeroInfluencers to control the AeroBody3D. Represents rotational axes. 
## X = Pitch, Y = Yaw, Z = Roll.
@export var control_command : Vector3 = Vector3.ZERO
## Value used by AeroInfluencers to control the AeroBody3D.
@export var throttle_command : float = 0.0
## Value used by AeroInfluencers to control the AeroBody3D.
@export var brake_command : float = 0.0
## Value used by AeroInfluencers to control the AeroBody3D.
@export var collective_command : float = 0.0

@export_group("Debug")

@export_subgroup("Visibility")
##Enables visibility of debug components.
@export var show_debug : bool = false:
	set(x):
		show_debug = x
		_update_debug_visibility()
##Enables update of debug components. Debug is only updated when show_debug and update_debug are true.
@export var update_debug : bool = false
##Enables visibility of wing debug components.
@export var show_wing_debug_vectors : bool = true:
	set(x):
		show_wing_debug_vectors = x
		_update_debug_visibility()
##Controls visibility of total lift vector.
@export var show_lift_vectors : bool = true:
	set(x):
		show_lift_vectors = x
		_update_debug_visibility()
##Controls visibility of total drag vector.
@export var show_drag_vectors : bool = true:
	set(x):
		show_drag_vectors = x
		_update_debug_visibility()
##Controls visibility of linear velocity vector.
@export var show_linear_velocity : bool = true:
	set(x):
		show_linear_velocity = x
		_update_debug_visibility()
##Controls visibility of angular velocity vector.
@export var show_angular_velocity : bool = true:
	set(x):
		show_angular_velocity = x
		_update_debug_visibility()

##Controls visibility of the center of lift vector.
@export var show_center_of_lift : bool = true:
	set(x):
		show_center_of_lift = x
		_update_debug_visibility()
##Controls visibility of the center of drag vector.
@export var show_center_of_drag : bool = true:
	set(x):
		show_center_of_drag = x
		_update_debug_visibility()
##Controls visibility of the center of mass marker.
@export var show_center_of_mass : bool = true:
	set(x):
		show_center_of_mass = x
		_update_debug_visibility()
##Controls visibility of the center of lift marker. (Unused)
@export var show_center_of_thrust : bool = true:
	set(x):
		show_center_of_thrust = x

@export_subgroup("Options")
##Linear velocity used for debug components calculations in the editor.
@export var debug_linear_velocity := Vector3(0, -10, -100)
##Angular velocity used for debug components calculations in the editor.
@export var debug_angular_velocity := Vector3.ZERO
##Controls the scale of debug components.
@export var debug_scale : float = 0.1:
	set(x):
		debug_scale = x
		_update_debug_scale()
##Controls the width/thickness of debug vectors.
@export var debug_width : float = 0.05:
	set(x):
		debug_width = x
		_update_debug_scale()
##Controls the width/thickness of debug center markers.
@export var debug_center_width : float = 0.2:
	set(x):
		debug_center_width = x
		_update_debug_scale()

		_update_debug_visibility()

@export_subgroup("")
@export_group("")
@export_category("")

var SUBSTEPS : int = ProjectSettings.get_setting("physics/3d/aerodynamics/substeps", 1):
	set(x):
		SUBSTEPS = x
		PREDICTION_TIMESTEP_FRACTION = 1.0 / float(SUBSTEPS)
	get:
		if substeps_override > -1:
			return substeps_override
		return ProjectSettings.get_setting("physics/3d/aerodynamics/substeps", 1)
var PREDICTION_TIMESTEP_FRACTION : float = 1.0 / float(SUBSTEPS)

var aero_influencers : Array[AeroInfluencer3D] = []
var aero_surfaces : Array[AeroSurface3D] = []

var current_force := Vector3.ZERO
var current_torque := Vector3.ZERO
var current_gravity := Vector3.ZERO
@onready var last_linear_velocity : Vector3 = linear_velocity
@onready var last_angular_velocity : Vector3 = angular_velocity
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
var linear_velocity_vector : AeroDebugVector3D
var angular_velocity_vector : AeroDebugVector3D

var lift_debug_vector : AeroDebugVector3D
var drag_debug_vector : AeroDebugVector3D

var mass_debug_point : AeroDebugPoint3D
var thrust_debug_vector : AeroDebugVector3D

func _init():
	mass_debug_point = AeroDebugPoint3D.new(Color(1, 1, 0), debug_center_width, true)
	mass_debug_point.visible = false
	mass_debug_point.sorting_offset = 0.0
	
	lift_debug_vector = AeroDebugVector3D.new(Color(0, 1, 1), debug_center_width, true)
	lift_debug_vector.visible = false
	lift_debug_vector.sorting_offset = 0.0
	
	drag_debug_vector = AeroDebugVector3D.new(Color(1, 0, 0), debug_width, true)
	drag_debug_vector.visible = false
	drag_debug_vector.sorting_offset = -0.01
	
	thrust_debug_vector = AeroDebugVector3D.new(Color(1, 0, 1), debug_width, true)
	thrust_debug_vector.visible = false
	thrust_debug_vector.sorting_offset = -0.02
	
	linear_velocity_vector = AeroDebugVector3D.new(Color(0, 0.5, 0.5), debug_width, false)
	linear_velocity_vector.visible = false
	linear_velocity_vector.sorting_offset = -0.03
	
	angular_velocity_vector = AeroDebugVector3D.new(Color(0, 0.333, 0), debug_width, false)
	angular_velocity_vector.visible = false
	angular_velocity_vector.sorting_offset = -0.04
	
	linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE

	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM

func _enter_tree() -> void:
	AeroNodeUtils.connect_signal_safe(self, "child_entered_tree", on_child_enter_tree, 0, true)
	AeroNodeUtils.connect_signal_safe(self, "child_exiting_tree", on_child_exit_tree, 0, true)
	
	if Engine.is_editor_hint():
		update_configuration_warnings()

func on_child_enter_tree(node : Node) -> void:
	if node is AeroInfluencer3D:
		aero_influencers.append(node)
		node.aero_body = self

func on_child_exit_tree(node : Node) -> void:
	if node is AeroInfluencer3D and aero_influencers.has(node):
		aero_influencers.erase(node)
		node.aero_body = null

func _ready() -> void:
	add_child(mass_debug_point, INTERNAL_MODE_FRONT)
	add_child(lift_debug_vector, INTERNAL_MODE_FRONT)
	add_child(drag_debug_vector, INTERNAL_MODE_FRONT)
	add_child(thrust_debug_vector, INTERNAL_MODE_FRONT)
	mass_debug_point.add_child(linear_velocity_vector, INTERNAL_MODE_FRONT)
	mass_debug_point.add_child(angular_velocity_vector, INTERNAL_MODE_FRONT)
	
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

func _physics_process(delta : float) -> void:
	if show_debug and update_debug:
		_update_debug()

var _integrate_forces_time : float = 0.0
func _integrate_forces(state : PhysicsDirectBodyState3D) -> void:
	if state.sleeping or SUBSTEPS == 0:
		return
	
	var pre_time : int = Time.get_ticks_usec()
	integrator(state)
	var post_time : int = Time.get_ticks_usec()
	_integrate_forces_time = float(post_time - pre_time) * 0.001

func integrator(state : PhysicsDirectBodyState3D) -> void:
	current_gravity = state.total_gravity
	var total_force_and_torque := calculate_forces(state)
	current_force = total_force_and_torque[0]
	current_torque = total_force_and_torque[1]
	state.apply_central_force(current_force)
	state.apply_torque(current_torque)

var linear_velocity_prediction : Vector3 = linear_velocity
var angular_velocity_prediction : Vector3 = angular_velocity
var substep_delta : float = get_physics_process_delta_time() / SUBSTEPS

func calculate_forces(state : PhysicsDirectBodyState3D) -> PackedVector3Array:
	#eventually implement wind
	wind = Vector3.ZERO
	air_velocity = -linear_velocity + wind
	air_speed = air_velocity.length()
	
	if has_node("/root/AeroUnits"):
		var _AeroUnits : Node = $"/root/AeroUnits"
		altitude = _AeroUnits.get_altitude(self)
		mach = _AeroUnits.speed_to_mach_at_altitude(air_speed, altitude)
		air_density = _AeroUnits.get_density_at_altitude(altitude)
		air_pressure = _AeroUnits.get_pressure_at_altitude(altitude)
	
	local_air_velocity = global_transform.basis.inverse() * air_velocity
	local_angular_velocity = global_transform.basis.inverse() * angular_velocity
	angle_of_attack = global_basis.y.angle_to(-air_velocity) - (PI / 2.0)
	sideslip_angle = global_basis.x.angle_to(air_velocity) - (PI / 2.0)
	bank_angle = rotation.z
	heading = rotation.y
	inclination = rotation.x
	if not Engine.is_editor_hint():
		center_of_mass = state.center_of_mass_local
	
	substep_delta = state.step / SUBSTEPS
	
	var last_force_and_torque := PackedVector3Array([Vector3.ZERO, Vector3.ZERO])
	var total_force_and_torque := last_force_and_torque
	
	linear_velocity_prediction = linear_velocity
	angular_velocity_prediction = angular_velocity
	
	for substep : int in SUBSTEPS:
		last_linear_velocity = linear_velocity_prediction
		last_angular_velocity = angular_velocity_prediction
		
		#allow aeroinfluencers to update their own transforms before we calculate forces
		if not Engine.is_editor_hint():
			for influencer : AeroInfluencer3D in aero_influencers:
				if influencer.disabled:
					continue
				influencer._update_transform_substep(substep_delta)
		
		linear_velocity_prediction = predict_linear_velocity(last_force_and_torque[0]) + state.total_gravity * PREDICTION_TIMESTEP_FRACTION
		angular_velocity_prediction = predict_angular_velocity(last_force_and_torque[1])
		last_force_and_torque = calculate_aerodynamic_forces(linear_velocity_prediction, angular_velocity_prediction, air_density, substep_delta)
		
		#add to total forces
		total_force_and_torque[0] += last_force_and_torque[0]
		total_force_and_torque[1] += last_force_and_torque[1]
	
	total_force_and_torque[0] = total_force_and_torque[0] / SUBSTEPS
	total_force_and_torque[1] = total_force_and_torque[1] / SUBSTEPS
	return total_force_and_torque

func calculate_aerodynamic_forces(_velocity : Vector3, _angular_velocity : Vector3, air_density : float, substep_delta : float = 0.0) -> PackedVector3Array:
	var force : Vector3
	var torque : Vector3
	
	#can we parallelize this for loop?
	for influencer : AeroInfluencer3D in aero_influencers:
		if influencer.disabled:
			continue
		
		#relative_position is the position of the surface, centered on the AeroBody's origin, with the global rotation
		var relative_position : Vector3 = global_basis * (influencer.transform.origin - center_of_mass)
		var force_and_torque : PackedVector3Array = influencer._calculate_forces(substep_delta)
		
		force += force_and_torque[0]
		torque += force_and_torque[1]
	
	return PackedVector3Array([force, torque])

func predict_linear_velocity(force : Vector3) -> Vector3:
	return linear_velocity + (force / mass * get_physics_process_delta_time() * PREDICTION_TIMESTEP_FRACTION)

func predict_angular_velocity(torque : Vector3) -> Vector3:
	return angular_velocity + get_physics_process_delta_time() * PREDICTION_TIMESTEP_FRACTION * (get_inverse_inertia_tensor() * torque)

func get_amount_of_active_influencers() -> int:
	var count : int = 0
	for influencer : AeroInfluencer3D in aero_influencers:
		if not influencer.disabled:
			count += 1
	
	return count

func get_relative_position() -> Vector3:
	return global_basis * -center_of_mass

func get_linear_velocity() -> Vector3:
	return linear_velocity_prediction

func get_angular_velocity() -> Vector3:
	return angular_velocity_prediction

func get_linear_acceleration() -> Vector3:
	return (linear_velocity_prediction - last_linear_velocity) / substep_delta

func get_angular_acceleration() -> Vector3:
	return (angular_velocity_prediction - last_angular_velocity) / substep_delta


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
	
	
	var linear_velocity_to_use := linear_velocity
	var angular_velocity_to_use := angular_velocity
	if Engine.is_editor_hint():
		linear_velocity_to_use = debug_linear_velocity
		angular_velocity_to_use = debug_angular_velocity
	
	linear_velocity_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(linear_velocity_to_use, 2.0)
	angular_velocity_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(angular_velocity_to_use, 2.0)
	
	#Godot doesn't run physics engine in-editor.
	#A consequence of this is that get_linear_velocity doesn't work.
	#Instead, we must access linear_velocity directly.
	#We don't want to overwrite user configured linear velocity, so we must use this workaround.
	
	if Engine.is_editor_hint():
		var original_linear_velocity := linear_velocity
		var original_angular_velocity := angular_velocity
		linear_velocity = debug_linear_velocity
		angular_velocity = debug_angular_velocity
		var last_force_and_torque := calculate_aerodynamic_forces(linear_velocity_to_use, angular_velocity_to_use, air_density)
		linear_velocity = original_linear_velocity
		angular_velocity = original_angular_velocity
	
	#force and torque debug
	if aero_influencers.size() > 0:
		var amount_of_aero_influencers : int = aero_influencers.size()
		var force_sum := 0.0
		var force_vector_sum := Vector3.ZERO
		
		for influencer : AeroInfluencer3D in aero_influencers:
			if influencer.omit_from_debug or influencer.disabled:
				amount_of_aero_influencers -= 1
				continue
			force_vector_sum += influencer._current_force
	
	#lift and drag debug
	var amount_of_aero_surfaces : int = aero_surfaces.size()
	for surface : AeroSurface3D in aero_surfaces:
		if surface.omit_from_debug or surface.disabled:
			amount_of_aero_surfaces -= 1
	
	if amount_of_aero_surfaces > 0:
		var lift_sum := 0.0
		var lift_sum_vector := Vector3.ZERO
		var drag_sum := 0.0
		var drag_sum_vector := Vector3.ZERO
		var lift_position_sum := Vector3.ZERO
		var drag_position_sum := Vector3.ZERO
		for surface : AeroSurface3D in aero_surfaces:
			if surface.omit_from_debug:
				continue
			
			lift_sum += surface.lift_force
			lift_sum_vector += surface._current_lift
			drag_sum += surface.drag_force
			drag_sum_vector += surface._current_drag
			lift_position_sum += surface.transform.origin * surface.lift_force
			drag_position_sum += surface.transform.origin * surface.drag_force
		
		if lift_sum_vector.is_finite() and drag_sum_vector.is_finite():
			lift_debug_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(lift_sum_vector / amount_of_aero_surfaces, 2.0)
			drag_debug_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(drag_sum_vector / amount_of_aero_surfaces, 2.0)
			
			if is_equal_approx(lift_sum, 0.0):
				lift_sum = 1.0
			lift_debug_vector.position = lift_position_sum / amount_of_aero_surfaces / (lift_sum / amount_of_aero_surfaces) 
			if is_equal_approx(drag_sum, 0.0):
				drag_sum = 1.0
			drag_debug_vector.position = drag_position_sum / amount_of_aero_surfaces / (drag_sum / amount_of_aero_surfaces)
	

func _update_debug_visibility() -> void:
	#update aerosurface visibility
	
	for influencer : AeroInfluencer3D in aero_influencers:
		influencer.update_debug_visibility(show_debug and show_wing_debug_vectors)
	
	#update self visibility
	linear_velocity_vector.visible = show_debug and show_linear_velocity
	angular_velocity_vector.visible = show_debug and show_angular_velocity

	lift_debug_vector.visible = show_debug and show_lift_vectors
	drag_debug_vector.visible = show_debug and show_drag_vectors

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
