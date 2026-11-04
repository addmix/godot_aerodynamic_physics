#include "aero_influencer_3d.h"

using namespace godot;

void AeroInfluencer3D::_bind_methods() {
	//ClassDB::bind_method(D_METHOD("default_calculate_forces", "substep_delta"), &AeroInfluencer3D::calculate_forces);
	//these are all virtuals
	GDVIRTUAL_BIND(_calculate_forces, "substep_delta");
	GDVIRTUAL_BIND(_update_transform_substep, "substep_delta");
	GDVIRTUAL_BIND(_update_control_transform, "substep_delta");
	GDVIRTUAL_BIND(is_overriding_body_sleep);
	//calculate_relative_position();
	//calculate_world_air_velocity();
	//calculate_linear_velocity();
	//calculate_angular_velocity();
	//calculate_centrifugal_offset();
	//calculate_linear_acceleration();
	//calculate_angular_acceleration();

	ClassDB::bind_method(D_METHOD("get_control_command"), &AeroInfluencer3D::get_control_command);
	//update_debug

	ClassDB::bind_method(D_METHOD("set_disabled", "p_disabled"), &AeroInfluencer3D::set_disabled);
	ClassDB::bind_method(D_METHOD("is_disabled"), &AeroInfluencer3D::is_disabled);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "disabled"), "set_disabled", "is_disabled");

	ClassDB::bind_method(D_METHOD("set_can_override_body_sleep", "can_override"), &AeroInfluencer3D::set_can_override_body_sleep);
	ClassDB::bind_method(D_METHOD("get_can_override_body_sleep"), &AeroInfluencer3D::get_can_override_body_sleep);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "can_override_body_sleep"), "set_can_override_body_sleep", "get_can_override_body_sleep");

	ADD_GROUP("Mirroring", "");
	ClassDB::bind_method(D_METHOD("set_mirror_axis", "axis"), &AeroInfluencer3D::set_mirror_axis);
	ClassDB::bind_method(D_METHOD("get_mirror_axis"), &AeroInfluencer3D::get_mirror_axis);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "mirror_axis", PROPERTY_HINT_ENUM, "None,X,Y,Z"), "set_mirror_axis", "get_mirror_axis");

	ClassDB::bind_method(D_METHOD("set_mirror_scaling_fix_axis", "axis"), &AeroInfluencer3D::set_mirror_scaling_fix_axis);
	ClassDB::bind_method(D_METHOD("get_mirror_scaling_fix_axis"), &AeroInfluencer3D::get_mirror_scaling_fix_axis);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "mirror_scaling_fix_axis", PROPERTY_HINT_ENUM, "None,X,Y,Z"), "set_mirror_scaling_fix_axis", "get_mirror_scaling_fix_axis");
	
	ClassDB::bind_method(D_METHOD("is_duplicate"), &AeroInfluencer3D::is_duplicate);
	
	ClassDB::bind_method(D_METHOD("get_mirror_duplicate"), &AeroInfluencer3D::get_mirror_duplicate);
	//ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "mirror_duplicate"), "", "get_mirror_duplicate");

	ADD_GROUP("Actuation Control", "");
	ADD_SUBGROUP("", "");
	ClassDB::bind_method(D_METHOD("set_actuation_config", "p_config"), &AeroInfluencer3D::set_actuation_config);
	ClassDB::bind_method(D_METHOD("get_actuation_config"), &AeroInfluencer3D::get_actuation_config);
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "actuation_config", PROPERTY_HINT_RESOURCE_TYPE, "AeroInfluencerControlConfig"), "set_actuation_config", "get_actuation_config");
	
	ClassDB::bind_method(D_METHOD("set_control_rotation_order", "rotation_order"), &AeroInfluencer3D::set_control_rotation_order);
	ClassDB::bind_method(D_METHOD("get_control_rotation_order"), &AeroInfluencer3D::get_control_rotation_order);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "control_rotation_order", PROPERTY_HINT_ENUM, "XYZ,XZY,YXZ,YZX,ZXY,ZYX"), "set_control_rotation_order", "get_control_rotation_order");

	ADD_GROUP("Debug", "");
	
	ClassDB::bind_method(D_METHOD("set_omit_from_debug", "omitted"), &AeroInfluencer3D::set_omit_from_debug);
	ClassDB::bind_method(D_METHOD("is_omitted_from_debug"), &AeroInfluencer3D::is_omitted_from_debug);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "omit_from_debug"), "set_omit_from_debug", "is_omitted_from_debug");
	
	ClassDB::bind_method(D_METHOD("set_debug_scale", "scale"), &AeroInfluencer3D::set_debug_scale);
	ClassDB::bind_method(D_METHOD("get_debug_scale"), &AeroInfluencer3D::get_debug_scale);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "debug_scale"), "set_debug_scale", "get_debug_scale");
	
	ClassDB::bind_method(D_METHOD("set_debug_scaling_factor", "scaling_factor"), &AeroInfluencer3D::set_debug_scaling_factor);
	ClassDB::bind_method(D_METHOD("get_debug_scaling_factor"), &AeroInfluencer3D::get_debug_scaling_factor);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "debug_scaling_factor"), "set_debug_scaling_factor", "get_debug_scaling_factor");

	ClassDB::bind_method(D_METHOD("set_debug_width", "width"), &AeroInfluencer3D::set_debug_width);
	ClassDB::bind_method(D_METHOD("get_debug_width"), &AeroInfluencer3D::get_debug_width);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "debug_width"), "set_debug_width", "get_debug_width");

	//update_debug_visibility
	GDVIRTUAL_BIND(update_debug_visibility);
	ClassDB::bind_method(D_METHOD("update_debug_visibility"), &AeroInfluencer3D::update_debug_visibility);

	ClassDB::bind_method(D_METHOD("set_show_debug", "show"), &AeroInfluencer3D::set_show_debug);
	ClassDB::bind_method(D_METHOD("get_show_debug"), &AeroInfluencer3D::get_show_debug);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "show_debug"), "set_show_debug", "get_show_debug");

	ADD_SUBGROUP("Visibility", "");
	ClassDB::bind_method(D_METHOD("set_show_force", "show"), &AeroInfluencer3D::set_show_force);
	ClassDB::bind_method(D_METHOD("get_show_force"), &AeroInfluencer3D::get_show_force);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "show_force"), "set_show_force", "get_show_force");

	ClassDB::bind_method(D_METHOD("set_show_torque", "show"), &AeroInfluencer3D::set_show_torque);
	ClassDB::bind_method(D_METHOD("get_show_torque"), &AeroInfluencer3D::get_show_torque);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "show_torque"), "set_show_torque", "get_show_torque");

	ClassDB::bind_method(D_METHOD("set_show_lift", "show"), &AeroInfluencer3D::set_show_lift);
	ClassDB::bind_method(D_METHOD("get_show_lift"), &AeroInfluencer3D::get_show_lift);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "show_lift"), "set_show_lift", "get_show_lift");

	ClassDB::bind_method(D_METHOD("set_show_drag", "show"), &AeroInfluencer3D::set_show_drag);
	ClassDB::bind_method(D_METHOD("get_show_drag"), &AeroInfluencer3D::get_show_drag);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "show_drag"), "set_show_drag", "get_show_drag");

	ClassDB::bind_method(D_METHOD("set_show_thrust", "show"), &AeroInfluencer3D::set_show_thrust);
	ClassDB::bind_method(D_METHOD("get_show_thrust"), &AeroInfluencer3D::get_show_thrust);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "show_thrust"), "set_show_thrust", "get_show_thrust");

	//the below properties are not shown in inspector
	ClassDB::bind_method(D_METHOD("get_aero_body"), &AeroInfluencer3D::get_aero_body);
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "aero_body", PROPERTY_HINT_NODE_TYPE, "AeroBody3D", PROPERTY_USAGE_STORAGE), "", "get_aero_body");
	
	ClassDB::bind_method(D_METHOD("set_default_transform", "new_transform"), &AeroInfluencer3D::set_default_transform);
	ClassDB::bind_method(D_METHOD("get_default_transform"), &AeroInfluencer3D::get_default_transform);
	ADD_PROPERTY(PropertyInfo(Variant::TRANSFORM3D, "default_transform", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "set_default_transform", "get_default_transform");
	ClassDB::bind_method(D_METHOD("get_altitude"), &AeroInfluencer3D::get_altitude);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "altitude", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_altitude");
	ClassDB::bind_method(D_METHOD("get_air_density"), &AeroInfluencer3D::get_air_density);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "air_density", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_air_density");
	ClassDB::bind_method(D_METHOD("get_relative_position"), &AeroInfluencer3D::get_relative_position);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "relative_position", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_relative_position");

	GDVIRTUAL_BIND(get_linear_velocity_substep);
	ClassDB::bind_method(D_METHOD("get_linear_velocity_substep"), &AeroInfluencer3D::get_linear_velocity_substep);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "linear_velocity_substep", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_linear_velocity_substep");
	GDVIRTUAL_BIND(get_angular_velocity_substep);
	ClassDB::bind_method(D_METHOD("get_angular_velocity_substep"), &AeroInfluencer3D::get_angular_velocity_substep);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "angular_velocity_substep", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_angular_velocity_substep");
	
	
	ClassDB::bind_method(D_METHOD("get_local_air_velocity"), &AeroInfluencer3D::get_local_air_velocity);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "local_air_velocity", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_local_air_velocity");
	ClassDB::bind_method(D_METHOD("get_world_air_velocity"), &AeroInfluencer3D::get_world_air_velocity);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "world_air_velocity", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_world_air_velocity");
	ClassDB::bind_method(D_METHOD("get_drag_direction"), &AeroInfluencer3D::get_drag_direction);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "drag_direction", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_drag_direction");
	ClassDB::bind_method(D_METHOD("get_air_speed"), &AeroInfluencer3D::get_air_speed);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "air_speed", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_air_speed");
	ClassDB::bind_method(D_METHOD("get_mach"), &AeroInfluencer3D::get_mach);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "mach", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_mach");
	ClassDB::bind_method(D_METHOD("get_dynamic_pressure"), &AeroInfluencer3D::get_dynamic_pressure);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "dynamic_pressure", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_dynamic_pressure");
	//ClassDB::bind_method(D_METHOD("get_centrifugal_offset"), &AeroInfluencer3D::get_centrifugal_offset);
	//ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "centrifugal", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_centrifugal_offset");
	ClassDB::bind_method(D_METHOD("get_linear_acceleration"), &AeroInfluencer3D::get_linear_acceleration);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "linear_acceleration", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_linear_acceleration");
	//ClassDB::bind_method(D_METHOD("get_angular_acceleration"), &AeroInfluencer3D::get_angular_acceleration);
	//ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "aero_body", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_angular_acceleration");
	ClassDB::bind_method(D_METHOD("get_current_force"), &AeroInfluencer3D::get_current_force);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "current_force", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_current_force");
	ClassDB::bind_method(D_METHOD("get_current_torque"), &AeroInfluencer3D::get_current_torque);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "current_torque", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_current_torque");
}

