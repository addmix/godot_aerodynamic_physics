extends Node3D

const AeroNodeUtils = preload("res://addons/godot_aerodynamic_physics/utils/node_utils.gd")
@onready var aero_body : AeroBody3D = AeroNodeUtils.get_first_parent_of_type(self, AeroBody3D)

@onready var wind : Vector3 = aero_body.wind

func _physics_process(delta: float) -> void:
	wind = aero_body.wind

func _process(delta: float) -> void:
	global_basis = Basis()
	if not is_equal_approx(wind.length(), 0.0):
		global_basis = Basis().looking_at(wind, Vector3(0, 1, 0))
