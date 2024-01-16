@tool
extends AeroPropeller3D
class_name AeroVariablePropeller3D

@export var propeller_pitch : float = 0.0
#variable isn't used. Alias for propeller_pitch
@export var collective : float = 0.0:
	set(x):
		collective = x
		propeller_pitch = collective
	get:
		return propeller_pitch

func _update_transform_substep(substep_delta : float) -> void:
	super._update_transform_substep(substep_delta)
	
	for influencer : AeroInfluencer3D in propeller_instances:
		influencer.rotation.x = deg_to_rad(propeller_pitch)
