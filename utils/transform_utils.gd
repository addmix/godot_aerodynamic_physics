# From https://github.com/addmix/godot_utils

static func quat_to_axis_angle(quat : Quaternion) -> Quaternion:
	return Quaternion(quat.get_axis().x, quat.get_axis().y, quat.get_axis().z, quat.get_angle())

static func looking_at_safe(target : Vector3, up : Vector3, alternate_up := Vector3(0, 0, 1), default_basis := Basis()) -> Basis:
	if is_equal_approx(target.length_squared(), 0.0) or is_equal_approx(up.length_squared(), 0.0):
		return default_basis
	
	if is_equal_approx(target.cross(up).length_squared(), 0.0):
		up = alternate_up
	
	return Basis.looking_at(target, up)
