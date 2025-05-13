@tool
extends AeroVariablePropeller3D
class_name AeroCyclicPropeller3D

##Cyclic control value. Control takes place cyclicly, and changes based on a blade's position through the cycle.
@export var cyclic := Vector2.ZERO
##Maximum rotation angle (degrees) of cyclic control.
@export var cyclic_pitch : float = 15.0

@export var cyclic_control_config :=  create_cyclic_control_config()
func create_cyclic_control_config() -> AeroInfluencerControlConfig:
	var config := AeroInfluencerControlConfig.new()
	config.max_value = Vector3(1.0, 1.0, 0.0)
	config.roll_config = AeroInfluencerControlAxisConfig.new(Vector3(1.0, 0.0, 0.0))
	config.pitch_config = AeroInfluencerControlAxisConfig.new(Vector3(0.0, 1.0, 0.0))
	return config

func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		cyclic_control_config = cyclic_control_config.duplicate(true)

func _update_transform_substep(substep_delta : float) -> void:
	super._update_transform_substep(substep_delta)
	
	var rotor_offset : float = basis.get_euler(EULER_ORDER_XZY).y
	for influencer : AeroInfluencer3D in propeller_instances:
		var angular_position : float = rotor_offset + influencer.rotation.y
		
		var cyclic_effect : float = cos(angular_position) * cyclic.x + sin(angular_position) * cyclic.y
		cyclic_effect *= deg_to_rad(cyclic_pitch)
		
		influencer.default_transform.basis = Basis.from_euler(Vector3(deg_to_rad(propeller_pitch) + cyclic_effect, influencer.default_transform.basis.get_euler().y, influencer.default_transform.basis.get_euler().z)) 

func _update_control_transform(substep_delta : float) -> void:
	super._update_control_transform(substep_delta)
	
	var cyclic_value := Vector3.ZERO
	if cyclic_control_config:
		cyclic_value = apply_control_commands_to_config(substep_delta, cyclic_control_config)
	
	cyclic_control_config.update(substep_delta)
	cyclic = Vector2(cyclic_control_config.current_value.x, cyclic_control_config.current_value.y)
