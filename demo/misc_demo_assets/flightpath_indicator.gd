extends Node3D

func _physics_process(delta: float) -> void:
	if not is_equal_approx(get_parent().get_parent().linear_velocity.length(), 0.0):
		global_basis = Basis.looking_at(get_parent().get_parent().linear_velocity, get_parent().get_parent().global_basis.y)
