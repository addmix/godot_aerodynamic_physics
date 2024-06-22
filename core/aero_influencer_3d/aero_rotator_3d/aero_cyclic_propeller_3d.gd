@tool
extends AeroVariablePropeller3D
class_name AeroCyclicPropeller3D

##Cyclic control value. Control takes place cyclicly, and changes based on a blade's position through the cycle.
@export var cyclic := Vector2.ZERO
##Maximum rotation angle (degrees) of cyclic control.
@export var cyclic_pitch : float = 15.0

func _update_transform_substep(substep_delta : float) -> void:
	super._update_transform_substep(substep_delta)
	
	var rotor_offset : float = basis.get_euler(EULER_ORDER_XZY).y
	for influencer : AeroInfluencer3D in propeller_instances:
		var angular_position : float = rotor_offset + influencer.rotation.y
		
		var cyclic_effect : float = cos(angular_position) * cyclic.x + sin(angular_position) * cyclic.y
		cyclic_effect *= deg_to_rad(cyclic_pitch)
		
		influencer.rotation.x = deg_to_rad(propeller_pitch) + cyclic_effect
