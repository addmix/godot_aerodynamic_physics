@tool
extends AeroInfluencer3D
class_name AeroMover3D

const AeroTransformUtils = preload("../../../utils/transform_utils.gd")
const AeroNodeUtils = preload("../../../utils/node_utils.gd")

var aero_influencers : Array[AeroInfluencer3D] = []

var default_transform : Transform3D = transform
@export var linear_velocity : Vector3 = Vector3.ZERO
@export var angular_velocity : Vector3 = Vector3.ZERO

var _linear_velocity : Vector3 = Vector3.ZERO
var _angular_velocity : Vector3 = Vector3.ZERO

var translation_velocity : Vector3 = Vector3.ZERO #(position - last_position) / substep_delta
var rotation_velocity : Vector3 = Vector3.ZERO

@onready var last_position : Vector3 = position
@onready var last_rotation : Basis = basis

func _enter_tree() -> void:
	child_entered_tree.connect(on_child_enter_tree)
	child_exiting_tree.connect(on_child_exit_tree)

func on_child_enter_tree(node : Node) -> void:
	if node is AeroInfluencer3D:
		aero_influencers.append(node)

func on_child_exit_tree(node : Node) -> void:
	if node is AeroInfluencer3D and aero_influencers.has(node):
		aero_influencers.erase(node)

func _calculate_forces(_world_air_velocity : Vector3, _world_angular_velocity : Vector3, _air_density : float, _relative_position : Vector3, _altitude : float, substep_delta : float = 0.0) -> PackedVector3Array:
	super._calculate_forces(_world_air_velocity, _world_angular_velocity, _air_density, _relative_position, _altitude, substep_delta)
	
	var force : Vector3 = Vector3.ZERO
	var torque : Vector3 = Vector3.ZERO
	
	var global_linear_velocity : Vector3 = _linear_velocity * global_basis.inverse()
	var global_angular_velocity : Vector3 = _angular_velocity * global_basis.inverse()
	
	for influencer : AeroInfluencer3D in aero_influencers:
		#position relative to AeroBody origin, using global rotation
		var influencer_relative_position : Vector3 = (global_transform.basis * influencer.position)
		var total_relative_position : Vector3 = relative_position + influencer_relative_position
		#negative because air velocity is opposite to object velocity
		var world_angular_point_velocity : Vector3 = -world_angular_velocity.cross(total_relative_position)
		var rotor_point_velocity : Vector3 = global_angular_velocity.cross(-influencer_relative_position)
		var total_angular_velocity : Vector3 = world_angular_velocity + global_angular_velocity
		var total_linear_velocity : Vector3 = world_air_velocity + global_linear_velocity + world_angular_point_velocity + rotor_point_velocity
		
		var force_and_torque : PackedVector3Array = influencer._calculate_forces(total_linear_velocity, total_angular_velocity, air_density, total_relative_position, position.y, substep_delta)
		
		influencer._current_force = global_angular_velocity * 50000
		force += force_and_torque[0]
		torque += force_and_torque[1]
	
	torque += relative_position.cross(force)
	
	_current_force = force
	_current_torque = torque
	
	return PackedVector3Array([force, torque])

func _update_transform_substep(substep_delta : float) -> void:
	position += linear_velocity * basis * substep_delta
	#rotate by angular velocity
	if not is_equal_approx(angular_velocity.length_squared(), 0.0):
		basis = basis.rotated(angular_velocity.normalized(), angular_velocity.length() * substep_delta) #(angular_velocity * basis.inverse()).normalized(), angular_velocity.length() * delta)
	
	#update movement velocity
	_linear_velocity = (position - last_position) / substep_delta + linear_velocity
	var axis_angle : Quaternion = AeroTransformUtils.quat_to_axis_angle(basis * last_rotation.inverse())
	_angular_velocity = Vector3(axis_angle.x, axis_angle.y, axis_angle.z) * axis_angle.w / substep_delta + angular_velocity
	
	last_position = position
	last_rotation = basis
	
	#update children nodes
	for influencer : AeroInfluencer3D in aero_influencers:
		influencer._update_transform_substep(substep_delta)

#func is_overriding_body_sleep() -> bool:
	#return not is_equal_approx(angular_velocity.length_squared(), 0.0)

func update_debug_visibility(_show_debug : bool = false) -> void:
	super.update_debug_visibility(_show_debug)
	for i : AeroInfluencer3D in aero_influencers:
		i.update_debug_visibility(_show_debug)

func update_debug_scale(_scale : float, _width : float) -> void: 
	super.update_debug_scale(_scale, _width)
	for i : AeroInfluencer3D in aero_influencers:
		i.update_debug_scale(_scale, _width)

func update_debug_vectors() -> void:
	super.update_debug_vectors()
	for i : AeroInfluencer3D in aero_influencers:
		i.update_debug_vectors()
