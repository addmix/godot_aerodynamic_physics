#include "aero_influencer_3d.h"

using namespace godot;

void AeroInfluencer3D::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_disabled", "p_disabled"), &AeroInfluencer3D::set_disabled);
	ClassDB::bind_method(D_METHOD("is_disabled"), &AeroInfluencer3D::is_disabled);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "disabled"), "set_disabled", "is_disabled");

	ClassDB::bind_method(D_METHOD("set_actuation_config", "p_config"), &AeroInfluencer3D::set_actuation_config);
	ClassDB::bind_method(D_METHOD("get_actuation_config"), &AeroInfluencer3D::get_actuation_config);
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "actuation_config", PROPERTY_HINT_RESOURCE_TYPE, "AeroInfluencerControlConfig"), "set_actuation_config", "get_actuation_config");

	ClassDB::bind_method(D_METHOD("set_enable_automatic_control", "p_enable_automatic_control"), &AeroInfluencer3D::set_enable_automatic_control);
	ClassDB::bind_method(D_METHOD("get_enable_automatic_control"), &AeroInfluencer3D::get_enable_automatic_control);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "enable_automatic_control"), "set_enable_automatic_control", "get_enable_automatic_control");

	ClassDB::bind_method(D_METHOD("set_control_command", "p_control_command"), &AeroInfluencer3D::set_control_command);
	ClassDB::bind_method(D_METHOD("get_control_command"), &AeroInfluencer3D::get_control_command);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "control_command"), "set_control_command", "get_control_command");
	
	ClassDB::bind_method(D_METHOD("set_throttle_command", "p_max_actuation"), &AeroInfluencer3D::set_throttle_command);
	ClassDB::bind_method(D_METHOD("get_throttle_command"), &AeroInfluencer3D::get_throttle_command);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "throttle_command"), "set_throttle_command", "get_throttle_command");

	ClassDB::bind_method(D_METHOD("set_brake_command", "p_brake_command"), &AeroInfluencer3D::set_brake_command);
	ClassDB::bind_method(D_METHOD("get_brake_command"), &AeroInfluencer3D::get_brake_command);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "brake_command"), "set_brake_command", "get_brake_command");

	ClassDB::bind_method(D_METHOD("set_max_actuation", "p_max_actuation"), &AeroInfluencer3D::set_max_actuation);
	ClassDB::bind_method(D_METHOD("get_max_actuation"), &AeroInfluencer3D::get_max_actuation);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "max_actuation"), "set_max_actuation", "get_max_actuation");

	ClassDB::bind_method(D_METHOD("set_pitch_contribution", "p_pitch_contribution"), &AeroInfluencer3D::set_pitch_contribution);
	ClassDB::bind_method(D_METHOD("get_pitch_contribution"), &AeroInfluencer3D::get_pitch_contribution);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "pitch_contribution"), "set_pitch_contribution", "get_pitch_contribution");

	ClassDB::bind_method(D_METHOD("set_yaw_contribution", "p_yaw_contribution"), &AeroInfluencer3D::set_yaw_contribution);
	ClassDB::bind_method(D_METHOD("get_yaw_contribution"), &AeroInfluencer3D::get_yaw_contribution);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "yaw_contribution"), "set_yaw_contribution", "get_yaw_contribution");

	ClassDB::bind_method(D_METHOD("set_roll_contribution", "p_roll_contribution"), &AeroInfluencer3D::set_roll_contribution);
	ClassDB::bind_method(D_METHOD("get_roll_contribution"), &AeroInfluencer3D::get_roll_contribution);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "roll_contribution"), "set_roll_contribution", "get_roll_contribution");

	ClassDB::bind_method(D_METHOD("set_brake_contribution", "p_brake_contribution"), &AeroInfluencer3D::set_brake_contribution);
	ClassDB::bind_method(D_METHOD("get_brake_contribution"), &AeroInfluencer3D::get_brake_contribution);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "brake_contribution"), "set_brake_contribution", "get_brake_contribution");

	ClassDB::bind_method(D_METHOD("set_void", "unused_value"), &AeroInfluencer3D::set_void);

	ClassDB::bind_method(D_METHOD("get_world_air_velocity"), &AeroInfluencer3D::get_world_air_velocity);
	ClassDB::bind_method(D_METHOD("get_linear_velocity"), &AeroInfluencer3D::get_linear_velocity);
	
	//these cause godot to crash from some reason
	//ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "world_air_velocity"), "", "get_world_air_velocity");
	//ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "world_air_velocity"), "set_void", "get_world_air_velocity");
	ClassDB::bind_method(D_METHOD("get_dynamic_pressure"), &AeroInfluencer3D::get_dynamic_pressure);
	ClassDB::bind_method(D_METHOD("get_mach"), &AeroInfluencer3D::get_mach);
	ClassDB::bind_method(D_METHOD("get_air_speed"), &AeroInfluencer3D::get_air_speed);
	ClassDB::bind_method(D_METHOD("get_relative_position"), &AeroInfluencer3D::get_relative_position);
	ClassDB::bind_method(D_METHOD("get_drag_direction"), &AeroInfluencer3D::get_drag_direction);

	ClassDB::bind_method(D_METHOD("get_current_force"), &AeroInfluencer3D::get_current_force);
	ClassDB::bind_method(D_METHOD("set_current_force", "force"), &AeroInfluencer3D::set_current_force);
	ClassDB::bind_method(D_METHOD("get_current_torque"), &AeroInfluencer3D::get_current_torque);
	ClassDB::bind_method(D_METHOD("set_current_torque", "torque"), &AeroInfluencer3D::set_current_torque);

	ClassDB::bind_method(D_METHOD("set_aero_influencers", "in_arr"), &AeroInfluencer3D::set_aero_influencers);
	ClassDB::bind_method(D_METHOD("get_aero_influencers"), &AeroInfluencer3D::get_aero_influencers);
    ClassDB::add_property(get_class_static(), PropertyInfo(Variant::ARRAY, "aero_influencer_array", PROPERTY_HINT_TYPE_STRING, vformat("%s/%s:%s", Variant::OBJECT, PROPERTY_HINT_NODE_TYPE, "Node")), "set_aero_influencers", "get_aero_influencers");

	//register function so we can use it with a signal.
	ClassDB::bind_method(D_METHOD("on_child_entered_tree", "node"), &AeroInfluencer3D::on_child_entered_tree);
	ClassDB::bind_method(D_METHOD("on_child_exiting_tree", "node"), &AeroInfluencer3D::on_child_exiting_tree);

	//ClassDB::bind_method(D_METHOD("default_calculate_forces", "substep_delta"), &AeroInfluencer3D::calculate_forces);
	//ClassDB::bind_virtual_method("AeroInfluencer3D", "_calculate_forces");
	GDVIRTUAL_BIND(_calculate_forces, "substep_delta");
}