AeroInfluencer3D::AeroInfluencer3D() {
	mirror_duplicate = nullptr;
}

AeroInfluencer3D::~AeroInfluencer3D() {
	// Add your cleanup here.
}

void AeroInfluencer3D::_notification(int what) {
	switch (what) {
	case NOTIFICATION_TRANSFORM_CHANGED:
		if (is_inside_tree()) generate_mirror();
		break;
	}
}
void AeroInfluencer3D::_ready() {
	if (not Engine::get_singleton()->is_editor_hint()) {
		if (actuation_config.is_valid()) {
			actuation_config = actuation_config->duplicate(true);
		}
	}

	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = Object::cast_to<AeroInfluencer3D>(aero_influencers[i]);
		if (influencer) influencer->generate_mirror();
	}

	update_debug_visibility();
}
void AeroInfluencer3D::_enter_tree() {
	Node* parent = get_parent();
	if (AeroBody3D* body = Object::cast_to<AeroBody3D>(parent)) {
		aero_body = body;
		body->add_aero_influencer(this); //self-registration, matches main's _enter_tree
	} else if (AeroInfluencer3D* infl_parent = Object::cast_to<AeroInfluencer3D>(parent)) {
		aero_body = infl_parent->get_aero_body();
		if (infl_parent->_duplicate) _duplicate = true; //same class, private access OK
		infl_parent->aero_influencers.append(this);
	}

	default_transform = get_transform();
	if (mirror_scaling_fix_axis != 0) {
		set_mirror_scaling_fix_axis(mirror_scaling_fix_axis); //re-trigger setter now that we're in the tree
	}
}
void AeroInfluencer3D::_exit_tree() {
	Node* parent = get_parent();
	if (AeroInfluencer3D* infl_parent = Object::cast_to<AeroInfluencer3D>(parent)) {
		infl_parent->aero_influencers.erase(this);
	} else if (AeroBody3D* body = Object::cast_to<AeroBody3D>(parent)) {
		body->remove_aero_influencer(this); //self-unregistration, matches main's _exit_tree
	}
	aero_body = nullptr;
}
void AeroInfluencer3D::_physics_process(double delta) {
	if (Engine::get_singleton()->is_editor_hint()) return;
	if (get_transform() != last_transform) {
		if (aero_body) aero_body->interrupt_sleep(); //null guard: main would crash on null aero_body, C++ nullptr deref is worse
	}
	last_transform = get_transform();
}

