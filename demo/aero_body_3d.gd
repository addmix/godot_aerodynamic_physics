@tool
extends AeroBody3D

func _physics_process(delta):
	super._physics_process(delta)
	$Elevator.rotation.x = Input.get_axis("ui_down", "ui_up") * 0.4
	$WingL.rotation.x = Input.get_axis("ui_left", "ui_right") * 0.1
	$WingR.rotation.x = -Input.get_axis("ui_left", "ui_right") * 0.1
