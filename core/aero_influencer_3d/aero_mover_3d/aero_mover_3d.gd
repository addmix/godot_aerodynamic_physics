@tool
extends AeroInfluencer3D
class_name AeroMover3D

const AeroTransformUtils = preload("../../../utils/transform_utils.gd")
const AeroNodeUtils = preload("../../../utils/node_utils.gd")

@export var linear_velocity : Vector3 = Vector3.ZERO
@export var angular_velocity : Vector3 = Vector3.ZERO

var _linear_velocity : Vector3 = Vector3.ZERO
var _angular_velocity : Vector3 = Vector3.ZERO

@onready var last_position : Vector3 = position
@onready var last_rotation : Basis = basis


func _update_transform_substep(substep_delta : float) -> void:
	#update movement velocity
	_linear_velocity = (position - last_position) / substep_delta
	var axis_angle : Quaternion = AeroTransformUtils.quat_to_axis_angle(basis * last_rotation.inverse())
	_angular_velocity = Vector3(axis_angle.x, axis_angle.y, axis_angle.z) * axis_angle.w / substep_delta * basis
	
	position += linear_velocity * basis * substep_delta
	#rotate by angular velocity
	if not is_equal_approx(angular_velocity.length_squared(), 0.0):
		basis = basis.rotated((angular_velocity * basis.inverse()).normalized(), angular_velocity.length() * substep_delta)
	
	_linear_velocity += linear_velocity
	_angular_velocity += angular_velocity
	
	last_position = position
	last_rotation = basis
	
	#update children nodes
	for influencer : AeroInfluencer3D in aero_influencers:
		influencer._update_transform_substep(substep_delta)


func get_linear_velocity() -> Vector3:
	return super.get_linear_velocity() + (linear_velocity * global_basis.inverse())

func get_angular_velocity() -> Vector3:
	return super.get_angular_velocity() + (angular_velocity * global_basis.inverse())

