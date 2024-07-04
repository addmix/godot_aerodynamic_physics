@tool
extends AeroPropeller3D
class_name AeroVariablePropeller3D

##Pitch angle for propeller blades.
@export var propeller_pitch : float = 0.0
#variable isn't used. Alias for propeller_pitch
##Pitch angle for propeller blades. Alias for `propeller_pitch`
@export var collective : float = 0.0:
	set(x):
		collective = x
		propeller_pitch = collective
	get:
		return propeller_pitch

func _update_transform_substep(substep_delta : float) -> void:
	super._update_transform_substep(substep_delta)
	
	for influencer : AeroInfluencer3D in propeller_instances:
		influencer.default_transform.basis = Basis.from_euler(Vector3(deg_to_rad(propeller_pitch), influencer.default_transform.basis.get_euler().y, influencer.default_transform.basis.get_euler().z)) 
		influencer.transform = influencer.default_transform

func is_overriding_body_sleep() -> bool:
	return super.is_overriding_body_sleep() and not is_equal_approx(propeller_pitch, 0.0)
