@tool
extends VehicleBody3D
class_name AeroBody3D
## AeroBody3D is the base node for simulating aerodynamic forces.[br]
##
## Aerodynamic forces are calculated from child [AeroInfluencer3D] nodes.[br]
## [br]
## Steps to retain all functionality when extending this script:[br]
## 1. Add [code]@tool[/code] to the top of the script.[br]
##     - This allows the script to run in the editor, so that the debug vectors can update.[br]
## 2. call [code]super()[/code] when extending functions.[br]
## [br]
## examples:
## [codeblock lang=gdscript]
## func _enter_tree():
##     super()
##     (...)
##
## func _ready():
##     super()
##     (...)
##
## func _physics_process(delta):
##     super(delta)
##     (...)
##
## [/codeblock]

const AeroMathUtils = preload("../utils/math_utils.gd")
const AeroNodeUtils = preload("../utils/node_utils.gd")

## Overrides the amount of simulation substeps that are used when calculating aerodynamics.
@export var substeps_override : int = -1

@export_group("Debug")

@export_subgroup("Visibility")
## Enables visibility of debug components.
@export var show_debug : bool = false:
	set(x):
		show_debug = x
		_update_debug_visibility()
## Enables update of debug components. Debug is only updated when show_debug and update_debug are true.
@export var update_debug : bool = true
## Enables visibility of wing debug components.
@export var show_wing_debug_vectors : bool = true:
	set(x):
		show_wing_debug_vectors = x
		_update_debug_visibility()
@export var show_torque : bool = false
## Controls visibility of total lift vector.
@export var show_lift_vectors : bool = true:
	set(x):
		show_lift_vectors = x
		_update_debug_visibility()
## Controls visibility of total drag vector.
@export var show_drag_vectors : bool = true:
	set(x):
		show_drag_vectors = x
		_update_debug_visibility()
## Controls visibility of linear velocity vector.
@export var show_linear_velocity : bool = true:
	set(x):
		show_linear_velocity = x
		_update_debug_visibility()
## Controls visibility of angular velocity vector.
@export var show_angular_velocity : bool = true:
	set(x):
		show_angular_velocity = x
		_update_debug_visibility()

## Controls visibility of the center of lift vector.
@export var show_center_of_lift : bool = true:
	set(x):
		show_center_of_lift = x
		_update_debug_visibility()
## Controls visibility of the center of drag vector.
@export var show_center_of_drag : bool = true:
	set(x):
		show_center_of_drag = x
		_update_debug_visibility()
## Controls visibility of the center of mass marker.
@export var show_center_of_mass : bool = true:
	set(x):
		show_center_of_mass = x
		_update_debug_visibility()
## Controls visibility of the center of lift marker. (Unused)
@export var show_center_of_thrust : bool = true:
	set(x):
		show_center_of_thrust = x

@export_subgroup("Options")
## Linear velocity used for debug components calculations in the editor.
@export var debug_linear_velocity := Vector3(0, -10, -100)
## Angular velocity used for debug components calculations in the editor.
@export var debug_angular_velocity := Vector3.ZERO
## Controls the scale of debug components.
@export var debug_scale : float = 0.1:
	set(x):
		debug_scale = x
		_update_debug_scale()
## Controls the logarithmic base used to "compress" debug vector lengths.
@export var debug_scaling_factor : float = 2.0:
	set(x):
		debug_scaling_factor = x
		_update_debug_scale()
## Controls the width/thickness of debug vectors.
@export var debug_width : float = 0.3:
	set(x):
		debug_width = x
		_update_debug_scale()
@export var influencer_debug_width : float = 0.1:
	set(x):
		influencer_debug_width = x
		_update_debug_scale()
## Controls the width/thickness of debug center markers.
@export var debug_center_width : float = 0.4:
	set(x):
		debug_center_width = x
		_update_debug_scale()

		_update_debug_visibility()

@export_subgroup("")
@export_group("")
@export_category("")

