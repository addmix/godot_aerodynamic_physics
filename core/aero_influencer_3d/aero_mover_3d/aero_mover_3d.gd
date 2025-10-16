@tool
extends AeroInfluencer3D
class_name AeroMover3D

const AeroTransformUtils = preload("../../../utils/transform_utils.gd")

##Rate (in meters per second) the AeroMover3D will move.
@export var linear_motor : Vector3 = Vector3.ZERO
##Rate (in radians per second) the AeroMover3D will rotate.
@export var angular_motor : Vector3 = Vector3.ZERO

@export var disable_lift_dissymmetry : bool = false

@export var use_movement_as_velocity : bool = false

var _linear_velocity : Vector3 = Vector3.ZERO
var _angular_velocity : Vector3 = Vector3.ZERO

@onready var last_position : Vector3 = position
@onready var last_rotation : Basis = basis

func _update_transform_substep(substep_delta : float) -> void:
	_linear_velocity = Vector3.ZERO
	_angular_velocity = Vector3.ZERO
	
	if use_movement_as_velocity:
		#calculate velocity caused by moving the node
		_linear_velocity = (position - last_position) / substep_delta
		_linear_velocity -= linear_motor #cancel out any movement caused by motor
		
		var axis_angle : Quaternion = AeroTransformUtils.quat_to_axis_angle(basis * last_rotation.inverse())
		_angular_velocity = Vector3(axis_angle.x, axis_angle.y, axis_angle.z) * axis_angle.w / substep_delta * basis * 2.0 #i'm not entirely sure why the 2.0 is needed, but testing showed that it's needed.
		_angular_velocity -= angular_motor #cancel out any rotation caused by motor
	
	#motors
	default_transform.origin += linear_motor * basis * substep_delta
	#rotate by angular velocity
	if not is_equal_approx(angular_motor.length_squared(), 0.0):
		default_transform.basis = default_transform.basis * Basis((angular_motor).normalized(), angular_motor.length() * substep_delta)
	
	_linear_velocity += linear_motor
	_angular_velocity += angular_motor
	
	last_position = position
	last_rotation = basis
	
	super._update_transform_substep(substep_delta)
	


func get_linear_velocity() -> Vector3:
	var velocity : Vector3 = super.get_linear_velocity() + (_linear_velocity * global_basis.inverse())
	
	if disable_lift_dissymmetry:
		velocity = global_basis.y.normalized() * velocity.dot(global_basis.y)
	
	return velocity

func get_angular_velocity() -> Vector3:
	return super.get_angular_velocity() + (_angular_velocity * global_basis.inverse())