AeroInfluencer3D::AeroInfluencer3D() {
	vector_3d_script = ResourceLoader::get_singleton()->load("res://addons/godot_aerodynamic_physics/utils/vector_3d/vector_3d.gd");
	point_3d_script = ResourceLoader::get_singleton()->load("res://addons/godot_aerodynamic_physics/utils/point_3d/point_3d.gd");
}

AeroInfluencer3D::~AeroInfluencer3D() {
	// Add your cleanup here.
}


void AeroInfluencer3D::_enter_tree() {}
void AeroInfluencer3D::_ready() {
	this->connect("child_entered_tree", Callable(this, "on_child_entered_tree"));
	this->connect("child_exiting_tree", Callable(this, "on_child_exiting_tree"));
}
void AeroInfluencer3D::on_child_entered_tree(const Variant &node) {
	Node* typed_node = (Node*) (Object*) node;
	//UtilityFunctions::print("child added ", typed_node->get_name());

	if (typed_node->is_class("AeroInfluencer3D")) {
		AeroInfluencer3D* influencer = (AeroInfluencer3D*) (Object*) typed_node;

		aero_influencers.append(influencer);
		influencer->set_aero_body(aero_body);
	}
}
void AeroInfluencer3D::on_child_exiting_tree(const Variant &node) {
	Node* typed_node = (Node*) (Object*) node;
	//UtilityFunctions::print("child removed ", typed_node->get_name());

	if (typed_node->is_class("AeroInfluencer3D")) {
		AeroInfluencer3D* influencer = (AeroInfluencer3D*) (Object*) typed_node;

		aero_influencers.erase(node);
		influencer->set_aero_body(nullptr);
	}
}
void AeroInfluencer3D::_process(double delta) {}
void AeroInfluencer3D::_physics_process(double delta) {
	if (is_overriding_body_sleep() and ObjectDB::get_instance(aero_body->get_instance_id()) != NULL) {
		aero_body->set_sleeping(false);
	}
}

