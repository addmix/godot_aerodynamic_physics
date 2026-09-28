extends Node3D

@export var rotation_speed : float = deg_to_rad(180)

const aero_math_utils = preload("res://addons/godot_aerodynamic_physics/utils/math_utils.gd")

func _process(delta: float) -> void:
	var flightpath_basis : Basis = get_parent().global_basis
	if not is_equal_approx(get_parent().linear_velocity.length(), 0.0):
		flightpath_basis = Basis.looking_at(get_parent().linear_velocity, get_parent().global_basis.y)
	var aerobody_basis : Basis = get_parent().global_basis
	
	var current_basis := global_basis
	
	# use aerobody's velocity as a lerp factor, so that the camera faces forward when not moving or slowing down
	var lerp_factor : float = clamp(remap(get_parent().linear_velocity.length(), 10, 40, 0, 0.5), 0, 0.5)
	var target_basis := aerobody_basis.slerp(flightpath_basis, lerp_factor)
	
	#the rotation required to rotate the camera from it's current rotation to the desired rotation
	var necessary_rotation := Quaternion(current_basis.inverse() * target_basis)
	#using the quaternion's axis and angle, we can get real linear interpolation using move_toward() at a constant speed
	var amount_to_rotate : float = move_toward(0.0, necessary_rotation.get_angle(), rotation_speed * delta)
	
	var rotation_to_make := Quaternion()
	if not is_equal_approx(necessary_rotation.get_axis().length(), 0.0):
		rotation_to_make = Quaternion(necessary_rotation.get_axis().normalized(), amount_to_rotate)
	
	global_basis = current_basis * Basis(rotation_to_make)
