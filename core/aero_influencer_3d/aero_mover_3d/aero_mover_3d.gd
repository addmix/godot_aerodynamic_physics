@tool
extends AeroInfluencer3D
class_name AeroMover3D

const AeroTransformUtils = preload("../../../utils/transform_utils.gd")

##Rate (in meters per second) the AeroMover3D will move.
@export var linear_motor : Vector3 = Vector3.ZERO:
	set(x):
		if linear_motor == x: return
		
		linear_motor = x
		notify_flight_model_changed()
##Rate (in radians per second) the AeroMover3D will rotate.
@export var angular_motor : Vector3 = Vector3.ZERO:
	set(x):
		if angular_motor == x: return
		
		angular_motor = x
		notify_flight_model_changed()

@export var disable_lift_dissymmetry : bool = false:
	set(x):
		if disable_lift_dissymmetry == x: return
		
		disable_lift_dissymmetry = x
		notify_flight_model_changed()

@export var use_movement_as_velocity : bool = false:
	set(x):
		if use_movement_as_velocity == x: return
		
		use_movement_as_velocity = x
		notify_flight_model_changed()

var _linear_velocity : Vector3 = Vector3.ZERO
var _angular_velocity : Vector3 = Vector3.ZERO

@onready var last_position : Vector3 = position
@onready var last_rotation : Basis = basis

func _update_transform_substep(substep_delta : float) -> void:
	_linear_velocity = Vector3.ZERO
	_angular_velocity = Vector3.ZERO
	
	#the node transform is only written at the end of the update, so the cache is what the substeps see
	var cached_transform : Transform3D = get_cached_local_transform()
	
	if use_movement_as_velocity:
		#calculate velocity caused by moving the node
		_linear_velocity = (cached_transform.origin - last_position) / substep_delta
		_linear_velocity -= linear_motor #cancel out any movement caused by motor
		
		var axis_angle : Vector3 = AeroTransformUtils.quat_to_axis_angle(cached_transform.basis * last_rotation.inverse())
		_angular_velocity = axis_angle / substep_delta * cached_transform.basis * 2.0 #i'm not entirely sure why the 2.0 is needed, but testing showed that it's needed.
		_angular_velocity -= angular_motor #cancel out any rotation caused by motor
	
	if not Engine.is_editor_hint():
		default_transform.origin += linear_motor * default_transform.basis * substep_delta
		#rotate by angular velocity
		if not is_equal_approx(angular_motor.length_squared(), 0.0):
			var new_transform := default_transform
			new_transform.basis = default_transform.basis * Basis((angular_motor).normalized(), angular_motor.length() * substep_delta)
			default_transform = new_transform
	
	_linear_velocity += linear_motor
	_angular_velocity += angular_motor
	
	last_position = cached_transform.origin
	last_rotation = cached_transform.basis
	
	super._update_transform_substep(substep_delta)


func calculate_linear_velocity_substep() -> Vector3:
	var velocity : Vector3 = super() + (_linear_velocity * get_cached_global_basis().inverse())
	
	if disable_lift_dissymmetry:
		velocity = get_cached_global_basis().y.normalized() * velocity.dot(get_cached_global_basis().y)
	
	return velocity

func calculate_angular_velocity_substep() -> Vector3:
	return super() + (_angular_velocity * get_cached_global_basis().inverse())