## The total amount of substeps used when calculating aerodynamics. [br]
## For example, when SUBSTEPS is set to 4, the physics update is broken down into 4 sub-iterations. [br]
## The initial physics update does NOT count as an extra substep. [br]
var SUBSTEPS : int = ProjectSettings.get_setting("physics/3d/aerodynamics/substeps", 1):
	set(x):
		SUBSTEPS = x
		PREDICTION_TIMESTEP_FRACTION = 1.0 / float(SUBSTEPS)
	get:
		if substeps_override > -1:
			return substeps_override
		return ProjectSettings.get_setting("physics/3d/aerodynamics/substeps", 1)
## Used to calculate [code]substep_delta[/code].
var PREDICTION_TIMESTEP_FRACTION : float:
	get:
		return 1.0 / float(SUBSTEPS)

## List of [AeroInfluencer3D] nodes that affect this [AeroBody3D]
var aero_influencers : Array[AeroInfluencer3D] = []
## Subset of [member AeroBody3D.aero_influencers] which only contains [AeroSurface3D]s
var aero_surfaces : Array[AeroSurface3D] = []

## The current force caused by aerodynamics. (excludes gravity)
var current_force := Vector3.ZERO
## The current torque caused by aerodynamics.
var current_torque := Vector3.ZERO
## The current gravity acting on the [AeroBody3D]
var current_gravity := Vector3.ZERO
@onready var last_linear_velocity : Vector3 = linear_velocity
@onready var last_angular_velocity : Vector3 = angular_velocity
@onready var uncommitted_last_linear_velocity : Vector3 = linear_velocity
@onready var uncommitted_last_angular_velocity : Vector3 = angular_velocity
## This [AeroBody3D]'s linear acceleration since the last frame. [br]
## Meters per second squared
var linear_acceleration := Vector3.ZERO
## This [AeroBody3D]'s angular acceleration since the last frame. [br]
## Radians per second squared
var angular_acceleration := Vector3.ZERO
## Wind velocity in meters per second.
var wind := Vector3.ZERO:
	set(x):
		if not wind == x: interrupt_sleep()
		wind = x
## The velocity of air passing the aircraft.[br]
## Equivalent to [code]-linear_velocity + wind[/code].
var air_velocity := Vector3.ZERO
## [member AeroBody3D.air_velocity] in the [AeroBody3D]'s local coordinate space.
var local_air_velocity := Vector3.ZERO
## [member RigidBody3D.angular_velocity] in the [AeroBody3D]'s local coordinate space.
var local_angular_velocity := Vector3.ZERO
## Air speed in meters per second.[br]
## Equivalent to [code]linear_velocity.length()[/code].
var air_speed := 0.0
## Current mach-speed of the [AeroBody3D].[br]
## Mach 1.0 is the speed of sound.[br]
## Adjusted for atmospheric changes.
var mach := 0.0
## The denisty of the air in kg/m^3.
var air_density : float = 1.225
## The pressure of air in pascals (Pa).
var air_pressure : float = 101325.0
## The angle-of-attack relative to the [member AeroBody3D.air_velocity] in radians.[br]
var angle_of_attack := 0.0
## The sideslip angle relative to the [member AeroBody3D.air_velocity] in radians.[br]
## Similar to [member AeroBody3D.angle_of_attack], but measured on the lateral axis, instead of vertical.
var sideslip_angle := 0.0
## Altitude of the AeroBody3D in meters.
var altitude := 0.0
## Bank angle (roll) of the AeroBody3D in radians.
## Alias for [code]global_rotation.z[/code]
var bank_angle := 0.0
## Heading angle in radians (compass angle). 0.0 is the global -Z direction. Left is the positive direction.[br]
## Alias for [code]global_rotation.y[/code]
var heading := 0.0
## Inclination angle (pitch) of the AeroBody3D in radians.
## Alias for [code]global_rotation.x[/code]
var inclination := 0.0


