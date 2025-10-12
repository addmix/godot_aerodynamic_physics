@tool
extends AeroMover3D
class_name AeroPropeller3D

##Amount of propeller blades to generate.
@export_range(1, 8, 1, "or_greater") var propeller_amount : int = 2:
	set(x):
		update_configuration_warnings()
		propeller_amount = x
		update_propeller_amount()
##Propeller blade that will be duplicated and arranged.
@export var propeller_blade : AeroInfluencer3D:
	set(x):
		update_configuration_warnings()
		if propeller_blade == x:
			return
		
		propeller_blade = x
		
		if is_node_ready():
			#remove all propellers
			while propeller_instances.size() > 0:
				var instance : AeroInfluencer3D = propeller_instances.pop_back()
				if instance:
					instance.queue_free()
		
		#reinitialize instances array
		propeller_instances = [propeller_blade]
		update_propeller_amount()
var propeller_instances : Array[AeroInfluencer3D] = []

@export_group("Speed Control")
@export var propeller_speed_control_config := create_speed_control_config()
func create_speed_control_config() -> AeroInfluencerControlConfig:
	var config := AeroInfluencerControlConfig.new()
	config.use_separate_minmax = true
	config.max_value = Vector3(0, 200.0, 0)
	config.min_value = Vector3.ZERO
	config.axis_configs.append(AeroInfluencerControlAxisConfig.new("throttle", Vector3.ONE))
	return config

func _init():
	super()
	
	show_torque = true
	show_thrust = true
	show_lift = false

# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	update_configuration_warnings()
	update_propeller_amount()
	
	if not Engine.is_editor_hint():
		if propeller_speed_control_config:
			propeller_speed_control_config = propeller_speed_control_config.duplicate(true)

func _get_configuration_warnings() -> PackedStringArray:
	var arr : PackedStringArray = PackedStringArray()#super._get_configuration_warnings()
	if not propeller_blade:
		arr.append("Propeller has not been assigned, or is not a valid instance. Make sure you have assigned an AeroInfluencer3D as a propeller.")
	
	return arr

func on_child_enter_tree(node : Node) -> void:
	super(node)
	
	if not propeller_blade and node is AeroInfluencer3D:
		propeller_blade = node

func update_propeller_amount() -> void:
	if not is_node_ready():
		return
	if not is_instance_valid(propeller_blade):
		push_warning("No propeller defined. Aborting...")
		return
	
	var change_in_amount : int = propeller_amount - propeller_instances.size()
	
	#remove propellers
	if change_in_amount < 0:
		for i : int in abs(change_in_amount):
			propeller_instances.pop_back().queue_free()
	#instance new propellers
	elif change_in_amount > 0:
		for i : int in change_in_amount:
			var new_prop : AeroInfluencer3D = propeller_blade.duplicate()
			add_child(new_prop)
			propeller_instances.append(new_prop)
	
	update_propeller_transforms()

func update_propeller_transforms() -> void:
	var base_transform : Transform3D = propeller_blade.default_transform
	
	for i in propeller_amount - 1:
		var prop_index = i + 1 #we already have 1 surface, so we add 1
		var new_blade : AeroInfluencer3D = propeller_instances[prop_index]
		
		new_blade.default_transform = base_transform.rotated(Vector3(0, 1, 0), deg_to_rad(360.0 / propeller_amount) * prop_index)
		new_blade.transform = new_blade.default_transform
		new_blade.default_transform.origin = base_transform.origin.rotated(Vector3(0, 1, 0), deg_to_rad(360.0 / propeller_amount) * prop_index)
		new_blade.position = new_blade.default_transform.origin

func _update_control_transform(substep_delta : float) -> void:
	super._update_control_transform(substep_delta)
	
	if propeller_speed_control_config:
		angular_motor = propeller_speed_control_config.update(self, substep_delta)

func get_angular_velocity() -> Vector3:
	if Engine.is_editor_hint() and propeller_speed_control_config:
			return super() + propeller_speed_control_config.max_value * global_basis.inverse()
	
	return super()
