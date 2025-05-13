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

@export_group("Collective Control")
@export var propeller_collective_control_config := create_collective_control_config()
func create_collective_control_config() -> AeroInfluencerControlConfig:
	var config := AeroInfluencerControlConfig.new()
	config.max_value.x = 0.5
	config.collective_config = AeroInfluencerControlAxisConfig.new(Vector3(1.0, 0.0, 0.0))
	return config

func _ready() -> void:
	super._ready()
	
	if not Engine.is_editor_hint():
		if propeller_collective_control_config:
			propeller_collective_control_config = propeller_collective_control_config.duplicate(true)

func _update_transform_substep(substep_delta : float) -> void:
	super._update_transform_substep(substep_delta)
	
	for influencer : AeroInfluencer3D in propeller_instances:
		influencer.default_transform.basis = Basis.from_euler(Vector3(propeller_pitch, influencer.default_transform.basis.get_euler().y, influencer.default_transform.basis.get_euler().z)) 
		influencer.transform = influencer.default_transform

func _update_control_transform(substep_delta : float) -> void:
	super._update_control_transform(substep_delta)
	
	var propeller_velocity_value := Vector3.ZERO
	if propeller_collective_control_config:
		propeller_velocity_value = apply_control_commands_to_config(substep_delta, propeller_collective_control_config)
	
	collective = propeller_collective_control_config.update(substep_delta).x


func is_overriding_body_sleep() -> bool:
	return super.is_overriding_body_sleep() and not is_equal_approx(propeller_pitch, 0.0)