ForceAndTorque AeroInfluencer3D::calculate_forces_with_override(double substep_delta) {
	ForceAndTorque force_and_torque = calculate_forces(substep_delta); //TODO - this is wrong, not properly implemented.
	//TODO revise this logic, may not be entirely necessary
	if (GDVIRTUAL_IS_OVERRIDDEN(_calculate_forces)) {
		PackedVector3Array result;
		GDVIRTUAL_CALL(_calculate_forces, substep_delta, result);
		
		//do post-calculate_forces code, like updating current_force and current_torque.

		if (result.size() < 2) return ForceAndTorque();

		force_and_torque = ForceAndTorque(result[0], result[1]);
	}
	//do post-calculate_forces code, like updating current_force and current_torque.
	
	current_force = force_and_torque.force;
	current_torque = force_and_torque.torque;

	return force_and_torque;
}

ForceAndTorque AeroInfluencer3D::calculate_forces(double substep_delta) {
	linear_velocity_substep = calculate_linear_velocity_substep();
	angular_velocity_substep = calculate_angular_velocity_substep();

	relative_position = calculate_relative_position();
	air_density = aero_body->get_air_density();
	world_air_velocity = calculate_world_air_velocity();

	for (int i = 0; i < aero_body->get_atmosphere_areas().size(); i++) {
		Area3D* atmosphere = Object::cast_to<Area3D>(aero_body->get_atmosphere_areas()[i]);
		if (not atmosphere) continue;
		if (not atmosphere->get("per_influencer_positioning")) continue;
		if (not atmosphere->call("is_inside_atmosphere", get_global_position())) continue; //error here
		
		if (atmosphere->get("override_density")) {
			air_density = atmosphere->call("get_density_at_position", get_global_position());
		}
		if (atmosphere->get("override_wind")) {
			world_air_velocity = -linear_velocity_substep + atmosphere->get("wind");
		}

		/*
		#this is a kinda bad way to do it tbh. It's difficult to separate global
		#effects from atmosphere-specific effects.
		#ideally, the global atmosphere can be converted into it's own atmosphere area
		
		#we can create a fake atmosphere node as a proxy for the AeroUnits singleton
		#that way global aero isn't constrained by the bounds of a collision shape
		
		#also, atmospheres should be given a priority value so they can be ordered deterministically
		#and give more flexibility for wind/density values
		*/
	}
	
	air_speed = world_air_velocity.length();
	altitude = aero_body->get_altitude();
	dynamic_pressure = 0.5 * air_density * air_speed * air_speed;
	drag_direction = world_air_velocity.normalized();
	local_air_velocity = get_global_basis().xform_inv(world_air_velocity);
	
	mach = AeroUnits::get_singleton()->speed_to_mach_at_altitude(air_speed, altitude);
	
	//TODO replace current_force/torque with single ForceAndTorque variable
	current_force = Vector3();
	current_torque = Vector3();

	ForceAndTorque total_force_and_torque;

	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = Object::cast_to<AeroInfluencer3D>(aero_influencers[i]);
		if (not influencer) continue;
		if (influencer->is_disabled()) continue;

		ForceAndTorque force_and_torque = influencer->calculate_forces_with_override(substep_delta);
		total_force_and_torque += force_and_torque;
	}
	
	return total_force_and_torque;
}

