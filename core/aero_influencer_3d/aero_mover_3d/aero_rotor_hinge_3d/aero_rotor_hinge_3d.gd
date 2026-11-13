
###This is currently broken.

@tool
extends AeroMover3D
class_name AeroRotorHinge3D

##Length of the simulated blade, from the hinge root, to the tip.
@export var blade_length : float = 10.0:
	set(x):
		if blade_length == x: return
		
		blade_length = x
		notify_flight_model_changed()
##Mass of the simulated blade.
@export var blade_mass : float = 100.0:
	set(x):
		if blade_mass == x: return
		
		blade_mass = x
		notify_flight_model_changed()

var flap_velocity : float = 0.0
var leadlag_velocity : float = 0.0

var flap : float = 0.0
var leadlag : float = 0.0

@onready var rotation_z : float = rotation.z
@onready var rotation_y : float = rotation.y

func _update_transform_substep(substep_delta : float) -> void:
	super._update_transform_substep(substep_delta)
	
	#should we use the torque instead of the force?
	var force : Vector3 = get_current_force() * get_cached_global_basis()
	var linear_acceleration : Vector3 = get_linear_acceleration() * get_cached_global_basis()
	
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
	
	#apply the rotation through the cache-aware setter so the influencer's transform caches stay valid
	var local_transform : Transform3D = get_cached_local_transform()
	local_transform.basis = Basis.from_euler(Vector3(0, rotation_y + leadlag, rotation_z + flap))
	set_cached_transform(local_transform)

func get_centrifugal_offset() -> Vector3:
	return position + Vector3(blade_length * 0.5, 0, 0)
