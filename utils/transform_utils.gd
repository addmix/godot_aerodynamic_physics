# From https://github.com/addmix/godot_utils

## Performs an addition matrix operation for two bases.
static func add_basis(a : Basis, b : Basis) -> Basis:
	return Basis(a.x + b.x, a.y + b.y, a.z + b.z)

## Performs a subtraction matrix operation for two bases.
static func subtract_basis(a : Basis, b : Basis) -> Basis:
	return Basis(a.x - b.x, a.y - b.y, a.z - b.z)

## Alias for [code]Quaternion.get_axis() * Quaternion.get_angle()[/code].
static func quat_to_axis_angle(quat : Quaternion) -> Vector3:
	return quat.get_axis() * quat.get_angle()

static func looking_at_safe(target : Vector3, up : Vector3, alternate_up := Vector3(0, 0, 1), default_basis := Basis()) -> Basis:
	if is_equal_approx(target.length_squared(), 0.0) or is_equal_approx(up.length_squared(), 0.0):
		return default_basis
	
	if is_equal_approx(target.cross(up).length_squared(), 0.0):
		up = alternate_up
	
	return Basis.looking_at(target, up)