double AeroInfluencer3D::get_control_command(StringName axis_name) {
	if (get_parent()->is_class("AeroInfluencer3D")) {
		AeroInfluencer3D* parent = (AeroInfluencer3D*) get_parent();
		if (not parent) return 0.0;
		
		return parent->get_control_command(axis_name);
	}
	else if (get_parent()->is_class("AeroBody3D")) {
		AeroBody3D* parent = (AeroBody3D*) get_parent();
		if (not parent) return 0.0;

		return parent->get_control_command(axis_name);
	}
	return 0.0;
}
//TODO add virtual for this func
void AeroInfluencer3D::_update_transform_substep(double substep_delta) {
	if (GDVIRTUAL_IS_OVERRIDDEN(_update_transform_substep)) {
		GDVIRTUAL_CALL(_update_transform_substep, substep_delta);
	}

	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = Object::cast_to<AeroInfluencer3D>(aero_influencers[i]);
		if (not influencer) continue;
		if (influencer->is_disabled()) continue;
		
		influencer->_update_transform_substep(substep_delta);
	}

	_update_control_transform(substep_delta);
}
void AeroInfluencer3D::_update_control_transform(double substep_delta) {
	Vector3 actuation_value = Vector3();
	if (actuation_config.is_valid()) {
		actuation_value = actuation_config->call("update", this, substep_delta);
	}

	//might be incorrect behavior, may need to set basis directly with: basis = ...
	set_basis(default_transform.basis * Basis::from_euler(actuation_value, (godot::EulerOrder) control_rotation_order));

	if (GDVIRTUAL_IS_OVERRIDDEN(_update_control_transform)) {
		GDVIRTUAL_CALL(_update_control_transform, substep_delta);
	}
}
//TODO add virtual for this func
bool AeroInfluencer3D::is_overriding_body_sleep() {
	if (not can_override_body_sleep) {
		return false;
	}
	
	bool overriding = false;

	// if (GDVIRTUAL_IS_OVERRIDDEN(_update_control_transform)) {
	// 	PackedVector3Array result;
	// 	GDVIRTUAL_CALL(_update_control_transform, substep_delta);
	// }

	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = Object::cast_to<AeroInfluencer3D>(aero_influencers[i]);
		if (not influencer) continue;
		if (influencer->is_disabled()) continue;

		overriding = overriding or influencer->is_overriding_body_sleep();
	}
	
	return overriding;
}