#override warning tests
var test_enter_tree_override : bool = false
var test_ready_override : bool = false
var test_physics_process_override : bool = false
var test_integrate_forces_override : bool = false

func test_overrides() -> void:
	if not is_inside_tree() or not get_tree():
		#push_error("Not inside tree, couldn't test method overrides.")
		return
	
	if not test_enter_tree_override:
		push_warning("_enter_tree() was overriden, but super._enter_tree() was not called. AeroBody3D may not work properly. " + get_script().get_path())
	if not test_ready_override:
		push_warning("_ready() was overriden, but super._ready() was not called. AeroBody3D may not work properly." + get_script().get_path())
	
	#wait 2 frames for validation
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	if can_process() and not test_physics_process_override:
		push_warning("_physics_process() was overriden, but super._physics_process() was not called. AeroBody3D may not work properly. " + get_script().get_path())
	
	if not Engine.is_editor_hint():
		if can_process() and not test_integrate_forces_override:
			push_warning("_integrate_forces() was overriden, but super._integrate_forces() was not called. AeroBody3D may not work properly." + get_script().get_path())
	
	

#debug
var linear_velocity_vector : AeroDebugVector3D
var angular_velocity_vector : AeroDebugVector3D

var force_debug_vector : AeroDebugVector3D
var torque_debug_vector : AeroDebugVector3D
var lift_debug_vector : AeroDebugVector3D
var drag_debug_vector : AeroDebugVector3D

var mass_debug_point : AeroDebugPoint3D
var thrust_debug_vector : AeroDebugVector3D

func _init():
	mass_debug_point = AeroDebugPoint3D.new(Color(1, 1, 0), debug_center_width, true, 5)
	mass_debug_point.name = "MassDebugPoint"
	
	force_debug_vector = AeroDebugVector3D.new(Color(1.0, 1.0, 1.0), debug_width, true, 1)
	force_debug_vector.name = "ForceDebugVector"
	
	torque_debug_vector = AeroDebugVector3D.new(Color(0.0, 0.0, 0.0), debug_width, true)
	torque_debug_vector.name = "TorqueDebugVector"
	
	lift_debug_vector = AeroDebugVector3D.new(Color(0, 1, 1), debug_width, true, 2)
	lift_debug_vector.name = "LiftDebugVector"
	
	drag_debug_vector = AeroDebugVector3D.new(Color(1, 0, 0), debug_width, true, 1)
	drag_debug_vector.name = "DragDebugVector"
	
	thrust_debug_vector = AeroDebugVector3D.new(Color(1, 0, 1), debug_width, true)
	thrust_debug_vector.name = "ThrustDebugVector"
	
	linear_velocity_vector = AeroDebugVector3D.new(Color(0, 0.5, 0.5), debug_width, false)
	linear_velocity_vector.name = "LinearVelocityVector"
	
	angular_velocity_vector = AeroDebugVector3D.new(Color(0, 0.333, 0), debug_width, false)
	angular_velocity_vector.name = "AngularVelocityVector"
	
	linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	
	#test that necessary functions (_ready(), _enter_tree(), _physics_process()
	test_overrides.call_deferred()

func _enter_tree() -> void:
	test_enter_tree_override = true
	
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
	test_ready_override = true
	
	add_child(mass_debug_point, INTERNAL_MODE_FRONT)
	
	mass_debug_point.add_child(force_debug_vector, INTERNAL_MODE_FRONT)
	mass_debug_point.add_child(lift_debug_vector, INTERNAL_MODE_FRONT)
	mass_debug_point.add_child(drag_debug_vector, INTERNAL_MODE_FRONT)
	mass_debug_point.add_child(thrust_debug_vector, INTERNAL_MODE_FRONT)
	
	mass_debug_point.add_child(torque_debug_vector, INTERNAL_MODE_FRONT)
	mass_debug_point.add_child(linear_velocity_vector, INTERNAL_MODE_FRONT)
	mass_debug_point.add_child(angular_velocity_vector, INTERNAL_MODE_FRONT)
	
	_update_debug_visibility()
	
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
	test_physics_process_override = true
	
	if show_debug and update_debug:
		_update_debug()