ForceAndTorque AeroInfluencer3D::calculate_forces_with_override(double substep_delta) {
	if (GDVIRTUAL_IS_OVERRIDDEN(_calculate_forces)) {
		PackedVector3Array result;
		GDVIRTUAL_CALL(_calculate_forces, substep_delta, result);
		UtilityFunctions::print("running gdscript override");
		return ForceAndTorque(result[0], result[1]);
	}
	
	return this->calculate_forces(substep_delta);
}

ForceAndTorque AeroInfluencer3D::calculate_forces(double substep_delta) {
	linear_velocity = get_linear_velocity();
	angular_velocity = get_angular_velocity();

	relative_position = get_relative_position();
	world_air_velocity = get_world_air_velocity();
	air_speed = world_air_velocity.length();
	air_density = aero_body->get_air_density();
	altitude = aero_body->get_altitude();
	dynamic_pressure = 0.5 * aero_body->get_air_density() * aero_body->get_air_speed() * aero_body->get_air_speed();
	drag_direction = world_air_velocity.normalized();
	local_air_velocity = get_global_basis().xform_inv(world_air_velocity);
	
	mach = AeroUnits::get_singleton()->speed_to_mach_at_altitude(air_speed, altitude);
	
	ForceAndTorque total_force_and_torque;

	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = Object::cast_to<AeroInfluencer3D>(aero_influencers[i]);
		if (not influencer) continue;

		ForceAndTorque force_and_torque = influencer->calculate_forces_with_override(substep_delta);
		total_force_and_torque += force_and_torque;
	}

	total_force_and_torque.torque += relative_position.cross(total_force_and_torque.force);

	_current_force = total_force_and_torque.force;
	_current_torque = total_force_and_torque.torque;
	
	return total_force_and_torque;
}
//must be virtual
void AeroInfluencer3D::_update_transform_substep(double substep_delta) {
	return;
}
//must be virtual
void AeroInfluencer3D::_update_control_transform(double substep_delta) {
	if (not enable_automatic_control) return;

	/*
	
	control_command = get_parent().control_command
	throttle_command = get_parent().throttle_command
	brake_command = get_parent().brake_command
	
	var pitch_actuation : Vector3 = pitch_contribution * control_command.x
	var yaw_actuation : Vector3 = yaw_contribution * control_command.y
	var roll_actuation : Vector3 = roll_contribution * control_command.z
	var brake_actuation : Vector3 = brake_contribution * brake_command
	
	var total_control_actuation : Vector3 = Vector3(
		pitch_actuation.x + yaw_actuation.x + roll_actuation.x + brake_actuation.x,
		pitch_actuation.y + yaw_actuation.y + roll_actuation.y + brake_actuation.y,
		pitch_actuation.z + yaw_actuation.z + roll_actuation.z + brake_actuation.z
	)
	total_control_actuation = total_control_actuation.clamp(-Vector3.ONE, Vector3.ONE)
	
	basis = default_transform.basis * Basis().from_euler(total_control_actuation * max_actuation, control_rotation_order)

	*/
}