Vector3 AeroInfluencer3D::calculate_relative_position() {
	if (get_parent()->is_class("AeroInfluencer3D")){
		AeroInfluencer3D* parent = (AeroInfluencer3D*) get_parent();
		return parent->get_relative_position() + (parent->get_global_basis().xform(get_position()));
	}
	else if (get_parent()->is_class("AeroBody3D")){
		AeroBody3D* parent = (AeroBody3D*) get_parent();
		return parent->get_relative_position() + (parent->get_global_basis().xform(get_position()));
	}

	return Vector3();
}
Vector3 AeroInfluencer3D::calculate_world_air_velocity() { //this function is redundant and should be removed.
	return -linear_velocity_substep + aero_body->get_wind();
}
Vector3 AeroInfluencer3D::calculate_linear_velocity_substep() {
	if (get_parent()->is_class("AeroInfluencer3D")){
		AeroInfluencer3D* parent = (AeroInfluencer3D*) get_parent();
		//TODO - Make sure this is actually used properly. this was the cause of substeps not working in previous versions
		return parent->get_linear_velocity_substep() + parent->get_angular_velocity_substep().cross(parent->get_global_basis().xform(get_position()));
	}
	else if (get_parent()->is_class("AeroBody3D")){
		AeroBody3D* parent = (AeroBody3D*) get_parent();
		//TODO - Make sure this is actually used properly. this was the cause of substeps not working in previous versions
		return parent->get_linear_velocity_substep() + parent->get_angular_velocity_substep().cross(parent->get_global_basis().xform(get_position()));
	} 
	return Vector3();
}
Vector3 AeroInfluencer3D::calculate_angular_velocity_substep() {
	if (get_parent()->is_class("AeroInfluencer3D")){
		AeroInfluencer3D* parent = (AeroInfluencer3D*) get_parent();
		//TODO - Make sure this is actually used properly. this was the cause of substeps not working in previous versions
		return parent->get_angular_velocity_substep();
	}
	else if (get_parent()->is_class("AeroBody3D")){
		AeroBody3D* parent = (AeroBody3D*) get_parent();
		//TODO - Make sure this is actually used properly. this was the cause of substeps not working in previous versions
		return parent->get_angular_velocity_substep();
	}
	return Vector3();
}
//virtual?
Vector3 AeroInfluencer3D::calculate_centrifugal_offset() {
	return get_position();
}
//TODO
Vector3 AeroInfluencer3D::calculate_linear_acceleration() {
	return Vector3();
}
//TODO
Vector3 AeroInfluencer3D::calculate_angular_acceleration() {
	return Vector3();
}



