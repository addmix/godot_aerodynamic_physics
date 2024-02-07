extends Marker3D

@export var enabled : bool = true
@export var force : float = 100.0

func _physics_process(delta : float) -> void:
	if enabled:
		get_parent().apply_force(-global_transform.basis.z * force, global_transform.basis * position)
