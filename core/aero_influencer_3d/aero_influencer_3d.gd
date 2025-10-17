@tool
extends Node3D
class_name AeroInfluencer3D
## Base class for all aerodynamic nodes.
##
## This class does not directly apply any forces to a body, requiring an [AeroBody3D] parent to 
## manage the simulation.[br]
## [br]
## [AeroInfluencer3D]s can also be arranged hierarchically, as long as they have a single 
## [AeroBody3D] as an ancestor node, and all other ancestors are [AeroInfluencer3D]s.[br]
## [br]
## Example node hierarchy:
## [codeblock]
## v AeroBody3D
## | v ManualAeroSurface3D
## | | > ManualAeroSurface3D
## | | # this node works, because it has an an ancestor AeroBody3D, and all other ancestor nodes
## | | # are AerInfluencer3D derived classes
## [/codeblock]


const AeroMathUtils = preload("../../utils/math_utils.gd")
const AeroNodeUtils = preload("../../utils/node_utils.gd")

## If true, this AeroInfluencer3D will not have any effect on the simulation.
@export var disabled : bool = false
## Allows the current AeroInfluencer to prevent/interrupt the AeroBody's sleep. This is useful for thrust-providing
## nodes like AeroMovers or Propellers. Sleep is only interrupted if the AeroInfluencer sub-class triggers it.
@export var can_override_body_sleep : bool = true

@export_enum("None", "X", "Y", "Z") var mirror_axis : int = 0:
	set(x):
		mirror_axis = x
		
		if mirror_duplicate: 
			mirror_duplicate.queue_free()
		
		if mirror_axis == 0 or is_duplicate or not is_inside_tree():
			return # no duplication
		
		mirror_axis = 0
		mirror_duplicate = duplicate()
		mirror_duplicate.is_duplicate = true
		mirror_duplicate.name = name + "Mirror"
		mirror_axis = x
		mirror_duplicate.mirror_axis = x
		
		
		match mirror_axis:
			1: #X
				mirror_duplicate.position *= Vector3(-1, 1, 1)
				mirror_duplicate.basis = Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)) * mirror_duplicate.basis
			2: #Y
				mirror_duplicate.position *= Vector3(1, -1, 1)
				mirror_duplicate.basis = Basis(Vector3(1, 0, 0), Vector3(0, -1, 0), Vector3(0, 0, 1)) * mirror_duplicate.basis
			3: #Z
				mirror_duplicate.position *= Vector3(1, 1, -1)
				mirror_duplicate.basis = Basis(Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1)) * mirror_duplicate.basis
		
		get_parent().add_child(mirror_duplicate)
var is_duplicate : bool = false
var mirror_duplicate : AeroInfluencer3D = null


@export_group("Actuation Control")
## Config that controls how this [AeroInfluencer3D] will rotate in response to control commands.
@export var actuation_config : AeroInfluencerControlConfig
## Rotation order used when doing control rotations.
@export_enum("XYZ", "XZY", "YXZ", "YZX", "ZXY", "ZYX") var control_rotation_order : int = 0
@export_subgroup("")

@export_group("Debug")
## If enabled, this AeroInfluencer3D is omitted from AeroBody3D debug calculations.
@export var omit_from_debug : bool = false
var debug_scale : float = 0.1
var debug_scaling_factor : float = 2.0
var debug_width : float = 0.05
var show_debug : bool = false

## Controls visibility of the AeroInfluencer3D's force debug vector.
@export var show_force : bool = true
## Controls visibility of the AeroInfluencer3D's torque debug vector.
@export var show_torque : bool = false
## Controls visibility of the AeroInfluencer3D's lift debug vector
@export var show_lift : bool = true
## Controls visibility of the AeroInfluencer3D's drag debug vector
@export var show_drag : bool = true
## Controls visibility of the AeroInfluencer3D's thrust debug vector
@export var show_thrust : bool = false

var aero_body : AeroBody3D
var aero_influencers : Array[AeroInfluencer3D] = []

@onready var default_transform := transform
var world_air_velocity := Vector3.ZERO
var linear_velocity := Vector3.ZERO:
	get = get_linear_velocity