var _integrate_forces_time : float = 0.0
func _integrate_forces(state : PhysicsDirectBodyState3D) -> void:
	test_integrate_forces_override = true
	
	if is_overriding_body_sleep():
		interrupt_sleep()
	
	if state.sleeping or SUBSTEPS == 0:
		return
	
	var pre_time : int = Time.get_ticks_usec()
	integrator(state)
	var post_time : int = Time.get_ticks_usec()
	_integrate_forces_time = float(post_time - pre_time) * 0.001

func integrator(state : PhysicsDirectBodyState3D) -> void:
	last_linear_velocity = uncommitted_last_linear_velocity
	last_angular_velocity = uncommitted_last_angular_velocity
	
	current_gravity = state.total_gravity
	substep_delta = state.step / SUBSTEPS
	if Engine.is_editor_hint():
		center_of_mass = state.center_of_mass_local
	
	var total_force_and_torque := calculate_forces(substep_delta)
	state.apply_central_force(current_force)
	state.apply_torque(current_torque)
	
	linear_acceleration = (linear_velocity - last_linear_velocity) / state.step
	angular_acceleration = (angular_velocity - last_angular_velocity) / state.step
	
	uncommitted_last_linear_velocity = state.linear_velocity
	uncommitted_last_angular_velocity = state.angular_velocity

var linear_velocity_prediction : Vector3 = linear_velocity
var angular_velocity_prediction : Vector3 = angular_velocity
var substep_delta : float = get_physics_process_delta_time() / SUBSTEPS

func calculate_forces(substep_delta : float) -> PackedVector3Array:
	#eventually implement wind
	#wind = Vector3.ZERO
	air_velocity = -linear_velocity + wind
	air_speed = air_velocity.length()
	
	if has_node("/root/AeroUnits"):
		var _AeroUnits : Node = $"/root/AeroUnits"
		altitude = _AeroUnits.get_altitude(self)
		mach = _AeroUnits.speed_to_mach_at_altitude(air_speed, altitude)
		air_density = _AeroUnits.get_density_at_altitude(altitude)
		air_pressure = _AeroUnits.get_pressure_at_altitude(altitude)
	
	local_air_velocity = air_velocity * global_transform.basis
	local_angular_velocity = angular_velocity * global_transform.basis
	angle_of_attack = global_basis.y.angle_to(-air_velocity) - (PI / 2.0)
	sideslip_angle = global_basis.x.angle_to(air_velocity) - (PI / 2.0)
	bank_angle = global_rotation.z
	heading = global_rotation.y
	inclination = global_rotation.x
	
	var last_force_and_torque := PackedVector3Array([Vector3.ZERO, Vector3.ZERO])
	var total_force_and_torque := last_force_and_torque
	
	for substep : int in SUBSTEPS:
		#allow aeroinfluencers to update their own transforms before we calculate forces
		if not Engine.is_editor_hint():
			for influencer : AeroInfluencer3D in aero_influencers:
				influencer._update_transform_substep(substep_delta)
		
		linear_velocity_prediction = predict_linear_velocity(last_force_and_torque[0]) + current_gravity * PREDICTION_TIMESTEP_FRACTION
		angular_velocity_prediction = predict_angular_velocity(last_force_and_torque[1])
		last_force_and_torque = PackedVector3Array([Vector3.ZERO, Vector3.ZERO])
		for influencer : AeroInfluencer3D in aero_influencers:
			if influencer.disabled:
				continue
			
			var force_and_torque : PackedVector3Array = influencer._calculate_forces(substep_delta)
			
			#influencer._current_force = force_and_torque[0]
			#influencer._current_torque = force_and_torque[1]
			
			#sum the force and torque of each influencer
			last_force_and_torque[0] += force_and_torque[0]
			last_force_and_torque[1] += force_and_torque[1]
		
		#add to total forces
		total_force_and_torque[0] += last_force_and_torque[0]
		total_force_and_torque[1] += last_force_and_torque[1]
	
	total_force_and_torque[0] = total_force_and_torque[0] / SUBSTEPS
	total_force_and_torque[1] = total_force_and_torque[1] / SUBSTEPS
	
	current_force = total_force_and_torque[0]
	current_torque = total_force_and_torque[1]
	
	return total_force_and_torque

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