bool AeroInfluencer3D::is_overriding_body_sleep() {
	bool overriding = false;

	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = Object::cast_to<AeroInfluencer3D>(aero_influencers[i]);
		if (not influencer) continue;
		overriding = overriding or influencer->is_overriding_body_sleep();
	}
	
	return overriding;
};
void AeroInfluencer3D::set_void(Vector3 value) {
	return;
}
Vector3 AeroInfluencer3D::get_relative_position() {
	if (get_parent()->is_class("AeroInfluencer3D") or get_parent()->is_class("AeroBody3D")){
		AeroInfluencer3D* parent = (AeroInfluencer3D*) get_parent();
		return parent->get_relative_position() + (parent->get_global_basis().xform(get_position()));
	}
	return Vector3();
}
Vector3 AeroInfluencer3D::get_world_air_velocity() {
	if (get_parent()->is_class("AeroInfluencer3D")){
		AeroInfluencer3D* parent = (AeroInfluencer3D*) get_parent();
		return -(parent->get_linear_velocity());
	}
	else if (get_parent()->is_class("AeroBody3D")) {
		AeroBody3D* parent = (AeroBody3D*) get_parent();
		return -(parent->get_linear_velocity());
	}
	return Vector3();
}
Vector3 AeroInfluencer3D::get_linear_velocity() {
	if (get_parent()->is_class("AeroInfluencer3D") or get_parent()->is_class("AeroBody3D")){
		AeroInfluencer3D* parent = (AeroInfluencer3D*) get_parent();
		return parent->get_linear_velocity() + parent->get_angular_velocity().cross(parent->get_global_basis().xform(get_position()));
	}
	return Vector3();
}
Vector3 AeroInfluencer3D::get_angular_velocity() const {
	if (get_parent()->is_class("AeroInfluencer3D") or get_parent()->is_class("AeroBody3D")){
		AeroInfluencer3D* parent = (AeroInfluencer3D*) get_parent();
		return parent->get_angular_velocity();
	}
	return Vector3();
}
//virtual?
Vector3 AeroInfluencer3D::get_centrifugal_offset() {
	return get_position();
	
}
Vector3 AeroInfluencer3D::get_linear_acceleration() {
	return Vector3();
}
Vector3 AeroInfluencer3D::get_angular_acceleration() {
	if (get_parent()->is_class("AeroInfluencer3D") or get_parent()->is_class("AeroBody3D")){
		AeroInfluencer3D* parent = (AeroInfluencer3D*) get_parent();
		return parent->get_angular_acceleration();
	}
	return Vector3();
}
double AeroInfluencer3D::get_dynamic_pressure() {
	return dynamic_pressure;
}
double AeroInfluencer3D::get_mach() {
	return mach;
}
double AeroInfluencer3D::get_air_speed() {
	return air_speed;
}
Vector3 AeroInfluencer3D::get_drag_direction() {
	return drag_direction;
}

Vector3 AeroInfluencer3D::get_current_force() {
	return _current_force;
}
void AeroInfluencer3D::set_current_force(Vector3 force) {
	_current_force = force;
}
Vector3 AeroInfluencer3D::get_current_torque() {
	return _current_torque;
}
void AeroInfluencer3D::set_current_torque(Vector3 torque) {
	_current_torque = torque;
}



void AeroInfluencer3D::set_disabled(const int p_disabled) {
	disabled = p_disabled;
}
int AeroInfluencer3D::is_disabled() const {
	return disabled;
}
void AeroInfluencer3D::set_enable_automatic_control(const bool p_enable_automatic_control) {
	enable_automatic_control = p_enable_automatic_control;
}
bool AeroInfluencer3D::get_enable_automatic_control() const {
	return enable_automatic_control;
}
void AeroInfluencer3D::set_control_command(const Vector3 p_control_command) {
	control_command = p_control_command;
}
Vector3 AeroInfluencer3D::get_control_command() const {
	return control_command;
}
void AeroInfluencer3D::set_throttle_command(const double p_throttle_command) {
	throttle_command = p_throttle_command;
}
double AeroInfluencer3D::get_throttle_command() const {
	return throttle_command;
}
void AeroInfluencer3D::set_brake_command(const double p_brake_command) {
	brake_command = p_brake_command;
}
double AeroInfluencer3D::get_brake_command() const {
	return brake_command;
}
void AeroInfluencer3D::set_max_actuation(const Vector3 p_max_actuation) {
	max_actuation = p_max_actuation;
}
Vector3 AeroInfluencer3D::get_max_actuation() const {
	return max_actuation;
}
void AeroInfluencer3D::set_pitch_contribution(const Vector3 p_pitch_contribution) {
	pitch_contribution = p_pitch_contribution;
}
Vector3 AeroInfluencer3D::get_pitch_contribution() const {
	return pitch_contribution;
}
void AeroInfluencer3D::set_yaw_contribution(const Vector3 p_yaw_contribution) {
	yaw_contribution = p_yaw_contribution;
}
Vector3 AeroInfluencer3D::get_yaw_contribution() const {
	return yaw_contribution;
}
void AeroInfluencer3D::set_roll_contribution(const Vector3 p_roll_contribution) {
	roll_contribution = p_roll_contribution;
}
Vector3 AeroInfluencer3D::get_roll_contribution() const {
	return roll_contribution;
}
void AeroInfluencer3D::set_brake_contribution(const Vector3 p_brake_contribution) {
	brake_contribution = p_brake_contribution;
}
Vector3 AeroInfluencer3D::get_brake_contribution() const {
	return brake_contribution;
}