var angular_velocity := Vector3.ZERO:
	get = get_angular_velocity
@onready var last_linear_velocity : Vector3 = linear_velocity
@onready var last_angular_velocity : Vector3 = angular_velocity
var air_density := 1.225
var relative_position := Vector3.ZERO
var altitude := 0.0

#Calculating air velocity relative to the surface's coordinate system.
var local_air_velocity := Vector3.ZERO
#The direction which drag force will be applied. This is equal to [code]world_air_velocity.normalized()[/code]
var drag_direction := Vector3.ZERO
var air_speed := 0.0

var mach : float = 0.0
#this represents the mass of air that affects the AeroInfluencer per square meter of area.
var dynamic_pressure : float = 0.0

var _current_force : Vector3 = Vector3.ZERO
var _current_torque : Vector3 = Vector3.ZERO

var force_debug_vector : AeroDebugVector3D
var torque_debug_vector : AeroDebugVector3D
var lift_debug_vector : AeroDebugVector3D
var drag_debug_vector : AeroDebugVector3D
var thrust_debug_vector : AeroDebugVector3D

func _init():
	#initialize debug vectors
	force_debug_vector = AeroDebugVector3D.new(Color(1, 1, 1), debug_width, true, 2)
	force_debug_vector.visible = false
	
	torque_debug_vector = AeroDebugVector3D.new(Color(0, 0, 0), debug_width, false, 1)
	torque_debug_vector.visible = false
	
	lift_debug_vector = AeroDebugVector3D.new(Color(0, 0, 1), debug_width, false, 4)
	lift_debug_vector.visible = false
	
	drag_debug_vector = AeroDebugVector3D.new(Color(1, 0, 0), debug_width, false, 3)
	drag_debug_vector.visible = false
	
	thrust_debug_vector = AeroDebugVector3D.new(Color(1.0, 0.0, 1.0), debug_width, false, 3)
	thrust_debug_vector.visible = false

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_TRANSFORM_CHANGED:
			mirror_axis = mirror_axis

func _ready() -> void:
	if not Engine.is_editor_hint():
		if actuation_config:
			actuation_config = actuation_config.duplicate(true)
	
	add_child(force_debug_vector, INTERNAL_MODE_FRONT)
	add_child(torque_debug_vector, INTERNAL_MODE_FRONT)
	add_child(lift_debug_vector, INTERNAL_MODE_FRONT)
	add_child(drag_debug_vector, INTERNAL_MODE_FRONT)
	add_child(thrust_debug_vector, INTERNAL_MODE_FRONT)

func _enter_tree() -> void:
	AeroNodeUtils.connect_signal_safe(self, "child_entered_tree", on_child_enter_tree, 0, true)
	AeroNodeUtils.connect_signal_safe(self, "child_exiting_tree", on_child_exit_tree, 0, true)
	
	set_deferred("mirror_axis", mirror_axis) #ensures that mirrored version is reliably created when nodes are changed

func _exit_tree() -> void:
	if mirror_duplicate: 
		mirror_duplicate.queue_free()

func on_child_enter_tree(node : Node) -> void:
	if node is AeroInfluencer3D:
		aero_influencers.append(node)
		node.aero_body = aero_body

func on_child_exit_tree(node : Node) -> void:
	if node is AeroInfluencer3D and aero_influencers.has(node):
		aero_influencers.erase(node)
		node.aero_body = null

var last_transform : Transform3D = Transform3D()
func _physics_process(delta : float) -> void:
	if Engine.is_editor_hint():
		return
	if not transform == last_transform:
		aero_body.interrupt_sleep()
	last_transform = transform