void AeroInfluencer3D::update_debug(){
	if (not is_inside_tree()) return;
	
	//TODO: Move this v3_log_with_base and basis stuff into the AeroDebugVector class
	if (force_debug_vector) {
		force_debug_vector->set("value", get_global_basis().xform_inv(AeroUtils::v3log_with_base(get_current_force(), debug_scaling_factor)) * debug_scale);
	}
	if (torque_debug_vector) {
		torque_debug_vector->set("value", get_global_basis().xform_inv(AeroUtils::v3log_with_base(get_current_torque(), debug_scaling_factor)) * debug_scale);
	}
	if (lift_debug_vector) {
		Vector3 lift = get_current_force() - get_current_force().dot(get_drag_direction()) * get_drag_direction();
		lift_debug_vector->set("value", get_global_basis().xform_inv(AeroUtils::v3log_with_base(lift, debug_scaling_factor)) * debug_scale);
	}
	if (drag_debug_vector) {
		Vector3 drag = double(UtilityFunctions::max(get_current_force().dot(get_drag_direction()), 0.0)) * get_drag_direction();
		drag_debug_vector->set("value", get_global_basis().xform_inv(AeroUtils::v3log_with_base(drag, debug_scaling_factor)) * debug_scale);
	}
	if (thrust_debug_vector) {
		Vector3 thrust = double(UtilityFunctions::min(get_current_force().dot(get_drag_direction()), 0.0)) * get_drag_direction();
		thrust_debug_vector->set("value", get_global_basis().xform_inv(AeroUtils::v3log_with_base(thrust, debug_scaling_factor)) * debug_scale);
	}	

	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = Object::cast_to<AeroInfluencer3D>(aero_influencers[i]);
		if (not influencer) continue;
		influencer->update_debug();
	}
}

void AeroInfluencer3D::set_disabled(const int p_disabled) {
	disabled = p_disabled;
}
int AeroInfluencer3D::is_disabled() const {
	return disabled;
}
void AeroInfluencer3D::set_can_override_body_sleep(bool override) {
	can_override_body_sleep = override;
}
bool AeroInfluencer3D::get_can_override_body_sleep() {
	return can_override_body_sleep;
}
void AeroInfluencer3D::set_mirror_axis(int axis) {
	mirror_axis = axis; //mirror regeneration happens via NOTIFICATION_TRANSFORM_CHANGED and the _ready loops
}
int AeroInfluencer3D::get_mirror_axis() {
	return mirror_axis;
}
void AeroInfluencer3D::generate_mirror() {
	if (mirror_axis == 0 or _duplicate) return; //no duplication
	
	if (mirror_duplicate) {
		mirror_duplicate->queue_free();
		mirror_duplicate = nullptr;
	}

	//remove debug vectors befor duplication, to prevent duplicating them
	bool temp_show_debug = get_show_debug();
	set_show_debug(false);

	int x = mirror_axis;
	mirror_axis = 0;
	mirror_duplicate = Object::cast_to<AeroInfluencer3D>(duplicate()); //Node::duplicate() default flags include DEEP - matches main's no-arg duplicate()
	
	//restore debug vectors after duplication has completed.
	set_show_debug(temp_show_debug);

	if (not mirror_duplicate) return; //something went wrong when duplicating and type casting

	mirror_duplicate->_duplicate = true;
	mirror_duplicate->mirror_duplicate = nullptr;
	mirror_duplicate->set_name(String(get_name()) + String("Mirror"));

	mirror_axis = x;
	mirror_duplicate->mirror_axis = x;

	Vector3 flip(1.0, 1.0, 1.0); //Vector3::ONE not available in this godot-cpp version
	flip[x - 1] = -1.0;
	mirror_duplicate->set_position(mirror_duplicate->get_position() * flip);
	Basis b = mirror_duplicate->get_basis();
	mirror_duplicate->set_basis(Basis::from_scale(flip) * b);
	mirror_duplicate->default_transform = mirror_duplicate->get_transform(); //main: default_transform = transform

	get_parent()->add_child(mirror_duplicate);
}
void AeroInfluencer3D::set_mirror_scaling_fix_axis(int axis) {
	mirror_scaling_fix_axis = axis;
	if (is_inside_tree()) {
		//undo previous mirroring
		if (_duplicate and _mirror_scaling_fix_axis != 0) {
			Basis b = get_basis();
			b[_mirror_scaling_fix_axis - 1] *= -1.0;
			set_basis(b);
		}
		_mirror_scaling_fix_axis = axis;
		//do new mirroring
		if (_duplicate and _mirror_scaling_fix_axis != 0) {
			Basis b = get_basis();
			b[_mirror_scaling_fix_axis - 1] *= -1.0;
			set_basis(b);
			default_transform = get_basis(); //main: default_transform = basis (zero origin)
		}
	}
}
int AeroInfluencer3D::get_mirror_scaling_fix_axis() const {
	return mirror_scaling_fix_axis;
}
void AeroInfluencer3D::set_duplicate(const bool value){
	_duplicate = value;
}
bool AeroInfluencer3D::is_duplicate() const {
	return _duplicate;
}
AeroInfluencer3D* AeroInfluencer3D::get_mirror_duplicate() {
	return mirror_duplicate;
}
void AeroInfluencer3D::set_actuation_config(const Ref<Resource> &p_config) {
	actuation_config = p_config;
}
Ref<Resource> AeroInfluencer3D::get_actuation_config() const {
	return actuation_config;
}
void AeroInfluencer3D::set_control_rotation_order(int rotation_order) {
	control_rotation_order = rotation_order;
}
int AeroInfluencer3D::get_control_rotation_order() {
	return control_rotation_order;
}
bool AeroInfluencer3D::is_omitted_from_debug() const {
	return omit_from_debug;
}
void AeroInfluencer3D::set_omit_from_debug(const bool omit) {
	omit_from_debug = omit;
}
void AeroInfluencer3D::set_debug_scale(const double value) {
	debug_scale = value;

	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = Object::cast_to<AeroInfluencer3D>(aero_influencers[i]);
		if (not influencer) continue;
		influencer->set_debug_scale(debug_scale);
	}

	
}
double AeroInfluencer3D::get_debug_scale() const {
	return debug_scale;
}
void AeroInfluencer3D::set_debug_scaling_factor(const double scaling_factor) {
	debug_scaling_factor = scaling_factor;
	//TODO - update scaling factor on debug vectors

	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = Object::cast_to<AeroInfluencer3D>(aero_influencers[i]);
		if (not influencer) continue;
		influencer->set_debug_scaling_factor(debug_scaling_factor);
	}
}
double AeroInfluencer3D::get_debug_scaling_factor() const {
	return debug_scaling_factor;
}
void AeroInfluencer3D::set_debug_width(const double value) {
	debug_width = value;
	//TODO implement the rest of the debug vectors
	if (force_debug_vector) {
		force_debug_vector->set("width", debug_width);
	}
	if (torque_debug_vector) {
		torque_debug_vector->set("width", debug_width);
	}
	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = Object::cast_to<AeroInfluencer3D>(aero_influencers[i]);
		if (not influencer) continue;
		influencer->set_debug_width(debug_width);
	}
}
double AeroInfluencer3D::get_debug_width() const {
	return debug_width;
}

