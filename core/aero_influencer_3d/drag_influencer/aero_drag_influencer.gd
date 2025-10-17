@tool
extends AeroInfluencer3D
class_name AeroDragInfluencer3D

@export var radius : float = 0.5
@export var drag_coefficient : float = 0.5

func _calculate_forces(substep_delta : float = 0.0) -> PackedVector3Array:
	var force_and_torque : PackedVector3Array = super._calculate_forces(substep_delta)
	
	#area of circle made by drag body
	var area : float = PI * radius * radius
	
	#this calculation is basically air density * air speed * area of influencer, in the drag direction.
	_current_force = dynamic_pressure * area * drag_direction
	#torque must be calculated manually because some influencers calculate torque differently.
	_current_torque = relative_position.cross(_current_force)
	
	#we want to add to force_and_torque, instead of replacing the value
	force_and_torque[0] += _current_force
	force_and_torque[1] += _current_torque
	
	return force_and_torque