##
func _calculate_forces(substep_delta : float = 0.0) -> PackedVector3Array:
	linear_velocity = get_linear_velocity()
	angular_velocity = get_angular_velocity()
	
	relative_position = get_relative_position()
	world_air_velocity = get_world_air_velocity()
	air_speed = world_air_velocity.length()
	air_density = aero_body.air_density
	altitude = aero_body.altitude
	dynamic_pressure = 0.5 * air_density * air_speed * air_speed
	drag_direction = world_air_velocity.normalized()
	local_air_velocity = global_transform.basis.inverse() * world_air_velocity
	if has_node("/root/AeroUnits"):
		var _AeroUnits : Node = $"/root/AeroUnits"
		mach = _AeroUnits.speed_to_mach_at_altitude(world_air_velocity.length(), altitude)
	
	_current_force = Vector3.ZERO
	_current_torque = Vector3.ZERO
	
	var force : Vector3 = Vector3.ZERO
	var torque : Vector3 = Vector3.ZERO
	
	for influencer : AeroInfluencer3D in aero_influencers:
		var force_and_torque : PackedVector3Array = influencer._calculate_forces(substep_delta)
		
		force += force_and_torque[0]
		torque += force_and_torque[1]
	
	return PackedVector3Array([force, torque])

## Intended to be overridden.[br]
## [br]
## This function runs during the aerodynamic update, before any forces are calculated.[br]
## [br]
## Be sure to call [code]super(substep_delta)[/code] at the end of the overridden function to retain 
## existing functionality.
func _update_transform_substep(substep_delta : float) -> void:
	if disabled:
		return
	
	for influencer : AeroInfluencer3D in aero_influencers:
		influencer._update_transform_substep(substep_delta)
	
	_update_control_transform(substep_delta)
## Intended to be overridden.[br]
## [br]
## This function runs during the aerodynamic update, before any forces are calculated, at the end of
## [method AeroInfluencer._update_transform_substep].[br]
## [br]
## This function is where control-related movements should be applied in extended classes.[br]
## [br]
## Be sure to call [code]super(substep_delta)[/code] at the end of the overridden function to retain 
## existing functionality.
func _update_control_transform(substep_delta : float) -> void:
	var actuation_value := Vector3.ZERO
	if actuation_config:
		actuation_value = actuation_config.update(self, substep_delta)
	
	basis = default_transform.basis * Basis().from_euler(actuation_value, control_rotation_order)

## Intended to be overridden.[br]
## [br]
## This function should be extended for AeroInfluencer3D derived classes that produce forces that
## might cause the [AeroBody3D] to move when sitting still.[br]
## [br]
## For example, a propeller would override body sleep, as it can create forces when the [AeroBody3D]
## is sitting still.[br]
## [br]
## Ensure that overridden functions end with [code]return custom_criteria or super()[/code] to
## retaun existing functionality.
func is_overriding_body_sleep() -> bool:
	if not can_override_body_sleep:
		return false
	
	var overriding : bool = false
	
	for influencer : AeroInfluencer3D in aero_influencers:
		overriding = overriding or influencer.is_overriding_body_sleep()
	
	return overriding

func get_relative_position() -> Vector3:
	return get_parent().get_relative_position() + (get_parent().global_basis * position)

func get_world_air_velocity() -> Vector3:
	return -get_linear_velocity()

func get_linear_velocity() -> Vector3:
	return get_parent().linear_velocity + get_parent().angular_velocity.cross(get_parent().global_basis * position)

func get_angular_velocity() -> Vector3:
	return get_parent().angular_velocity

func get_centrifugal_offset() -> Vector3:
	return position

func get_linear_acceleration() -> Vector3:
	var position_in_global_rotation : Vector3 = get_parent().global_basis * position
	
	var centrifugal_offset : Vector3 = get_parent().global_basis * get_centrifugal_offset()
	
	var axis : Vector3 = angular_velocity.normalized()
	var nearest_point_on_line : Vector3 = axis * centrifugal_offset.dot(axis.normalized())
	var rotation_radius : float = nearest_point_on_line.distance_to(centrifugal_offset)
	var acceleration_axis : Vector3 = nearest_point_on_line - centrifugal_offset
	
	var centripetal_acceleration_force : float = get_parent().get_angular_velocity().length_squared() * rotation_radius
	var centripetal_acceleration_vector : Vector3 = centripetal_acceleration_force * acceleration_axis
	
	return get_parent().get_linear_acceleration() + get_parent().get_angular_acceleration().cross(centrifugal_offset) + centripetal_acceleration_vector

func get_angular_acceleration() -> Vector3:
	return get_parent().get_angular_acceleration()



