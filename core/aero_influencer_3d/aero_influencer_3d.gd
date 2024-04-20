@tool
extends Node3D
class_name AeroInfluencer3D

const AeroNodeUtils = preload("../../utils/node_utils.gd")

@export var disabled : bool = false

@export_group("Debug")
@export var omit_from_debug : bool = false
@export var debug_scale : float = 0.1
@export var debug_width : float = 0.05
@export var show_debug : bool = false

@export var show_force : bool = true
@export var show_torque : bool = true

var aero_body : AeroBody3D
var aero_influencers : Array[AeroInfluencer3D] = []

var override_body_sleep : bool = false:
	set(x):
		override_body_sleep = x
		
		if override_body_sleep and aero_body:
			aero_body.sleeping = false

var world_air_velocity := Vector3.ZERO
var linear_velocity := Vector3.ZERO
var angular_velocity := Vector3.ZERO
@onready var last_linear_velocity : Vector3 = linear_velocity
@onready var last_angular_velocity : Vector3 = angular_velocity
var air_density := 0.0
var relative_position := Vector3.ZERO
var altitude := 0.0

#Calculating air velocity relative to the surface's coordinate system.
var local_air_velocity := Vector3.ZERO
var air_speed := 0.0

var mach : float = 0.0
var dynamic_pressure : float = 0.0

var _current_force : Vector3 = Vector3.ZERO
var _current_torque : Vector3 = Vector3.ZERO

var force_debug_vector : AeroDebugVector3D
var torque_debug_vector : AeroDebugVector3D

func _init():
	#initialize debug vectors
	force_debug_vector = AeroDebugVector3D.new(Color(1, 1, 1), debug_width, true)
	force_debug_vector.visible = false
	force_debug_vector.sorting_offset = 0.02
	add_child(force_debug_vector, INTERNAL_MODE_FRONT)
	
	torque_debug_vector = AeroDebugVector3D.new(Color(0, 0, 0))
	torque_debug_vector.visible = false
	torque_debug_vector.sorting_offset = 0.01
	add_child(torque_debug_vector, INTERNAL_MODE_FRONT)

func _enter_tree() -> void:
	AeroNodeUtils.connect_signal_safe(self, "child_entered_tree", on_child_enter_tree, 0, true)
	AeroNodeUtils.connect_signal_safe(self, "child_exiting_tree", on_child_exit_tree, 0, true)

func on_child_enter_tree(node : Node) -> void:
	if node is AeroInfluencer3D:
		aero_influencers.append(node)
		node.aero_body = aero_body

func on_child_exit_tree(node : Node) -> void:
	if node is AeroInfluencer3D and aero_influencers.has(node):
		aero_influencers.erase(node)
		node.aero_body = null

func _physics_process(delta: float) -> void:
	update_debug_vectors()
	
	if is_overriding_body_sleep() and aero_body:
		aero_body.sleeping = false

func _calculate_forces(substep_delta : float = 0.0) -> PackedVector3Array:
	linear_velocity = get_linear_velocity()
	angular_velocity = get_angular_velocity()
	
	relative_position = get_relative_position()
	world_air_velocity = get_world_air_velocity()
	air_speed = world_air_velocity.length()
	air_density = aero_body.air_density
	altitude = aero_body.altitude
	local_air_velocity = global_transform.basis.inverse() * world_air_velocity
	mach = AeroUnits.speed_to_mach_at_altitude(world_air_velocity.length(), altitude)
	dynamic_pressure = 0.5 * AeroUnits.get_density_at_altitude(altitude) * (air_speed * air_speed)
	
	var force : Vector3 = Vector3.ZERO
	var torque : Vector3 = Vector3.ZERO
	
	for influencer : AeroInfluencer3D in aero_influencers:
		var force_and_torque : PackedVector3Array = influencer._calculate_forces(substep_delta)
		
		force += force_and_torque[0]
		torque += force_and_torque[1]
	
	torque += relative_position.cross(force)
	
	_current_force = force
	_current_torque = torque
	
	return PackedVector3Array([force, torque])

#virtual
func _update_transform_substep(substep_delta : float) -> void:
	for influencer : AeroInfluencer3D in aero_influencers:
		influencer._update_transform_substep(substep_delta)

#virtual
func is_overriding_body_sleep() -> bool:
	var overriding : bool = false
	for influencer : AeroInfluencer3D in aero_influencers:
		overriding = overriding or influencer.is_overriding_body_sleep()
	
	return overriding

func get_relative_position() -> Vector3:
	return get_parent().get_relative_position() + (get_parent().global_basis * position)

func get_world_air_velocity() -> Vector3:
	return -get_linear_velocity()

func get_linear_velocity() -> Vector3:
	return get_parent().get_linear_velocity() + get_parent().get_angular_velocity().cross(get_parent().global_basis * position)

func get_angular_velocity() -> Vector3:
	return get_parent().get_angular_velocity()

#virtual
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



#debug


func update_debug_visibility(_show_debug : bool = false) -> void:
	for i : AeroInfluencer3D in aero_influencers:
		i.update_debug_visibility(_show_debug)
	
	show_debug = _show_debug
	
	force_debug_vector.visible = show_debug and show_force
	torque_debug_vector.visible = show_debug and show_torque

func update_debug_scale(_scale : float, _width : float) -> void:
	for i : AeroInfluencer3D in aero_influencers:
		i.update_debug_scale(_scale, _width)
	
	debug_scale = _scale
	debug_width = _width
	
	force_debug_vector.width = debug_width
	torque_debug_vector.width = debug_width

func update_debug_vectors() -> void:
	for i : AeroInfluencer3D in aero_influencers:
		i.update_debug_vectors()
	
	#don't update invisible vectors
	if force_debug_vector.visible:
		force_debug_vector.value = global_transform.basis.inverse() * AeroBody3D.log_with_base(_current_force, 2.0) * debug_scale
	if torque_debug_vector.visible:
		torque_debug_vector.value = global_transform.basis.inverse() * AeroBody3D.log_with_base(_current_torque, 2.0) * debug_scale
