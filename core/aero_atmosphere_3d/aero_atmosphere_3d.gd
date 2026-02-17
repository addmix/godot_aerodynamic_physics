@tool
extends Area3D
class_name AeroAtmosphere3D

@export var per_influencer_positioning : bool = false
@export var wind : Vector3 = Vector3.ZERO
@export var override_wind : bool = false
@export var density : float = 1.225
@export var override_density : bool = false
@export var temperature : float = 288.0
@export var override_temperature : bool = false

#this isn't a great solution, but it's easier than the alternative.
func _init() -> void:
	monitorable = false
	
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(ProjectSettings.get_setting("physics/aerodynamics/atmosphere_area_collision_layer", 15), true) 
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
#this isn't a great solution, but it's easier than the alternative.
func _on_body_entered(body : PhysicsBody3D) -> void:
	if body is AeroBody3D:
		body.atmosphere_areas.append(self)
#this isn't a great solution, but it's easier than the alternative.
func _on_body_exited(body : PhysicsBody3D) -> void:
	if body is AeroBody3D:
		body.atmosphere_areas.erase(self)

func is_inside_atmosphere(_position : Vector3) -> bool:
	return get_distance_to_surface(_position) < 0.0

func get_wind_at_position(_position : Vector3) -> Vector3:
	return wind

func get_density_at_position(_position : Vector3) -> float:
	return density

func get_temperature_at_position(_position : Vector3) -> float:
	return temperature

func get_distance_to_surface(_position : Vector3, direction : Vector3 = Vector3(0, 1, 0)) -> float:
	return 0.0

func get_surface_normal(_position : Vector3, direction : Vector3 = Vector3(0, 1, 0)) -> Vector3:
	return Vector3(0, 1, 0)