## Used for input propagation.
func get_control_command(axis_name : String = "") -> float:
	return get_parent().get_control_command(axis_name)

#debug


func update_debug_visibility(_show_debug : bool = false) -> void:
	for i : AeroInfluencer3D in aero_influencers:
		i.update_debug_visibility(_show_debug)
	
	show_debug = _show_debug
	
	force_debug_vector.visible = show_debug and show_force
	torque_debug_vector.visible = show_debug and show_torque
	lift_debug_vector.visible = show_debug and show_lift
	drag_debug_vector.visible = show_debug and show_drag
	thrust_debug_vector.visible = show_debug and show_thrust

func update_debug_scale(_scale : float, _width : float, _debug_scaling_factor : float) -> void:
	for i : AeroInfluencer3D in aero_influencers:
		i.update_debug_scale(_scale, _width, _debug_scaling_factor)
	
	debug_scale = _scale
	debug_width = _width
	debug_scaling_factor = _debug_scaling_factor
	
	force_debug_vector.width = debug_width
	torque_debug_vector.width = debug_width
	lift_debug_vector.width = debug_width
	drag_debug_vector.width = debug_width
	thrust_debug_vector.width = debug_width

func update_debug_vectors() -> void:
	
	#don't update invisible vectors
	if force_debug_vector.visible:
		force_debug_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(_current_force, debug_scaling_factor) * debug_scale
	if torque_debug_vector.visible:
		torque_debug_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(_current_torque, debug_scaling_factor) * debug_scale
	if lift_debug_vector:
		var lift := _current_force - _current_force.dot(drag_direction) * drag_direction
		lift_debug_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(lift, debug_scaling_factor) * debug_scale
	if drag_debug_vector:
		var drag : Vector3 = max(_current_force.dot(drag_direction), 0.0) * drag_direction
		drag_debug_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(drag, debug_scaling_factor) * debug_scale
	if thrust_debug_vector:
		
		#do this calculation relative to torque/angular velocity instead of drag
		var thrust : Vector3 = min(_current_force.dot(drag_direction), 0.0) * drag_direction
		thrust_debug_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(thrust, debug_scaling_factor) * debug_scale
		
	for i : AeroInfluencer3D in aero_influencers:
		i.update_debug_vectors()