Node3D* create_debug_vector(Node *node, String name, Color color = Color(1.0, 1.0, 1.0), bool checker = true) {
	Node3D *vector = memnew(MeshInstance3D);
	vector->set_script(ResourceLoader::get_singleton()->load("res://addons/godot_aerodynamic_physics/utils/vector_3d/vector_3d.gd"));
	vector->set_name(name);

	vector->set("color", color);
	vector->set("checker", checker);

	node->add_child(vector, godot::Node::INTERNAL_MODE_FRONT);
	return vector;
}
void destroy_debug_vector(Node3D*& vector) {
	vector->queue_free();
	vector = nullptr;
}

void AeroInfluencer3D::update_debug_visibility() {
	if (show_debug and show_force and not force_debug_vector) force_debug_vector = create_debug_vector(this, "ForceDebug", Color(1.0, 1.0, 1.0));
	if (show_debug and show_torque and not torque_debug_vector) torque_debug_vector = create_debug_vector(this, "TorqueDebug", Color(0.0, 0.0, 0.0), false);
	if (show_debug and show_lift and not lift_debug_vector) lift_debug_vector = create_debug_vector(this, "LiftDebug", Color(0.0, 0.0, 1.0), false);
	if (show_debug and show_drag and not drag_debug_vector) drag_debug_vector = create_debug_vector(this, "DragDebug", Color(1.0, 0.0, 0.0), false);
	if (show_debug and show_thrust and not thrust_debug_vector) thrust_debug_vector = create_debug_vector(this, "ThrustDebug", Color(1.0, 0.0, 1.0));

	if ((not show_debug or not show_force) and force_debug_vector) destroy_debug_vector(force_debug_vector);
	if ((not show_debug or not show_torque) and torque_debug_vector) destroy_debug_vector(torque_debug_vector);
	if ((not show_debug or not show_lift) and lift_debug_vector) destroy_debug_vector(lift_debug_vector);
	if ((not show_debug or not show_drag) and drag_debug_vector) destroy_debug_vector(drag_debug_vector);
	if ((not show_debug or not show_thrust) and thrust_debug_vector) destroy_debug_vector(thrust_debug_vector);

	if (GDVIRTUAL_IS_OVERRIDDEN(update_debug_visibility)) {
		GDVIRTUAL_CALL(update_debug_visibility);
	}
}

