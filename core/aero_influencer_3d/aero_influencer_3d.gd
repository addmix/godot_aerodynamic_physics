@tool
extends Node3D
class_name AeroInfluencer3D

@export_group("Debug")
@export var debug_scale : float = 0.001
@export var debug_width : float = 0.05
@export var show_debug : bool = false

@export var show_force : bool = true
@export var show_torque : bool = true

var world_air_velocity := Vector3.ZERO
var world_angular_velocity := Vector3.ZERO
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

func _physics_process(delta: float) -> void:
	update_debug_vectors()

func _calculate_forces(_world_air_velocity : Vector3, _world_angular_velocity : Vector3, _air_density : float, _relative_position : Vector3, _altitude : float, substep_delta : float = 0.0) -> PackedVector3Array:
	world_air_velocity = _world_air_velocity
	world_angular_velocity = _world_angular_velocity
	air_speed = world_air_velocity.length()
	#prevent crash when sitting still
	if is_equal_approx(air_speed, 0.0):
		return PackedVector3Array([Vector3.ZERO, Vector3.ZERO])
	
	air_density = _air_density
	relative_position = _relative_position
	altitude = _altitude
	
	local_air_velocity = global_transform.basis.inverse() * world_air_velocity
	mach = AeroUnits.speed_to_mach_at_altitude(world_air_velocity.length(), altitude)
	dynamic_pressure = 0.5 * AeroUnits.get_density_at_altitude(altitude) * (air_speed * air_speed)
	
	return PackedVector3Array([Vector3.ZERO, Vector3.ZERO])

#virtual
func _update_transform_substep(substep_delta : float) -> void:
	pass

func update_debug_visibility(_show_debug : bool = false) -> void:
	show_debug = _show_debug

	#check that debug vectors exist
	if force_debug_vector and torque_debug_vector:
		force_debug_vector.visible = show_debug and show_force
		torque_debug_vector.visible = show_debug and show_torque

func update_debug_scale(_scale : float, _width : float) -> void:
	debug_scale = _scale
	debug_width = _width
	
	force_debug_vector.width = debug_width
	torque_debug_vector.width = debug_width

func update_debug_vectors() -> void:
	#check that debug vectors exist
	if !force_debug_vector or !torque_debug_vector:
		return
	
	#don't update invisible vectors
	if force_debug_vector.visible:
		force_debug_vector.value = global_transform.basis.inverse() * _current_force * debug_scale
	if torque_debug_vector.visible:
		torque_debug_vector.value = global_transform.basis.inverse() * _current_torque * debug_scale
