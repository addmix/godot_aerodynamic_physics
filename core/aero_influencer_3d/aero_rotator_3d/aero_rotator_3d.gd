@tool
extends AeroInfluencer3D
class_name AeroRotator3D

var aero_influencers : Array[AeroInfluencer3D] = []

var default_transform : Transform3D = transform
@export var angular_velocity : Vector3 = Vector3.ZERO

func _ready():
	for i in get_children():
		if i is AeroInfluencer3D:
			aero_influencers.append(i)

func _calculate_forces(_world_air_velocity : Vector3, _world_angular_velocity : Vector3, _air_density : float, _relative_position : Vector3, _altitude : float, substep_delta : float = 0.0) -> PackedVector3Array:
	super._calculate_forces(_world_air_velocity, _world_angular_velocity, _air_density, _relative_position, _altitude, substep_delta)
	
	var force : Vector3 = Vector3.ZERO
	var torque : Vector3 = Vector3.ZERO
	
	for influencer : AeroInfluencer3D in aero_influencers:
		#position relative to AeroBody origin, using global rotation
		var influencer_relative_position : Vector3 = (global_transform.basis * influencer.position)
		var force_and_torque : PackedVector3Array = influencer._calculate_forces(world_air_velocity - (world_angular_velocity.cross(relative_position + influencer_relative_position) + (angular_velocity * global_basis.inverse()).cross(influencer_relative_position)), world_angular_velocity + angular_velocity, air_density, influencer_relative_position, position.y, substep_delta)
		force += force_and_torque[0]
		torque += force_and_torque[1]
	
	torque += relative_position.cross(force)
	
	_current_force = force
	_current_torque = torque
	
	return PackedVector3Array([force, torque])

func _update_transform_substep(substep_delta : float) -> void:
	#rotate by angular velocity
	if not is_equal_approx(angular_velocity.length_squared(), 0.0):
		basis = basis.rotated((angular_velocity * basis.inverse()).normalized(), angular_velocity.length() * substep_delta)
	
	#update children nodes
	for influencer : AeroInfluencer3D in aero_influencers:
		influencer._update_transform_substep(substep_delta)

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