//create virtual function for this
void AeroInfluencer3D::set_show_debug(const bool value) {
	bool update_visibility = show_debug != value;
	show_debug = value;
	
	if (update_visibility) update_debug_visibility();

	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = Object::cast_to<AeroInfluencer3D>(aero_influencers[i]);
		if (not influencer) continue;
		influencer->set_show_debug(show_debug);
	}

	
}
bool AeroInfluencer3D::get_show_debug() const {
	return show_debug;
}
void AeroInfluencer3D::set_show_force(bool show) {
	bool update_visibility = show_force != show;
	show_force = show;

	if(update_visibility) update_debug_visibility();
}
bool AeroInfluencer3D::get_show_force() {
	return show_force;
}
void AeroInfluencer3D::set_show_torque(bool show) {
	bool update_visibility = show_torque != show;
	show_torque = show;

	if(update_visibility) update_debug_visibility();
}
bool AeroInfluencer3D::get_show_torque() {
	return show_torque;
}
void AeroInfluencer3D::set_show_lift(bool show) {
	bool update_visibility = show_lift != show;
	show_lift = show;

	if(update_visibility) update_debug_visibility();
}
bool AeroInfluencer3D::get_show_lift() {
	return show_lift;
}
void AeroInfluencer3D::set_show_drag(bool show) {
	bool update_visibility = show_drag != show;
	show_drag = show;

	if(update_visibility) update_debug_visibility();
}
bool AeroInfluencer3D::get_show_drag() {
	return show_drag;
}
void AeroInfluencer3D::set_show_thrust(bool show) {
	bool update_visibility = show_thrust != show;
	show_thrust = show;

	if(update_visibility) update_debug_visibility();
}
bool AeroInfluencer3D::get_show_thrust() {
	return show_thrust;
}
void AeroInfluencer3D::set_aero_body(AeroBody3D *p_new_body) {
    aero_body = p_new_body;
}
AeroBody3D* AeroInfluencer3D::get_aero_body() const {
	return aero_body;
}
void AeroInfluencer3D::set_aero_influencers(const TypedArray<AeroInfluencer3D> &new_arr) {
    aero_influencers.assign(new_arr);
}
TypedArray<AeroInfluencer3D> AeroInfluencer3D::get_aero_influencers() const {
	return aero_influencers;
}
void AeroInfluencer3D::set_default_transform(Transform3D new_transform) {
	default_transform = new_transform;
}
Transform3D AeroInfluencer3D::get_default_transform() const {
	return default_transform;
}
double AeroInfluencer3D::get_altitude() const {
	return altitude;
}
double AeroInfluencer3D::get_air_density() const {
	return air_density;
}
Vector3 AeroInfluencer3D::get_relative_position() const {
	return relative_position;
}
Vector3 AeroInfluencer3D::get_linear_velocity_substep() {
	if (GDVIRTUAL_IS_OVERRIDDEN(get_linear_velocity_substep)) {
		Vector3 result = Vector3();
		GDVIRTUAL_CALL(get_linear_velocity_substep, result);
		return result;
	}

	return linear_velocity_substep;
}
Vector3 AeroInfluencer3D::get_angular_velocity_substep() {
	if (GDVIRTUAL_IS_OVERRIDDEN(get_angular_velocity_substep)) {
		Vector3 result = Vector3();
		GDVIRTUAL_CALL(get_angular_velocity_substep, result);
		return result;
	}
	
	return angular_velocity_substep;
}
Vector3 AeroInfluencer3D::get_local_air_velocity() const {
	return local_air_velocity;
}
Vector3 AeroInfluencer3D::get_world_air_velocity() const {
	return world_air_velocity;
}
Vector3 AeroInfluencer3D::get_drag_direction() const {
	return drag_direction;
}
double AeroInfluencer3D::get_air_speed() const {
	return air_speed;
}
double AeroInfluencer3D::get_mach() const {
	return mach;
}
double AeroInfluencer3D::get_dynamic_pressure() const {
	return dynamic_pressure;
}
Vector3 AeroInfluencer3D::get_centrifugal_offset() const {
	return Vector3(); //TODO
}
Vector3 AeroInfluencer3D::get_linear_acceleration() const {
	return Vector3(); //TODO
}
Vector3 AeroInfluencer3D::get_angular_acceleration() const {
	return Vector3(); //TODO
}
Vector3 AeroInfluencer3D::get_current_force() const {
	return current_force;
}
Vector3 AeroInfluencer3D::get_current_torque() const {
	return current_torque;
}
