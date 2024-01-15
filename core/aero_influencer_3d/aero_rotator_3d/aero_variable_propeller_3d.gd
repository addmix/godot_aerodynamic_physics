@tool
extends AeroPropeller3D
class_name AeroVariablePropeller3D

func _ready() -> void:
	super._ready()
	update_propeller_pitch()

@export var propeller_pitch : float = 0.0:
	set(x):
		propeller_pitch = x
		update_propeller_pitch()

func update_propeller_pitch() -> void:
	if Engine.is_editor_hint() or not is_node_ready():
		return
	
	for i : AeroInfluencer3D in propeller_instances:
		i.rotation.x = deg_to_rad(propeller_pitch)

#variable isn't used. Alias for propeller_pitch
@export var collective : float = 0.0:
	set(x):	propeller_pitch = collective
	get: return propeller_pitch

#Alias for update_propeller_pitch()
func update_propeller_cyclic() -> void:
	update_propeller_pitch()
