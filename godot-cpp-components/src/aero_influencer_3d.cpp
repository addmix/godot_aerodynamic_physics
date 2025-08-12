#include "aero_influencer_3d.h"

using namespace godot;

void AeroInfluencer3D::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_disabled", "p_disabled"), &AeroInfluencer3D::set_disabled);
	ClassDB::bind_method(D_METHOD("is_disabled"), &AeroInfluencer3D::is_disabled);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "disabled"), "set_disabled", "is_disabled");

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
	//these cause godot to crash from some reason
	//ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "world_air_velocity"), "", "get_world_air_velocity");
	//ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "world_air_velocity"), "set_void", "get_world_air_velocity");
	ClassDB::bind_method(D_METHOD("get_dynamic_pressure"), &AeroInfluencer3D::get_dynamic_pressure);
	ClassDB::bind_method(D_METHOD("get_mach"), &AeroInfluencer3D::get_mach);
	ClassDB::bind_method(D_METHOD("get_air_speed"), &AeroInfluencer3D::get_air_speed);
	ClassDB::bind_method(D_METHOD("get_relative_position"), &AeroInfluencer3D::get_relative_position);

	ClassDB::bind_method(D_METHOD("get_current_force"), &AeroInfluencer3D::get_current_force);
	ClassDB::bind_method(D_METHOD("set_current_force", "force"), &AeroInfluencer3D::set_current_force);
	ClassDB::bind_method(D_METHOD("get_current_torque"), &AeroInfluencer3D::get_current_torque);
	ClassDB::bind_method(D_METHOD("set_current_torque", "torque"), &AeroInfluencer3D::set_current_torque);

	ClassDB::bind_method(D_METHOD("set_array", "in_arr"), &AeroInfluencer3D::set_aero_influencers);
	ClassDB::bind_method(D_METHOD("get_array"), &AeroInfluencer3D::get_aero_influencers);
    ClassDB::add_property(get_class_static(), PropertyInfo(Variant::ARRAY, "node2DArray", PROPERTY_HINT_TYPE_STRING, vformat("%s/%s:%s", Variant::OBJECT, PROPERTY_HINT_NODE_TYPE, "Node")), "set_array", "get_array");

	//register function so we can use it with a signal.
	ClassDB::bind_method(D_METHOD("on_child_entered_tree", "node"), &AeroInfluencer3D::on_child_entered_tree);
	ClassDB::bind_method(D_METHOD("on_child_exiting_tree", "node"), &AeroInfluencer3D::on_child_exiting_tree);

	ClassDB::bind_method(D_METHOD("default_calculate_forces", "substep_delta"), &AeroInfluencer3D::calculate_forces);
	//ClassDB::bind_virtual_method("AeroInfluencer3D", "_calculate_forces");
	GDVIRTUAL_BIND(_calculate_forces, "substep_delta");
}

AeroInfluencer3D::AeroInfluencer3D() {
	// Initialize any variables here.
	disabled = false;
	enable_automatic_control = true;
	control_command = Vector3(0.0, 0.0, 0.0);
}

AeroInfluencer3D::~AeroInfluencer3D() {
	// Add your cleanup here.
}

void AeroInfluencer3D::_notification(int p_notification) {
	switch (p_notification) {
	case NOTIFICATION_ENTER_TREE:
		on_enter_tree();
	case NOTIFICATION_READY:
		on_ready();
	case NOTIFICATION_PROCESS:
		on_process(get_process_delta_time());
	case NOTIFICATION_PHYSICS_PROCESS:
		on_physics_process(get_physics_process_delta_time());
	}
}
void AeroInfluencer3D::on_enter_tree() {}
void AeroInfluencer3D::on_ready() {
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
void AeroInfluencer3D::on_process(double delta) {}
void AeroInfluencer3D::on_physics_process(double delta) {
	//update_debug_vectors();

	if (is_overriding_body_sleep() and ObjectDB::get_instance(aero_body->get_instance_id()) != NULL) {
		aero_body->set_sleeping(false);
	}
}

PackedVector3Array AeroInfluencer3D::calculate_forces_with_override(double substep_delta) {
	if (GDVIRTUAL_IS_OVERRIDDEN(_calculate_forces)) {
		PackedVector3Array result;
		GDVIRTUAL_CALL(_calculate_forces, substep_delta, result);
		return result;
	}
	
	return calculate_forces(substep_delta);
}

PackedVector3Array AeroInfluencer3D::calculate_forces(double substep_delta) {
	linear_velocity = get_linear_velocity();
	angular_velocity = get_angular_velocity();

	relative_position = get_relative_position();
	world_air_velocity = get_world_air_velocity();
	air_speed = world_air_velocity.length();
	//UtilityFunctions::print(world_air_velocity);
	air_density = aero_body->get_air_density();
	altitude = aero_body->get_altitude();
	local_air_velocity = get_global_basis().xform_inv(world_air_velocity);

	if (has_node("/root/AeroUnits")) {
		
		Node AeroUnits = *get_node_or_null("/root/AeroUnits");
		mach = AeroUnits.call("speed_to_mach_at_altitude", air_speed, altitude);
		dynamic_pressure = 0.5 * (double) AeroUnits.call("get_density_at_altitude", altitude) * (air_speed * air_speed);
	}
	else {
		UtilityFunctions::print("AeroUnits not available");
	}
	//error if AeroUnits isn't available

	Vector3 force = Vector3();
	Vector3 torque = Vector3();

	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = (AeroInfluencer3D*) (Object*) aero_influencers[i];

		PackedVector3Array force_and_torque = influencer->calculate_forces_with_override(substep_delta);
		force += force_and_torque[0];
		torque += force_and_torque[1];
	}

	torque += relative_position.cross(force);

	_current_force = force;
	_current_torque = torque;
	
	PackedVector3Array total_force_and_torque = PackedVector3Array();
	total_force_and_torque.append(force);
	total_force_and_torque.append(torque);
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
		AeroInfluencer3D* influencer = (AeroInfluencer3D*) (Object*) aero_influencers[i];
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
		return (parent)->get_relative_position() + (parent->get_global_basis().xform(get_position()));
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
Vector3 AeroInfluencer3D::get_angular_velocity() {
	if (get_parent()->is_class("AeroInfluencer3D") or get_parent()->is_class("AeroBody3D")){
		AeroInfluencer3D* parent = (AeroInfluencer3D*) get_parent();
		parent->get_angular_velocity();
	}
	return Vector3();
}
//virtual?
Vector3 AeroInfluencer3D::get_centrifugal_offset() {
	return get_position();
	
}
Vector3 AeroInfluencer3D::get_linear_acceleration() {

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


