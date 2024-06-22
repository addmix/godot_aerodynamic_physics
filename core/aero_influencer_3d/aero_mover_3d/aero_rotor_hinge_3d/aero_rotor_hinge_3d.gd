
### This is currently broken.

@tool
extends AeroMover3D
class_name AeroRotorHinge3D

##Length of the simulated blade, from the hinge root, to the tip.
@export var blade_length : float = 10.0
##Mass of the simulated blade.
@export var blade_mass : float = 100.0

var flap_velocity : float = 0.0
var leadlag_velocity : float = 0.0

var flap : float = 0.0
var leadlag : float = 0.0

@onready var rotation_z : float = rotation.z
@onready var rotation_y : float = rotation.y

func _update_transform_substep(substep_delta : float) -> void:
	super._update_transform_substep(substep_delta)
	
	#should we use the torque instead of the force?
	var force : Vector3 = _current_force * global_basis
	var linear_acceleration : Vector3 = get_linear_acceleration() * global_basis
	
	leadlag_velocity += force.z / blade_mass * substep_delta #might need to be negative
	leadlag_velocity += linear_acceleration.z * substep_delta
	leadlag += leadlag_velocity * substep_delta
	
	#if not leadlag == clamp(leadlag, -0.5, 0.5):
		#leadlag = clamp(leadlag, -0.5, 0.5) - 0.05 * sign(leadlag)
		#leadlag_velocity = 0.0
	
	
	# lead-lag and flap velocity isn't integrated properly by AeroMover3D
	
	#need conservation of angular momentum
	
	#need option for "delta 3" feathering control
	
	flap_velocity = force.y / blade_mass * substep_delta
	flap_velocity += -linear_acceleration.y * substep_delta
	flap += flap_velocity * substep_delta
	
	#if not flap == clamp(flap, -0.5, 0.5):
		#flap = clamp(flap, -0.5, 0.5) - 0.05 * sign(flap)
		#flap_velocity = 0.0
	
	rotation.z = rotation_z + flap
	rotation.y = rotation_y + leadlag

func get_centrifugal_offset() -> Vector3:
	return position + Vector3(blade_length * 0.5, 0, 0)
