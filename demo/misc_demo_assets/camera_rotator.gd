extends Node3D

@export var rotation_speed : float = deg_to_rad(180)

const AeroTransformUtils = preload("res://addons/godot_aerodynamic_physics/utils/transform_utils.gd")

func _process(delta: float) -> void:
	var aerobody_basis : Basis = get_parent().global_basis
	
	#look towareds which is closer, linear velocity or negative linear velocity
	var direction_to_look : Vector3 = get_parent().linear_velocity
	
	if direction_to_look.normalized().dot(-aerobody_basis.z.normalized()) < 0.0:
		direction_to_look = -get_parent().linear_velocity
	
	var flightpath_basis : Basis = AeroTransformUtils.looking_at_safe(direction_to_look, get_parent().global_basis.y, get_parent().global_basis.z, get_parent().global_basis)
	var current_basis := global_basis
	
	# use aerobody's velocity as a lerp factor, so that the camera faces forward when not moving or slowing down
	var lerp_factor : float = clamp(remap(direction_to_look.length(), 10, 40, 0, 0.5), 0, 0.5)
	var target_basis := aerobody_basis.slerp(flightpath_basis, lerp_factor)
	
	#the rotation required to rotate the camera from it's current rotation to the desired rotation
	var necessary_rotation := Quaternion((current_basis.inverse() * target_basis).get_rotation_quaternion())
	#using the quaternion's axis and angle, we can get real linear interpolation using move_toward() at a constant speed
	var amount_to_rotate : float = move_toward(0.0, necessary_rotation.get_angle(), rotation_speed * delta)
	
	var rotation_to_make := Quaternion()
	if not is_equal_approx(necessary_rotation.get_axis().length(), 0.0):
		rotation_to_make = Quaternion(necessary_rotation.get_axis().normalized(), amount_to_rotate)
	
	global_basis = current_basis * Basis(rotation_to_make)
