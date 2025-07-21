extends Marker3D

@export var launch_velocity : float = 400.0

var ball_scene : PackedScene = preload("res://addons/godot_aerodynamic_physics/demo/aircraft_examples/drag_ball/ball.tscn")

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		var ball_instance : AeroBody3D = ball_scene.instantiate()
		#get the parent of the AeroBody3D
		get_parent().get_parent().add_child(ball_instance)
		ball_instance.global_transform = global_transform
		ball_instance.linear_velocity = get_parent().linear_velocity + -global_basis.z * launch_velocity
		ball_instance.angular_velocity = get_parent().angular_velocity
		
		await get_tree().create_timer(30.0).timeout
		
		ball_instance.queue_free()