func get_drag_direction() -> Vector3:
	return air_velocity.normalized()

func get_linear_velocity() -> Vector3:
	return linear_velocity_prediction

func get_angular_velocity() -> Vector3:
	return angular_velocity_prediction

func get_linear_acceleration() -> Vector3:
	return (linear_velocity_prediction - last_linear_velocity) / substep_delta

func get_angular_acceleration() -> Vector3:
	return (angular_velocity_prediction - last_angular_velocity) / substep_delta

func get_control_command(axis_name : String = "") -> float:
	var control_component : AeroControlComponent = AeroNodeUtils.get_first_child_of_type(self, AeroControlComponent)
	if is_instance_valid(control_component):
		return control_component.get_control_command(axis_name)

	return 0.0

func is_overriding_body_sleep() -> bool:
	var overriding : bool = false
	for influencer : AeroInfluencer3D in aero_influencers:
		overriding = overriding or influencer.is_overriding_body_sleep()
	
	return overriding

func interrupt_sleep() -> void:
	sleeping = false

#debug


func _update_debug() -> void:
	_update_debug_visibility()
	_update_debug_scale()
	
	mass_debug_point.position = center_of_mass
	
	var linear_velocity_to_use := linear_velocity
	var angular_velocity_to_use := angular_velocity
	
	if Engine.is_editor_hint():
		linear_velocity_to_use = debug_linear_velocity
		angular_velocity_to_use = debug_angular_velocity
		
		var original_linear_velocity := linear_velocity
		var original_angular_velocity := angular_velocity
		linear_velocity = debug_linear_velocity
		angular_velocity = debug_angular_velocity
		substep_delta = 1.0 / float(ProjectSettings.get_setting("physics/common/physics_ticks_per_second")) / SUBSTEPS
		var last_force_and_torque := calculate_forces(substep_delta)
		
		linear_velocity = original_linear_velocity
		angular_velocity = original_angular_velocity
	
	
	force_debug_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(current_force, 2.0)
	torque_debug_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(current_torque, 2.0)
	
	linear_velocity_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(linear_velocity_to_use, 2.0)
	angular_velocity_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(angular_velocity_to_use, 2.0)
	
	#force and torque debug
	if aero_influencers.size() > 0:
		var get_aero_influencer_array : Callable = func x(influencer)-> Array[AeroInfluencer3D]:
			var influencers : Array[AeroInfluencer3D] = influencer.aero_influencers.duplicate()
			for _influencer : AeroInfluencer3D in influencer.aero_influencers:
				influencers.append_array(_influencer.aero_influencers)
			return influencers
		
		var recursive_aero_influencers : Array[AeroInfluencer3D] = get_aero_influencer_array.call(self)
		var amount_of_aero_influencers : int = recursive_aero_influencers.size()
		var force_sum := 0.0
		var force_vector_sum := Vector3.ZERO
		var force_position_sum := Vector3.ZERO
		var lift_sum := 0.0
		var lift_vector_sum := Vector3.ZERO
		var lift_position_sum := Vector3.ZERO
		var drag_sum := 0.0
		var drag_vector_sum := Vector3.ZERO
		var drag_position_sum := Vector3.ZERO
		var thrust_sum := 0.0
		var thrust_vector_sum := Vector3.ZERO
		var thrust_position_sum := Vector3.ZERO
		
		
		#this is flawed, it needs to be recursive, and use the current influencer's force instead of it's force sum of child influencers
		
		
		
		for influencer : AeroInfluencer3D in recursive_aero_influencers:
			#skip omitted or disabled influencers, and don't add them to the debug vectors
			if influencer.omit_from_debug or influencer.disabled:
				amount_of_aero_influencers -= 1
				continue
			
			var force_vector := influencer._current_force
			var force := force_vector.length()
			force_sum += force
			force_vector_sum += force_vector
			force_position_sum += influencer.relative_position * force
			
			var drag_vector : Vector3 = max(force_vector.dot(get_drag_direction()), 0.0) * get_drag_direction()
			var drag := drag_vector.length()
			drag_sum += drag
			drag_vector_sum += drag_vector
			drag_position_sum += influencer.relative_position * drag
			
			var lift_vector := force_vector - force_vector.dot(get_drag_direction()) * get_drag_direction()
			var lift := lift_vector.length()
			lift_sum += lift
			lift_vector_sum += lift_vector
			lift_position_sum += influencer.relative_position * lift
			
			var thrust_vector : Vector3 = min(force_vector.dot(get_drag_direction()), 0.0) * get_drag_direction()
			var thrust := thrust_vector.length()
			thrust_sum += thrust
			thrust_vector_sum += thrust_vector
			thrust_position_sum += influencer.relative_position * thrust
		
		force_debug_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(force_vector_sum, debug_scaling_factor) * debug_scale
		if not is_equal_approx(force_sum, 0.0):
			force_debug_vector.position = global_transform.basis.inverse() * force_position_sum / amount_of_aero_influencers / (force_sum / amount_of_aero_influencers)
		drag_debug_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(drag_vector_sum, debug_scaling_factor) * debug_scale
		if not is_equal_approx(drag_sum, 0.0):
			drag_debug_vector.position = global_transform.basis.inverse() * drag_position_sum / amount_of_aero_influencers / (drag_sum / amount_of_aero_influencers)
		lift_debug_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(lift_vector_sum, debug_scaling_factor) * debug_scale
		if not is_equal_approx(lift_sum, 0.0):
			lift_debug_vector.position = global_transform.basis.inverse() * lift_position_sum / amount_of_aero_influencers / (lift_sum / amount_of_aero_influencers)
		thrust_debug_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(thrust_vector_sum, debug_scaling_factor) * debug_scale
		if not is_equal_approx(thrust_sum, 0.0):
			thrust_debug_vector.position = global_transform.basis.inverse() * thrust_position_sum / amount_of_aero_influencers / (thrust_sum / amount_of_aero_influencers)
	
	
	for influencer : AeroInfluencer3D in aero_influencers:
		influencer.update_debug_vectors()

