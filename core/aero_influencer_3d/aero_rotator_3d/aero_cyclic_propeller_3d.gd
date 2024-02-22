@tool
extends AeroVariablePropeller3D
class_name AeroCyclicPropeller3D

@export var cyclic := Vector2.ZERO
@export var cyclic_pitch : float = 15.0

func _update_transform_substep(substep_delta : float) -> void:
	super._update_transform_substep(substep_delta)
	
	var rotor_offset : float = basis.get_euler(EULER_ORDER_XZY).y
	for influencer : AeroInfluencer3D in propeller_instances:
		var angular_position : float = rotor_offset + influencer.rotation.y
		#must be *2 because sin and cos are 50% out of phase
		var cyclic_effect : float = cos(angular_position) * cyclic.x + sin(angular_position) * cyclic.y * 2.0
		
		cyclic_effect *= deg_to_rad(cyclic_pitch)
		
		influencer.rotation.x = deg_to_rad(propeller_pitch) + cyclic_effect
