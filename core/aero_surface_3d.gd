@tool
extends Node3D
class_name AeroSurface3D

@export var wing_config : AeroSurfaceConfig = AeroSurfaceConfig.new():
	set(value):
		wing_config = value
		if wing_config == null:
			return
		if not wing_config.is_connected("changed", update_gizmos):
			wing_config.changed.connect(update_gizmos)
			update_gizmos()

@export_category("Debug")
@export var debug_scale : float = 0.001
@export var show_debug : bool = false
@export var show_lift : bool = true
@export var show_drag : bool = true
@export var show_airflow : bool = true

@export_category("")
@export var flap_angle : float = 0.0:
	set(value):
		flap_angle = clamp(value, deg_to_rad(-50), deg_to_rad(50))

var world_air_velocity := Vector3.ZERO
var air_density := 0.0
var air_pressure := 0.0
var relative_position := Vector3.ZERO
var altitude := 0.0

#Calculating air velocity relative to the surface's coordinate system.
var air_velocity := Vector3.ZERO
var air_speed := 0.0
var sweep_angle := 0.0
var drag_direction := Vector3.ZERO
var lift_direction := Vector3.ZERO

var mach : float = 0.0
var dynamic_pressure : float = 0.0
var angle_of_attack : float = 0.0
var area : float = wing_config.chord * wing_config.span
var projected_wing_area : float = 0.0

var _current_lift : Vector3
var _current_drag : Vector3
var _current_torque : Vector3

var lift_debug_vector : Vector3D
var drag_debug_vector : Vector3D
var airflow_debug_vector : Vector3D

func _enter_tree() -> void:
	#initialize signal connections from resources
	if wing_config != null:
		if not wing_config.is_connected("changed", update_gizmos):
			wing_config.changed.connect(update_gizmos)
			update_gizmos()

	#initialize debug vectors
	lift_debug_vector = Vector3D.new(Color(0, 0, 1))
	lift_debug_vector.visible = false
	add_child(lift_debug_vector)
	drag_debug_vector = Vector3D.new(Color(1, 0, 0))
	drag_debug_vector.visible = false
	add_child(drag_debug_vector)
	airflow_debug_vector = Vector3D.new(Color(0, 1, 0))
	airflow_debug_vector.visible = false
	add_child(airflow_debug_vector)

func _physics_process(delta: float) -> void:
	update_debug_vectors()

func calculate_forces(_world_air_velocity : Vector3, _air_density : float, _air_pressure : float, _relative_position : Vector3, _altitude : float) -> PackedVector3Array:
	world_air_velocity = _world_air_velocity
	air_density = _air_density
	air_pressure = _air_pressure
	relative_position = _relative_position
	altitude = _altitude

	#calculate some common values, some necessary for debugging
	#air velocity in local space
	air_velocity = global_transform.basis.inverse() * world_air_velocity
	air_speed = air_velocity.length()
	sweep_angle =  abs(atan2(air_velocity.z, air_velocity.x) / PI - 0.5)
	drag_direction = global_transform.basis * (air_velocity.normalized()).normalized()
	var right_facing_air_vector : Vector3 = world_air_velocity.cross(-global_transform.basis.y).normalized()
	lift_direction = drag_direction.cross(right_facing_air_vector).normalized()
	mach = AeroUnits.speed_to_mach_at_altitude(air_velocity.length(), altitude)
	dynamic_pressure = 0.5 * AeroUnits.get_density_at_altitude(altitude) * (air_speed * air_speed)
	angle_of_attack = atan2(air_velocity.y, air_velocity.z)
	area = wing_config.chord * wing_config.span
	projected_wing_area = abs(wing_config.span * wing_config.chord * sin(angle_of_attack))

	return PackedVector3Array([Vector3.ZERO, Vector3.ZERO])

func update_debug_visibility(_show_debug : bool = false, _show_lift : bool = false, _show_drag : bool = false, _show_airflow : bool = false) -> void:
	show_debug = _show_debug
	show_lift = _show_lift
	show_drag = _show_drag
	show_airflow = _show_airflow

	#check that debug vectors exist
	if !lift_debug_vector or !drag_debug_vector or !airflow_debug_vector:
		return
	lift_debug_vector.visible = show_debug and show_lift
	drag_debug_vector.visible = show_debug and show_drag
	airflow_debug_vector.visible = show_debug and show_airflow


func update_debug_vectors() -> void:
	#check that debug vectors exist
	if !lift_debug_vector or !drag_debug_vector or !airflow_debug_vector:
		return
	#not ensuring proper transforms when aero_surface has a parent that is not aerobody
	lift_debug_vector.value = global_transform.basis.inverse() * _current_lift * debug_scale
	drag_debug_vector.value = global_transform.basis.inverse() * _current_drag * debug_scale
	airflow_debug_vector.value = global_transform.basis.inverse() * air_velocity * debug_scale