func _update_debug_visibility() -> void:
	#update aerosurface visibility
	
	for influencer : AeroInfluencer3D in aero_influencers:
		influencer.update_debug_visibility(show_debug and show_wing_debug_vectors)
	
	#update self visibility
	force_debug_vector.visible = show_debug
	torque_debug_vector.visible = show_debug and show_torque
	
	linear_velocity_vector.visible = show_debug and show_linear_velocity
	angular_velocity_vector.visible = show_debug and show_angular_velocity

	lift_debug_vector.visible = show_debug and show_center_of_lift
	drag_debug_vector.visible = show_debug and show_center_of_drag

	mass_debug_point.visible = show_debug and show_center_of_mass
	thrust_debug_vector.visible = show_debug and show_center_of_thrust



func _update_debug_scale() -> void:
	for influencer : AeroInfluencer3D in aero_influencers:
		influencer.update_debug_scale(debug_scale, influencer_debug_width, debug_scaling_factor)
	
	linear_velocity_vector.width = debug_width
	angular_velocity_vector.width = debug_width
	
	force_debug_vector.width = debug_width
	torque_debug_vector.width = debug_width
	lift_debug_vector.width = debug_width
	drag_debug_vector.width = debug_width
	
	mass_debug_point.width = debug_center_width
	thrust_debug_vector.width = debug_width
