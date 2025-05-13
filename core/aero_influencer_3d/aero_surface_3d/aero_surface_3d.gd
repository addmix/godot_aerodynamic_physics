@tool
extends AeroInfluencer3D
class_name AeroSurface3D

##Config resource used to define the size of the AeroSurface3D node.
@export var wing_config : AeroSurfaceConfig = AeroSurfaceConfig.new():
	set(value):
		wing_config = value
		if wing_config == null:
			return
		if not wing_config.is_connected("changed", update_gizmos):
			wing_config.changed.connect(update_gizmos)
			update_gizmos()

@export_group("Debug")
##Controls visibility of the AeroSurface3D's lift debug vector
@export var show_lift : bool = true
##Controls visibility of the AeroSurface3D's drag debug vector
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

var lift_debug_vector : AeroDebugVector3D
var drag_debug_vector : AeroDebugVector3D

func _init():
	super._init()
	#initialize debug vectors
	lift_debug_vector = AeroDebugVector3D.new(Color(0, 0, 1))
	lift_debug_vector.visible = false
	lift_debug_vector.sorting_offset = 0.02
	add_child(lift_debug_vector, INTERNAL_MODE_FRONT)
	
	drag_debug_vector = AeroDebugVector3D.new(Color(1, 0, 0))
	drag_debug_vector.visible = false
	drag_debug_vector.sorting_offset = 0.01
	add_child(drag_debug_vector, INTERNAL_MODE_FRONT)

func _enter_tree() -> void:
	super._enter_tree()
	#initialize signal connections from resources
	if wing_config:
		if not wing_config.is_connected("changed", update_gizmos):
			wing_config.changed.connect(update_gizmos)
			update_gizmos()

func _calculate_forces(substep_delta : float = 0.0) -> PackedVector3Array:
	var force_and_torque : PackedVector3Array = super._calculate_forces(substep_delta)
	#calculate some common values, some necessary for debugging
	#air velocity in local space
	angle_of_attack = global_basis.y.angle_to(-world_air_velocity) - (PI / 2.0)
	sweep_angle = global_basis.x.angle_to(-world_air_velocity) - (PI / 2.0)
	
	area = wing_config.chord * wing_config.span
	projected_wing_area = abs(wing_config.span * wing_config.chord * sin(angle_of_attack))
	
	drag_direction = world_air_velocity.normalized()
	var right_facing_air_vector : Vector3 = world_air_velocity.cross(-global_transform.basis.y).normalized()
	lift_direction = drag_direction.cross(right_facing_air_vector).normalized()
	
	return force_and_torque

func update_debug_visibility(_show_debug : bool = false) -> void:
	super.update_debug_visibility(_show_debug)
	#check that debug vectors exist
	if lift_debug_vector and drag_debug_vector:
		lift_debug_vector.visible = show_debug and show_lift
		drag_debug_vector.visible = show_debug and show_drag

func update_debug_scale(_scale : float, _width : float) -> void:
	super.update_debug_scale(_scale, _width)
	
	if lift_debug_vector:
		lift_debug_vector.width = debug_width
	if drag_debug_vector:
		drag_debug_vector.width = debug_width

func update_debug_vectors() -> void:
	super.update_debug_vectors()
	
	#check that debug vectors exist
	if !lift_debug_vector or !drag_debug_vector:
		return
	
	#don't update invisible vectors
	if lift_debug_vector.visible:
		lift_debug_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(_current_lift, 2.0) * debug_scale
	if drag_debug_vector.visible:
		drag_debug_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(_current_drag, 2.0) * debug_scale
