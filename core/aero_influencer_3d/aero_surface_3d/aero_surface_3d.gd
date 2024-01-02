@tool
extends AeroInfluencer3D
class_name AeroSurface3D

@export var wing_config : AeroSurfaceConfig = AeroSurfaceConfig.new():
	set(value):
		wing_config = value
		if wing_config == null:
			return
		if not wing_config.is_connected("changed", update_gizmos):
			wing_config.changed.connect(update_gizmos)
			update_gizmos()

@export_group("Debug")
@export var show_lift : bool = true
@export var show_drag : bool = true

var angle_of_attack : float = 0.0
var sweep_angle := 0.0

var area : float = wing_config.chord * wing_config.span
var projected_wing_area : float = 0.0

var lift_direction := Vector3.ZERO
var lift_force : float = 0.0
var drag_direction := Vector3.ZERO
var drag_force : float = 0.0

var _current_lift : Vector3
var _current_drag : Vector3

var lift_debug_vector : Vector3D
var drag_debug_vector : Vector3D

func _init():
	super._init()
	#initialize debug vectors
	lift_debug_vector = Vector3D.new(Color(0, 0, 1))
	lift_debug_vector.visible = false
	lift_debug_vector.sorting_offset = 0.02
	add_child(lift_debug_vector, INTERNAL_MODE_FRONT)
	
	drag_debug_vector = Vector3D.new(Color(1, 0, 0))
	drag_debug_vector.visible = false
	drag_debug_vector.sorting_offset = 0.01
	add_child(drag_debug_vector, INTERNAL_MODE_FRONT)

func _enter_tree() -> void:
	#initialize signal connections from resources
	if wing_config != null:
		if not wing_config.is_connected("changed", update_gizmos):
			wing_config.changed.connect(update_gizmos)
			update_gizmos()

func _calculate_forces(_world_air_velocity : Vector3, _air_density : float, _relative_position : Vector3, _altitude : float, substep_delta : float = 0.0) -> PackedVector3Array:
	super._calculate_forces(_world_air_velocity, _air_density, _relative_position, _altitude, substep_delta)
	#calculate some common values, some necessary for debugging
	#air velocity in local space
	sweep_angle =  abs(atan2(local_air_velocity.z, local_air_velocity.x) / PI - 0.5)
	drag_direction = world_air_velocity.normalized()
	var right_facing_air_vector : Vector3 = world_air_velocity.cross(-global_transform.basis.y).normalized()
	lift_direction = drag_direction.cross(right_facing_air_vector).normalized()
	angle_of_attack = atan2(local_air_velocity.y, local_air_velocity.z)
	area = wing_config.chord * wing_config.span
	projected_wing_area = abs(wing_config.span * wing_config.chord * sin(angle_of_attack))
	
	return PackedVector3Array([Vector3.ZERO, Vector3.ZERO])

func update_debug_visibility(_show_debug : bool = false) -> void:
	super.update_debug_visibility(_show_debug)
	#check that debug vectors exist
	if lift_debug_vector and drag_debug_vector:
		lift_debug_vector.visible = show_debug and show_lift
		drag_debug_vector.visible = show_debug and show_drag

func update_debug_scale(_scale : float, _width : float) -> void:
	super.update_debug_scale(_scale, _width)
	
	lift_debug_vector.width = debug_width
	drag_debug_vector.width = debug_width

func update_debug_vectors() -> void:
	super.update_debug_vectors()
	
	#check that debug vectors exist
	if !lift_debug_vector or !drag_debug_vector:
		return
	
	#don't update invisible vectors
	if lift_debug_vector.visible:
		lift_debug_vector.value = global_transform.basis.inverse() * _current_lift * debug_scale
	if drag_debug_vector.visible:
		drag_debug_vector.value = global_transform.basis.inverse() * _current_drag * debug_scale
