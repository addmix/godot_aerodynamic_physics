extends Node3D

const AeroTransformUtils = preload("res://addons/godot_aerodynamic_physics/utils/transform_utils.gd")

func _physics_process(delta: float) -> void:
	if is_equal_approx(get_parent().get_parent().linear_velocity.length(), 0.0):
		global_basis = Basis.from_scale(Vector3.ZERO)
		return
	
	var target : Vector3 = get_parent().get_parent().linear_velocity
	var up : Vector3 = get_parent().get_parent().global_basis.y
	
	if is_equal_approx(target.cross(up).length_squared(), 0.0):
		up = get_parent().get_parent().global_basis.x
	
	global_basis = AeroTransformUtils.looking_at_safe(get_parent().get_parent().linear_velocity, get_parent().get_parent().global_basis.y, get_parent().get_parent().global_basis.z, Basis.from_scale(Vector3.ZERO))
