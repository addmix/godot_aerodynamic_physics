extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#enable direction target autopilot mode
	get_parent().flight_assist.enable_target_direction = true

func _physics_process(delta: float) -> void:
	var mouse_direction : Vector3 = get_viewport().get_camera_3d().project_ray_normal(get_viewport().get_mouse_position())
	get_parent().flight_assist.direction_target = mouse_direction

func _enter_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