void AeroInfluencer3D::set_aero_body(AeroBody3D *p_new_body) {
    aero_body = p_new_body;
}
void AeroInfluencer3D::set_aero_influencers(const TypedArray<AeroInfluencer3D> new_arr) {
    aero_influencers.assign(new_arr);
}
TypedArray<AeroInfluencer3D> AeroInfluencer3D::get_aero_influencers() const { return aero_influencers; }

void AeroInfluencer3D::update_debug(){
	if (not is_inside_tree()) return;

	if (force_debug_vector) {
		force_debug_vector->set("value", get_global_basis().xform_inv(get_current_force()) * debug_scale);
	}
	if (torque_debug_vector) {
		torque_debug_vector->set("value", get_global_basis().xform_inv(get_current_torque()) * debug_scale);
	}

	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = Object::cast_to<AeroInfluencer3D>(aero_influencers[i]);
		if (not influencer) continue;
		influencer->update_debug();
	}
}

void AeroInfluencer3D::set_show_debug(const bool value) {
	show_debug = value;
	if (show_debug) {
		if (not force_debug_vector) {
			force_debug_vector = memnew(MeshInstance3D);
			force_debug_vector->set_script(vector_3d_script);
			force_debug_vector->set_name("ForceDebug");

			force_debug_vector->set("color", Color(1.0, 1.0, 1.0));
			force_debug_vector->set("checker", true);
			add_child(force_debug_vector, INTERNAL_MODE_FRONT);
		}
		if (not torque_debug_vector) {
			torque_debug_vector = memnew(MeshInstance3D);
			torque_debug_vector->set_script(vector_3d_script);
			torque_debug_vector->set_name("ForceDebug");

			torque_debug_vector->set("color", Color(0.0, 0.5, 0.0));
			add_child(torque_debug_vector, INTERNAL_MODE_FRONT);
		}
	} else {
		if (force_debug_vector) {
			force_debug_vector->queue_free();
			force_debug_vector = nullptr;
		}
		if (torque_debug_vector) {
			torque_debug_vector->queue_free();
			torque_debug_vector = nullptr;
		}
	}

	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = Object::cast_to<AeroInfluencer3D>(aero_influencers[i]);
		if (not influencer) continue;
		influencer->set_show_debug(show_debug);
	}
}
void AeroInfluencer3D::set_debug_scale(const double value) {
	debug_scale = value;

	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = Object::cast_to<AeroInfluencer3D>(aero_influencers[i]);
		if (not influencer) continue;
		influencer->set_debug_scale(debug_scale);
	}
}
void AeroInfluencer3D::set_debug_width(const double value) {
	debug_width = value;

	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = Object::cast_to<AeroInfluencer3D>(aero_influencers[i]);
		if (not influencer) continue;
		influencer->set_debug_width(debug_width);
	}
	if (force_debug_vector) {
		force_debug_vector->set("width", debug_width);
	}
	if (torque_debug_vector) {
		torque_debug_vector->set("width", debug_width);
	}
}


void AeroInfluencer3D::set_actuation_config(const Ref<Resource> &p_config) {actuation_config = p_config;};
Ref<Resource> AeroInfluencer3D::get_actuation_config() const {return actuation_config;};
