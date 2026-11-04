extends Node3D

const airplane_scene = preload("res://addons/godot_aerodynamic_physics/tests/paper airplanes/plane.tscn")

@export var spawn_amount : int = 1000



func start() -> void:
	for x : int in spawn_amount:
		var instance : AeroBody3D = airplane_scene.instantiate()
		var spawn_direction := randf_range(0.0, 360.0)
		
		instance.position = Vector3(0, randf_range(200, 300), randf_range(400, 600)).rotated(Vector3(0, 1, 0), spawn_direction)
		instance.rotation.y = spawn_direction
		instance.linear_velocity = -instance.basis.z * randf_range(20, 35)
		
		add_child(instance)


func _on_button_pressed() -> void:
	$Button.hide()
	start()
