@tool
extends AeroInfluencer3D
class_name AeroDragInfluencer3D

@export var radius : float = 0.5:
	set(x):
		if radius == x: return
		
		radius = x
		notify_flight_model_changed()
@export var drag_coefficient : float = 0.5:
	set(x):
		if drag_coefficient == x: return
		
		drag_coefficient = x
		notify_flight_model_changed()

func _calculate_forces(substep_delta : float = 0.0) -> PackedVector3Array:
	var force_and_torque : PackedVector3Array = PackedVector3Array([Vector3.ZERO, Vector3.ZERO])
	
	#area of circle made by drag body
	var area : float = PI * radius * radius
	
	#this calculation is basically air density * air speed * area of influencer, in the drag direction.
	var force := dynamic_pressure * area * drag_direction
	#torque must be calculated manually because some influencers calculate torque differently.
	var torque := relative_position.cross(force)
	
	#we want to add to force_and_torque, instead of replacing the value
	force_and_torque[0] += force
	force_and_torque[1] += torque
	
	return force_and_torque