#this was a cool system, but it's pretty unnecessary. Will probably reuse in the future for automatic update conversions.
#var updated_properties := get_property_conversion_info()
#func get_property_conversion_info() -> Dictionary:
	##
	#
	##return super.get_property_conversion_info().merged({
	#return {
	##input
	#"enable_automatic_control" : [TYPE_BOOL, \
	#func(value) -> void:
		#if value and not is_instance_valid(actuation_config):
			#actuation_config = AeroInfluencerControlConfig.new()
			#actuation_config.enable_control = value
	#],
	#"max_actuation" : [TYPE_VECTOR3, \
	#func(value) -> void:
		#if not is_instance_valid(actuation_config):
			#actuation_config = AeroInfluencerControlConfig.new()
		#actuation_config.max_value = value
	#],
	#"limit_actuation_speed" : [TYPE_BOOL, \
	#func(value) -> void:
		#if not is_instance_valid(actuation_config):
			#actuation_config = AeroInfluencerControlConfig.new()
		#actuation_config.limit_movement_speed = value
	#],
	#"actuation_speed" : [TYPE_FLOAT, \
	#func(value) -> void:
		#if not is_instance_valid(actuation_config):
			#actuation_config = AeroInfluencerControlConfig.new()
		#actuation_config.movement_speed = value
	#],
	#"pitch_contribution" : [TYPE_VECTOR3, \
	#func(value) -> void:
		#if not is_instance_valid(actuation_config):
			#actuation_config = AeroInfluencerControlConfig.new()
		#if not is_instance_valid(actuation_config.pitch_config):
			#actuation_config.pitch_config = AeroInfluencerControlAxisConfig.new()
		#actuation_config.pitch_config.contribution = value
	#],
	#"pitch_easing" : [TYPE_FLOAT, \
	#func(value) -> void:
		#if not is_instance_valid(actuation_config):
			#actuation_config = AeroInfluencerControlConfig.new()
		#if not is_instance_valid(actuation_config.pitch_config):
			#actuation_config.pitch_config = AeroInfluencerControlAxisConfig.new()
		#actuation_config.pitch_config.easing = value
	#],
	#"yaw_contribution" : [TYPE_VECTOR3, \
	#func(value) -> void:
		#if not is_instance_valid(actuation_config):
			#actuation_config = AeroInfluencerControlConfig.new()
		#if not is_instance_valid(actuation_config.yaw_config):
			#actuation_config.yaw_config = AeroInfluencerControlAxisConfig.new()
		#actuation_config.yaw_config.contribution = value
	#],
	#"yaw_easing" : [TYPE_FLOAT, \
	#func(value) -> void:
		#if not is_instance_valid(actuation_config):
			#actuation_config = AeroInfluencerControlConfig.new()
		#if not is_instance_valid(actuation_config.yaw_config):
			#actuation_config.yaw_config = AeroInfluencerControlAxisConfig.new()
		#actuation_config.yaw_config.easing = value
	#],
	#"roll_contribution" : [TYPE_VECTOR3, \
	#func(value) -> void:
		#if not is_instance_valid(actuation_config):
			#actuation_config = AeroInfluencerControlConfig.new()
		#if not is_instance_valid(actuation_config.roll_config):
			#actuation_config.roll_config = AeroInfluencerControlAxisConfig.new()
		#actuation_config.roll_config.contribution = value
	#],
	#"roll_easing" : [TYPE_FLOAT, \
	#func(value) -> void:
		#if not is_instance_valid(actuation_config):
			#actuation_config = AeroInfluencerControlConfig.new()
		#if not is_instance_valid(actuation_config.roll_config):
			#actuation_config.roll_config = AeroInfluencerControlAxisConfig.new()
		#actuation_config.roll_config.easing = value
	#],
	#"brake_contribution" : [TYPE_VECTOR3, \
	#func(value) -> void:
		#if not is_instance_valid(actuation_config):
			#actuation_config = AeroInfluencerControlConfig.new()
		#if not is_instance_valid(actuation_config.brake_config):
			#actuation_config.brake_config = AeroInfluencerControlAxisConfig.new()
		#actuation_config.brake_config.contribution = value
	#],
	#"brake_easing" : [TYPE_FLOAT, \
	#func(value) -> void:
		#if not is_instance_valid(actuation_config):
			#actuation_config = AeroInfluencerControlConfig.new()
		#if not is_instance_valid(actuation_config.brake_config):
			#actuation_config.brake_config = AeroInfluencerControlAxisConfig.new()
		#actuation_config.brake_config.easing = value
	#],
	#"throttle_contribution" : [TYPE_VECTOR3, \
	#func(value) -> void:
		#if not is_instance_valid(actuation_config):
			#actuation_config = AeroInfluencerControlConfig.new()
		#if not is_instance_valid(actuation_config.throttle_config):
			#actuation_config.throttle_config = AeroInfluencerControlAxisConfig.new()
		#actuation_config.throttle_config.contribution = value
	#],
	#"throttle_easing" : [TYPE_FLOAT, \
	#func(value) -> void:
		#if not is_instance_valid(actuation_config):
			#actuation_config = AeroInfluencerControlConfig.new()
		#if not is_instance_valid(actuation_config.throttle_config):
			#actuation_config.throttle_config = AeroInfluencerControlAxisConfig.new()
		#actuation_config.throttle_config.easing = value
	#],
	#
	#}#)
#
#func _get_property_list() -> Array[Dictionary]:
	#var array : Array[Dictionary] = []
	#var updated_properties := get_property_conversion_info()
	#for property in updated_properties.keys():
		#var property_info : Array = updated_properties[property]
		#array.append({
			#"name" : property,
			#"type" : property_info[0],
			#"usage" : 0,
		#})
	#
	#return array
#
#func _set(property: StringName, value: Variant) -> bool:
	#if property in updated_properties.keys():
		#var property_info : Array = updated_properties[property]
		#if property_info.size() >= 2:
			##print("Calling %s with value %s"  %[property, value])
			#property_info[1].call(value)
		#
		#return true
	#return false
