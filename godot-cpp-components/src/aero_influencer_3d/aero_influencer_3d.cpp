#include "aero_influencer_3d.h"

using namespace godot;

void AeroInfluencer3D::_bind_methods() {
	//ClassDB::bind_method(D_METHOD("default_calculate_forces", "substep_delta"), &AeroInfluencer3D::calculate_forces);
	//these are all virtuals
	GDVIRTUAL_BIND(_calculate_forces, "substep_delta");
	GDVIRTUAL_BIND(_update_transform_substep, "substep_delta");
	GDVIRTUAL_BIND(_update_control_transform, "substep_delta");
	GDVIRTUAL_BIND(is_overriding_body_sleep);
	GDVIRTUAL_BIND(calculate_linear_velocity_substep);
	GDVIRTUAL_BIND(calculate_angular_velocity_substep);
	GDVIRTUAL_BIND(get_centrifugal_offset);
	ClassDB::bind_method(D_METHOD("_update_transform_substep", "substep_delta"), &AeroInfluencer3D::_update_transform_substep);
	ClassDB::bind_method(D_METHOD("_update_control_transform", "substep_delta"), &AeroInfluencer3D::_update_control_transform);
	ClassDB::bind_method(D_METHOD("update_debug_vectors"), &AeroInfluencer3D::update_debug_vectors);
	ClassDB::bind_method(D_METHOD("set_cached_transform", "transform"), &AeroInfluencer3D::set_cached_transform);
	ClassDB::bind_method(D_METHOD("get_cached_local_transform"), &AeroInfluencer3D::get_cached_local_transform);
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

	ClassDB::bind_method(D_METHOD("is_overriding_body_sleep"), &AeroInfluencer3D::is_overriding_body_sleep_with_override);

	ADD_GROUP("Mirroring", "");
	ClassDB::bind_method(D_METHOD("set_mirror_axis", "axis"), &AeroInfluencer3D::set_mirror_axis);
	ClassDB::bind_method(D_METHOD("get_mirror_axis"), &AeroInfluencer3D::get_mirror_axis);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "mirror_axis", PROPERTY_HINT_ENUM, "None,X,Y,Z"), "set_mirror_axis", "get_mirror_axis");

	ClassDB::bind_method(D_METHOD("set_mirror_scaling_fix_axis", "axis"), &AeroInfluencer3D::set_mirror_scaling_fix_axis);
	ClassDB::bind_method(D_METHOD("get_mirror_scaling_fix_axis"), &AeroInfluencer3D::get_mirror_scaling_fix_axis);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "mirror_scaling_fix_axis", PROPERTY_HINT_ENUM, "None,X,Y,Z"), "set_mirror_scaling_fix_axis", "get_mirror_scaling_fix_axis");
	
	ClassDB::bind_method(D_METHOD("is_mirrored"), &AeroInfluencer3D::is_mirrored);
	ClassDB::bind_method(D_METHOD("is_mirror_pending"), &AeroInfluencer3D::is_mirror_pending);
	
	ClassDB::bind_method(D_METHOD("get_mirror_duplicate"), &AeroInfluencer3D::get_mirror_duplicate);
	ClassDB::bind_method(D_METHOD("set_duplicate", "value"), &AeroInfluencer3D::set_duplicate);
	ClassDB::bind_method(D_METHOD("is_duplicate"), &AeroInfluencer3D::is_duplicate);


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
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "aero_body", PROPERTY_HINT_NODE_TYPE, "AeroBody3D", PROPERTY_USAGE_NONE), "", "get_aero_body");
	
	ClassDB::bind_method(D_METHOD("set_default_transform", "new_transform"), &AeroInfluencer3D::set_default_transform);
	ClassDB::bind_method(D_METHOD("get_default_transform"), &AeroInfluencer3D::get_default_transform);
	ADD_PROPERTY(PropertyInfo(Variant::TRANSFORM3D, "default_transform", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "set_default_transform", "get_default_transform");
	ClassDB::bind_method(D_METHOD("get_altitude"), &AeroInfluencer3D::get_altitude);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "altitude", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_altitude");
	ClassDB::bind_method(D_METHOD("get_air_density"), &AeroInfluencer3D::get_air_density);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "air_density", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_air_density");
	ClassDB::bind_method(D_METHOD("get_relative_position"), &AeroInfluencer3D::get_relative_position);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "relative_position", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_relative_position");

	ClassDB::bind_method(D_METHOD("calculate_linear_velocity_substep"), &AeroInfluencer3D::calculate_linear_velocity_substep);
	ClassDB::bind_method(D_METHOD("calculate_angular_velocity_substep"), &AeroInfluencer3D::calculate_angular_velocity_substep);

	ClassDB::bind_method(D_METHOD("get_linear_velocity_substep"), &AeroInfluencer3D::get_linear_velocity_substep);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "linear_velocity_substep", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_linear_velocity_substep");
	ClassDB::bind_method(D_METHOD("get_angular_velocity_substep"), &AeroInfluencer3D::get_angular_velocity_substep);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "angular_velocity_substep", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_angular_velocity_substep");
	
	
	ClassDB::bind_method(D_METHOD("get_local_air_velocity"), &AeroInfluencer3D::get_local_air_velocity);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "local_air_velocity", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_local_air_velocity");
	ClassDB::bind_method(D_METHOD("get_world_air_velocity"), &AeroInfluencer3D::get_world_air_velocity);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "world_air_velocity", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_world_air_velocity");
	ClassDB::bind_method(D_METHOD("get_drag_direction"), &AeroInfluencer3D::get_drag_direction);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "drag_direction", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_drag_direction");
	ClassDB::bind_method(D_METHOD("get_air_speed"), &AeroInfluencer3D::get_air_speed);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "air_speed", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_air_speed");
	ClassDB::bind_method(D_METHOD("get_mach"), &AeroInfluencer3D::get_mach);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "mach", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_mach");
	ClassDB::bind_method(D_METHOD("get_dynamic_pressure"), &AeroInfluencer3D::get_dynamic_pressure);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "dynamic_pressure", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_dynamic_pressure");
	ClassDB::bind_method(D_METHOD("get_centrifugal_offset"), &AeroInfluencer3D::get_centrifugal_offset);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "centrifugal_offset", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_centrifugal_offset");
	ClassDB::bind_method(D_METHOD("get_linear_acceleration"), &AeroInfluencer3D::get_linear_acceleration);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "linear_acceleration", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_linear_acceleration");
	ClassDB::bind_method(D_METHOD("get_angular_acceleration"), &AeroInfluencer3D::get_angular_acceleration);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "angular_acceleration", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_angular_acceleration");
	ClassDB::bind_method(D_METHOD("get_current_force"), &AeroInfluencer3D::get_current_force);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "current_force", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_current_force");
	ClassDB::bind_method(D_METHOD("get_current_torque"), &AeroInfluencer3D::get_current_torque);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "current_torque", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_current_torque");
}

AeroInfluencer3D::AeroInfluencer3D() {
	mirror_duplicate = nullptr;
}

AeroInfluencer3D::~AeroInfluencer3D() {
	// Add your cleanup here.
}

void AeroInfluencer3D::_notification(int what) {
	switch (what) {
	case NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
		local_transform_cache = get_transform();

		if (is_inside_tree()) {
			Transform3D parent_global = Transform3D();
			if (parent_influencer) {
				parent_global = parent_influencer->get_cached_global_transform();
			} else if (aero_body) {
				parent_global = aero_body->get_cached_global_transform();
			}

			update_transform_cache(parent_global);

			//mirroring is its own inverse, so whichever half was moved pushes the mirrored transform to the
			//other. the equality check ends the bounce: the other half then pushes back the same value
			if (Engine::get_singleton()->is_editor_hint() and mirror_duplicate) {
				const Transform3D mirrored = calculate_mirrored_transform(get_transform());
				if (mirror_duplicate->get_transform() != mirrored) mirror_duplicate->set_transform(mirrored);
			}
		}
		break;
	}
}
void AeroInfluencer3D::_ready() {
	if (not Engine::get_singleton()->is_editor_hint()) {
		if (actuation_config.is_valid()) set_actuation_config(actuation_config->duplicate(true));
	}

	//a node added to an already-ready body never reaches the body's _ready loop
	Node *parent = get_parent();
	if (parent and parent->is_node_ready()) generate_mirror();

	if (_duplicate and mirror_duplicate) update_mirror_transform();

	const size_t influencer_count = aero_influencers.size();
	for (size_t i = 0; i < influencer_count; i++) {
		AeroInfluencer3D* influencer = aero_influencers[i];
		if (influencer) influencer->generate_mirror();
	}


	update_debug_visibility();
}
void AeroInfluencer3D::refresh_virtual_override_cache() {
	calculate_forces_overridden = GDVIRTUAL_IS_OVERRIDDEN(_calculate_forces);
	update_transform_substep_overridden = GDVIRTUAL_IS_OVERRIDDEN(_update_transform_substep);
	update_control_transform_overridden = GDVIRTUAL_IS_OVERRIDDEN(_update_control_transform);
	linear_velocity_substep_overridden = GDVIRTUAL_IS_OVERRIDDEN(calculate_linear_velocity_substep);
	angular_velocity_substep_overridden = GDVIRTUAL_IS_OVERRIDDEN(calculate_angular_velocity_substep);
	body_sleep_overridden = GDVIRTUAL_IS_OVERRIDDEN(is_overriding_body_sleep);
}
void AeroInfluencer3D::_enter_tree() {
	refresh_virtual_override_cache();

	parent_influencer = nullptr;

	Node* parent = get_parent();
	if (AeroBody3D* body = Object::cast_to<AeroBody3D>(parent)) {
		aero_body = body;
		body->add_aero_influencer(this);
	} else if (AeroInfluencer3D* infl_parent = Object::cast_to<AeroInfluencer3D>(parent)) {
		parent_influencer = infl_parent;
		aero_body = infl_parent->get_aero_body();
		if (infl_parent->_duplicate) _duplicate = true;
		infl_parent->aero_influencers.push_back(this);
	}

	default_transform = get_transform();
	local_transform_cache = default_transform;
	global_transform_cache = get_global_transform();


	set_notify_local_transform(true);
}
void AeroInfluencer3D::_exit_tree() {
	if (mirror_duplicate) {
		if (mirror_duplicate->mirror_duplicate == this) mirror_duplicate->mirror_duplicate = nullptr;
		mirror_duplicate = nullptr;
	}

	if (parent_influencer) {
		for (size_t i = 0; i < parent_influencer->aero_influencers.size(); i++) {
			if (parent_influencer->aero_influencers[i] == this) {
				parent_influencer->aero_influencers.erase(parent_influencer->aero_influencers.begin() + i);
				break;
			}
		}
	} else if (aero_body) {
		aero_body->remove_aero_influencer(this);
	}
	parent_influencer = nullptr;
	aero_body = nullptr;
}
void AeroInfluencer3D::_physics_process(double delta) {
	if (Engine::get_singleton()->is_editor_hint()) return;
	if (get_transform() != last_transform) {
		if (aero_body and aero_body->is_sleeping()) aero_body->interrupt_sleep();
	}
	last_transform = get_transform();
}

void AeroInfluencer3D::update_transform_cache(const Transform3D &parent_global_transform) {
	global_transform_cache = parent_global_transform * local_transform_cache;

	for (AeroInfluencer3D* influencer : aero_influencers) {
		if (not influencer) continue;

		influencer->update_transform_cache(global_transform_cache);
	}
}
void AeroInfluencer3D::set_cached_transform(const Transform3D &p_transform) {
	if (p_transform == local_transform_cache) return;

	set_transform(p_transform);
}
const Transform3D &AeroInfluencer3D::get_cached_local_transform() const {
	return local_transform_cache;
}
Vector3 AeroInfluencer3D::get_cached_position() const {
	return local_transform_cache.origin;
}
const Transform3D &AeroInfluencer3D::get_cached_global_transform() const {
	return global_transform_cache;
}
Basis AeroInfluencer3D::get_cached_global_basis() const {
	return global_transform_cache.basis;
}

ForceAndTorque AeroInfluencer3D::calculate_forces_with_override(double substep_delta) {
	ForceAndTorque force_and_torque = calculate_forces(substep_delta);

	if (calculate_forces_overridden) {
		PackedVector3Array result;
		GDVIRTUAL_CALL(_calculate_forces, substep_delta, result);
		if (result.size() >= 2) {
			ForceAndTorque own_force_and_torque(result[0], result[1]);
			force_and_torque += own_force_and_torque;
			current_force = own_force_and_torque.force;
			current_torque = own_force_and_torque.torque;
		}
	}

	return force_and_torque;
}

ForceAndTorque AeroInfluencer3D::calculate_forces(double substep_delta) {
	if (not aero_body) return ForceAndTorque();

	linear_velocity_substep = calculate_linear_velocity_substep_with_override();
	angular_velocity_substep = calculate_angular_velocity_substep_with_override();

	relative_position = calculate_relative_position();
	air_density = aero_body->get_air_density();
	world_air_velocity = calculate_world_air_velocity();

	for (Area3D* atmosphere : aero_body->get_atmosphere_areas_internal()) {
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
	local_air_velocity = get_cached_global_basis().xform_inv(world_air_velocity);
	
	if (AeroUnits::get_singleton()) {
		mach = AeroUnits::get_singleton()->speed_to_mach_at_altitude(air_speed, altitude);
	} else {
		mach = 0.0;
	}
	
	//TODO replace current_force/torque with single ForceAndTorque variable
	current_force = Vector3();
	current_torque = Vector3();

	ForceAndTorque total_force_and_torque;

	const size_t influencer_count = aero_influencers.size();
	for (size_t i = 0; i < influencer_count; i++) {
		AeroInfluencer3D* influencer = aero_influencers[i];
		if (not influencer) continue;
		if (influencer->is_disabled()) continue;

		ForceAndTorque force_and_torque = influencer->calculate_forces_with_override(substep_delta);
		total_force_and_torque += force_and_torque;
	}
	
	return total_force_and_torque;
}

double AeroInfluencer3D::get_control_command(StringName axis_name) {
	if (parent_influencer) {
		return parent_influencer->get_control_command(axis_name);
	}
	else if (aero_body) {
		return aero_body->get_control_command(axis_name);
	}
	return 0.0;
}
void AeroInfluencer3D::_update_transform_substep_with_override(double substep_delta) {
	if (update_transform_substep_overridden) {
		GDVIRTUAL_CALL(_update_transform_substep, substep_delta);
	} else {
		_update_transform_substep(substep_delta);
	}
}
void AeroInfluencer3D::_update_transform_substep(double substep_delta) {
	const size_t influencer_count = aero_influencers.size();
	for (size_t i = 0; i < influencer_count; i++) {
		AeroInfluencer3D* influencer = aero_influencers[i];
		if (not influencer) continue;
		if (influencer->is_disabled()) continue;
		
		influencer->_update_transform_substep_with_override(substep_delta);
	}

	_update_control_transform_with_override(substep_delta);
}
void AeroInfluencer3D::_update_control_transform_with_override(double substep_delta) {
	if (update_control_transform_overridden) {
		GDVIRTUAL_CALL(_update_control_transform, substep_delta);
	} else {
		_update_control_transform(substep_delta);
	}
}
void AeroInfluencer3D::_update_control_transform(double substep_delta) {
	Basis new_basis;
	Vector3 actuation_value = Vector3();
	if (actuation_config.is_valid()) {
		actuation_value = actuation_config->call("update", this, substep_delta);
	}

	if (actuation_value != Vector3()) {
		new_basis = default_transform.basis * Basis::from_euler(actuation_value, (godot::EulerOrder) control_rotation_order);
	} else {
		if (default_transform == local_transform_cache) return;

		new_basis = default_transform.basis;
	}

	set_cached_transform(Transform3D(new_basis, local_transform_cache.origin));
}
bool AeroInfluencer3D::is_overriding_body_sleep_with_override() {
	if (body_sleep_overridden and not in_body_sleep_override) {
		in_body_sleep_override = true;
		bool result = false;
		GDVIRTUAL_CALL(is_overriding_body_sleep, result);
		in_body_sleep_override = false;
		if (result) return true;
	}

	return is_overriding_body_sleep();
}
bool AeroInfluencer3D::is_overriding_body_sleep() const {
	if (not can_override_body_sleep) {
		return false;
	}

	for (AeroInfluencer3D* influencer : aero_influencers) {
		if (not influencer) continue;
		if (influencer->is_disabled()) continue;

		if (influencer->is_overriding_body_sleep_with_override()) return true;
	}

	return false;
}








Vector3 AeroInfluencer3D::calculate_relative_position() const {
	if (parent_influencer) {
		return parent_influencer->get_relative_position() + (parent_influencer->get_cached_global_basis().xform(get_cached_position()));
	}
	else if (aero_body) {
		return aero_body->get_relative_position() + (aero_body->get_cached_global_basis().xform(get_cached_position()));
	}

	return Vector3();
}
Vector3 AeroInfluencer3D::calculate_world_air_velocity() const { //this function is redundant and should be removed.
	return -linear_velocity_substep + aero_body->get_wind();
}
Vector3 AeroInfluencer3D::calculate_linear_velocity_substep_with_override() {
	if (linear_velocity_substep_overridden) {
		Vector3 result = Vector3();
		GDVIRTUAL_CALL(calculate_linear_velocity_substep, result);
		return result;
	}

	return calculate_linear_velocity_substep();
}
Vector3 AeroInfluencer3D::calculate_linear_velocity_substep() const {
	if (parent_influencer) {
		return parent_influencer->get_linear_velocity_substep() + parent_influencer->get_angular_velocity_substep().cross(parent_influencer->get_cached_global_basis().xform(get_cached_position()));
	}
	else if (aero_body) {
		return aero_body->get_linear_velocity_substep() + aero_body->get_angular_velocity_substep().cross(aero_body->get_cached_global_basis().xform(get_cached_position()));
	} 
	return Vector3();
}
Vector3 AeroInfluencer3D::calculate_angular_velocity_substep_with_override() {
	if (angular_velocity_substep_overridden) {
		Vector3 result = Vector3();
		GDVIRTUAL_CALL(calculate_angular_velocity_substep, result);
		return result;
	}

	return calculate_angular_velocity_substep();
}
Vector3 AeroInfluencer3D::calculate_angular_velocity_substep() const {
	if (parent_influencer) {
		return parent_influencer->get_angular_velocity_substep();
	}
	else if (aero_body) {
		return aero_body->get_angular_velocity_substep();
	}
	return Vector3();
}
//virtual?
Vector3 AeroInfluencer3D::calculate_centrifugal_offset() {
	return get_centrifugal_offset();
}
Vector3 AeroInfluencer3D::calculate_linear_acceleration() {
	return get_linear_acceleration();
}
Vector3 AeroInfluencer3D::calculate_angular_acceleration() const {
	return get_angular_acceleration();
}



void AeroInfluencer3D::update_debug_vectors(){
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
		Vector3 drag = Math::max(get_current_force().dot(get_drag_direction()), (real_t)0.0) * get_drag_direction();
		drag_debug_vector->set("value", get_global_basis().xform_inv(AeroUtils::v3log_with_base(drag, debug_scaling_factor)) * debug_scale);
	}
	if (thrust_debug_vector) {
		Vector3 thrust = Math::min(get_current_force().dot(get_drag_direction()), (real_t)0.0) * get_drag_direction();
		thrust_debug_vector->set("value", get_global_basis().xform_inv(AeroUtils::v3log_with_base(thrust, debug_scaling_factor)) * debug_scale);
	}	

	for (AeroInfluencer3D* influencer : aero_influencers) {
		if (not influencer) continue;
		influencer->update_debug_vectors();
	}
}

void AeroInfluencer3D::set_disabled(int p_disabled) {
	if (disabled == p_disabled) return;

	disabled = p_disabled;
	update_gizmos();

	if (mirror_duplicate) mirror_duplicate->set_disabled(p_disabled);
}
int AeroInfluencer3D::is_disabled() const {
	return disabled;
}
void AeroInfluencer3D::set_can_override_body_sleep(bool override) {
	if (can_override_body_sleep == override) return;
	
	can_override_body_sleep = override;

	if (mirror_duplicate) mirror_duplicate->set_can_override_body_sleep(override);
}
bool AeroInfluencer3D::get_can_override_body_sleep() const {
	return can_override_body_sleep;
}
void AeroInfluencer3D::set_mirror_axis(int axis) {
	if (mirror_axis == axis) return;

	mirror_axis = axis;

	if (axis == 0) {
		if (mirror_duplicate) {
			mirror_duplicate->mirror_duplicate = nullptr;
			mirror_duplicate->queue_free();
			mirror_duplicate = nullptr;
		}
		return;
	}

	if (mirror_duplicate) mirror_duplicate->mirror_axis = axis; //both halves reflect through the same axis

	AeroInfluencer3D *mirrored_copy = _duplicate ? this : mirror_duplicate;
	if (mirrored_copy) {
		mirrored_copy->update_mirror_transform();
	} else if (is_inside_tree()) {
		generate_mirror();
	}
}
int AeroInfluencer3D::get_mirror_axis() const {
	return mirror_axis;
}
void AeroInfluencer3D::generate_mirror() {
	if (mirror_axis == 0 or _duplicate) return;
	if (parent_influencer and parent_influencer->mirror_axis != 0) return;
	if (mirror_duplicate) return;

	//the copy is saved with the scene, so it may already be there under its generated name
	if (Node *parent = get_parent()) {
		AeroInfluencer3D *saved_copy = Object::cast_to<AeroInfluencer3D>(parent->get_node_or_null(String(get_name()) + String("Mirror")));
		if (saved_copy and saved_copy->mirror_axis == mirror_axis and not saved_copy->mirror_duplicate) {
			mirror_duplicate = saved_copy;
			saved_copy->mirror_duplicate = this;
			saved_copy->_duplicate = true;
			map_mirror_sources(this, saved_copy);
			saved_copy->update_mirror_transform();
			return;
		}
	}
	
	//remove debug vectors befor duplication, to prevent duplicating them
	bool temp_show_debug = get_show_debug();
	set_show_debug(false);

	int x = mirror_axis;
	mirror_axis = 0;
	mirror_duplicate = Object::cast_to<AeroInfluencer3D>(duplicate());
	
	set_show_debug(temp_show_debug);

	if (not mirror_duplicate) return;

	mirror_duplicate->_duplicate = true;
	mirror_duplicate->set_name(String(get_name()) + String("Mirror"));

	mirror_axis = x;
	mirror_duplicate->mirror_axis = x;

	mirror_duplicate->mirror_duplicate = this;
	map_mirror_sources(this, mirror_duplicate);

	Node *parent = get_parent();
	parent->add_child(mirror_duplicate);
	mirror_duplicate->update_mirror_transform();

	//keep the copy next to its original in the tree
	parent->move_child(mirror_duplicate, get_index(true) + 1);

	//give the copy the same owner so it is saved to the scene
	if (Engine::get_singleton()->is_editor_hint() and get_owner()) {
		Node *owner = get_owner();
		if (owner == parent or owner->is_ancestor_of(parent)) {
			set_owner_recursive(mirror_duplicate, owner);
		}
	}
}
bool AeroInfluencer3D::is_mirrored() const {
	return mirror_axis != 0 or _duplicate;
}
bool AeroInfluencer3D::is_mirror_pending() const {
	return mirror_axis != 0 and not _duplicate and not mirror_duplicate;
}
void AeroInfluencer3D::set_owner_recursive(Node *p_node, Node *p_owner) {
	p_node->set_owner(p_owner);

	for (int i = 0; i < p_node->get_child_count(); i++) {
		set_owner_recursive(p_node->get_child(i), p_owner);
	}
}
Transform3D AeroInfluencer3D::calculate_mirrored_transform(const Transform3D &p_transform) const {
	Transform3D xform = p_transform;

	//reflect through the axis that created the copy
	if (mirror_axis != 0) {
		Vector3 flip(1.0, 1.0, 1.0); //Vector3::ONE not available in this godot-cpp version
		flip[mirror_axis - 1] = -1.0;
		xform.basis = Basis::from_scale(flip) * xform.basis;
		xform.origin = xform.origin * flip;
	}

	//optionally take the reflection back out of one axis, keeping the basis right handed
	if (mirror_scaling_fix_axis != 0) {
		xform.basis[mirror_scaling_fix_axis - 1] *= -1.0;
	}

	return xform;
}
void AeroInfluencer3D::update_mirror_transform() {
	if (not _duplicate or not mirror_duplicate) return;

	const Transform3D xform = calculate_mirrored_transform(mirror_duplicate->get_transform());
	set_transform(xform);
	default_transform = xform;
}
void AeroInfluencer3D::map_mirror_sources(AeroInfluencer3D *p_source, AeroInfluencer3D *p_mirror) {
	for (int i = 0; i < p_source->get_child_count(); i++) {
		AeroInfluencer3D *source_child = Object::cast_to<AeroInfluencer3D>(p_source->get_child(i));
		if (not source_child) continue;

		AeroInfluencer3D *mirror_child = Object::cast_to<AeroInfluencer3D>(p_mirror->find_child(String(source_child->get_name()), false, false));
		if (not mirror_child) continue;

		mirror_child->mirror_duplicate = source_child;
		source_child->mirror_duplicate = mirror_child;
		mirror_child->_duplicate = true;
		mirror_child->mirror_axis = 0;
		mirror_child->update_mirror_transform();
		map_mirror_sources(source_child, mirror_child);
	}
}
void AeroInfluencer3D::set_mirror_scaling_fix_axis(int axis) {
	mirror_scaling_fix_axis = axis;

	if (not mirror_duplicate) return;

	if (not _duplicate) {
		mirror_duplicate->set_mirror_scaling_fix_axis(axis);
		return;
	}

	update_mirror_transform();
}
int AeroInfluencer3D::get_mirror_scaling_fix_axis() const {
	return mirror_scaling_fix_axis;
}
void AeroInfluencer3D::set_duplicate(bool value){
	_duplicate = value;
}
bool AeroInfluencer3D::is_duplicate() const {
	return _duplicate;
}
AeroInfluencer3D* AeroInfluencer3D::get_mirror_duplicate() const {
	return mirror_duplicate;
}
void AeroInfluencer3D::set_actuation_config(const Ref<Resource> &p_config) {
	if (actuation_config == p_config) return;

	actuation_config = p_config;

	if (mirror_duplicate) mirror_duplicate->set_actuation_config(p_config);
}
Ref<Resource> AeroInfluencer3D::get_actuation_config() const {
	return actuation_config;
}
void AeroInfluencer3D::set_control_rotation_order(int rotation_order) {
	if (control_rotation_order == rotation_order) return;

	control_rotation_order = rotation_order;

	if (mirror_duplicate) mirror_duplicate->set_control_rotation_order(rotation_order);
}
int AeroInfluencer3D::get_control_rotation_order() const {
	return control_rotation_order;
}
bool AeroInfluencer3D::is_omitted_from_debug() const {
	return omit_from_debug;
}
void AeroInfluencer3D::set_omit_from_debug(bool omit) {
	if (omit_from_debug == omit) return;

	omit_from_debug = omit;

	if (mirror_duplicate) mirror_duplicate->set_omit_from_debug(omit);
}
void AeroInfluencer3D::set_debug_scale(double value) {
	debug_scale = value;

	for (AeroInfluencer3D* influencer : aero_influencers) {
		if (not influencer) continue;
		influencer->set_debug_scale(debug_scale);
	}
}
double AeroInfluencer3D::get_debug_scale() const {
	return debug_scale;
}
void AeroInfluencer3D::set_debug_scaling_factor(double scaling_factor) {
	debug_scaling_factor = scaling_factor;

	for (AeroInfluencer3D* influencer : aero_influencers) {
		if (not influencer) continue;
		influencer->set_debug_scaling_factor(debug_scaling_factor);
	}
}
double AeroInfluencer3D::get_debug_scaling_factor() const {
	return debug_scaling_factor;
}
void AeroInfluencer3D::set_debug_width(double value) {
	debug_width = value;

	if (force_debug_vector) force_debug_vector->set("width", debug_width);
	if (torque_debug_vector) torque_debug_vector->set("width", debug_width);
	if (lift_debug_vector) lift_debug_vector->set("width", debug_width);
	if (drag_debug_vector) drag_debug_vector->set("width", debug_width);
	if (thrust_debug_vector) thrust_debug_vector->set("width", debug_width);

	for (AeroInfluencer3D* influencer : aero_influencers) {
		if (not influencer) continue;
		influencer->set_debug_width(debug_width);
	}
}
double AeroInfluencer3D::get_debug_width() const {
	return debug_width;
}

void destroy_debug_vector(Node3D*& vector) {
	if (vector->get_parent()) vector->get_parent()->remove_child(vector);
	vector->queue_free();
	vector = nullptr;
}

void AeroInfluencer3D::update_debug_visibility() {
	if (show_debug and show_force and not force_debug_vector) force_debug_vector = AeroUtils::create_debug_vector_node("ForceDebug", Color(1.0, 1.0, 1.0), true, debug_width, this);
	if (show_debug and show_torque and not torque_debug_vector) torque_debug_vector = AeroUtils::create_debug_vector_node("TorqueDebug", Color(0.0, 0.0, 0.0), false, debug_width, this);
	if (show_debug and show_lift and not lift_debug_vector) lift_debug_vector = AeroUtils::create_debug_vector_node("LiftDebug", Color(0.0, 0.0, 1.0), false, debug_width, this);
	if (show_debug and show_drag and not drag_debug_vector) drag_debug_vector = AeroUtils::create_debug_vector_node("DragDebug", Color(1.0, 0.0, 0.0), false, debug_width, this);
	if (show_debug and show_thrust and not thrust_debug_vector) thrust_debug_vector = AeroUtils::create_debug_vector_node("ThrustDebug", Color(1.0, 0.0, 1.0), true, debug_width, this);

	if ((not show_debug or not show_force) and force_debug_vector) destroy_debug_vector(force_debug_vector);
	if ((not show_debug or not show_torque) and torque_debug_vector) destroy_debug_vector(torque_debug_vector);
	if ((not show_debug or not show_lift) and lift_debug_vector) destroy_debug_vector(lift_debug_vector);
	if ((not show_debug or not show_drag) and drag_debug_vector) destroy_debug_vector(drag_debug_vector);
	if ((not show_debug or not show_thrust) and thrust_debug_vector) destroy_debug_vector(thrust_debug_vector);

	if (show_debug) update_debug_vectors();

	if (GDVIRTUAL_IS_OVERRIDDEN(update_debug_visibility)) {
		GDVIRTUAL_CALL(update_debug_visibility);
	}
}

//create virtual function for this
void AeroInfluencer3D::set_show_debug(bool value) {
	bool update_visibility = show_debug != value;
	show_debug = value;
	
	if (update_visibility) update_debug_visibility();

	for (AeroInfluencer3D* influencer : aero_influencers) {
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
bool AeroInfluencer3D::get_show_force() const {
	return show_force;
}
void AeroInfluencer3D::set_show_torque(bool show) {
	bool update_visibility = show_torque != show;
	show_torque = show;

	if(update_visibility) update_debug_visibility();
}
bool AeroInfluencer3D::get_show_torque() const {
	return show_torque;
}
void AeroInfluencer3D::set_show_lift(bool show) {
	bool update_visibility = show_lift != show;
	show_lift = show;

	if(update_visibility) update_debug_visibility();
}
bool AeroInfluencer3D::get_show_lift() const {
	return show_lift;
}
void AeroInfluencer3D::set_show_drag(bool show) {
	bool update_visibility = show_drag != show;
	show_drag = show;

	if(update_visibility) update_debug_visibility();
}
bool AeroInfluencer3D::get_show_drag() const {
	return show_drag;
}
void AeroInfluencer3D::set_show_thrust(bool show) {
	bool update_visibility = show_thrust != show;
	show_thrust = show;

	if(update_visibility) update_debug_visibility();
}
bool AeroInfluencer3D::get_show_thrust() const {
	return show_thrust;
}
void AeroInfluencer3D::set_aero_body(AeroBody3D *p_new_body) {
    aero_body = p_new_body;
}
AeroBody3D* AeroInfluencer3D::get_aero_body() const {
	return aero_body;
}
void AeroInfluencer3D::set_aero_influencers(const TypedArray<AeroInfluencer3D> &new_arr) {
	aero_influencers.clear();
	aero_influencers.reserve((size_t) new_arr.size());
	for (int i = 0; i < new_arr.size(); i++) {
		AeroInfluencer3D* influencer = Object::cast_to<AeroInfluencer3D>(new_arr[i]);
		if (influencer) aero_influencers.push_back(influencer);
	}
}
TypedArray<AeroInfluencer3D> AeroInfluencer3D::get_aero_influencers() const {
	TypedArray<AeroInfluencer3D> result;
	result.resize((int) aero_influencers.size());
	for (size_t i = 0; i < aero_influencers.size(); i++) {
		result[(int) i] = aero_influencers[i];
	}
	return result;
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
Vector3 AeroInfluencer3D::get_linear_velocity_substep() const {
	return linear_velocity_substep;
}
Vector3 AeroInfluencer3D::get_angular_velocity_substep() const {
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
Vector3 AeroInfluencer3D::get_centrifugal_offset() {
	if (GDVIRTUAL_IS_OVERRIDDEN(get_centrifugal_offset)) {
		Vector3 result = Vector3();
		GDVIRTUAL_CALL(get_centrifugal_offset, result);
		return result;
	}

	return get_cached_position();
}
Vector3 AeroInfluencer3D::get_linear_acceleration() {
	Vector3 parent_linear_acceleration = Vector3();
	Vector3 parent_angular_acceleration = Vector3();
	double parent_angular_velocity_squared = 0.0;
	Basis parent_basis = Basis();

	if (parent_influencer) {
		parent_linear_acceleration = parent_influencer->get_linear_acceleration();
		parent_angular_acceleration = parent_influencer->get_angular_acceleration();
		parent_basis = parent_influencer->get_cached_global_basis();
	} else if (aero_body) {
		parent_linear_acceleration = aero_body->get_linear_acceleration();
		parent_angular_acceleration = aero_body->get_angular_acceleration();
		parent_angular_velocity_squared = aero_body->get_angular_velocity().length_squared();
		parent_basis = aero_body->get_cached_global_basis();
	} else {
		return Vector3();
	}

	Vector3 centrifugal_offset = parent_basis.xform(get_centrifugal_offset());

	Vector3 axis = angular_velocity_substep.normalized();
	Vector3 nearest_point_on_line = axis * centrifugal_offset.dot(axis.normalized());
	double rotation_radius = nearest_point_on_line.distance_to(centrifugal_offset);
	Vector3 acceleration_axis = nearest_point_on_line - centrifugal_offset;

	double centripetal_acceleration_force = parent_angular_velocity_squared * rotation_radius;
	Vector3 centripetal_acceleration_vector = centripetal_acceleration_force * acceleration_axis;
	

	return parent_linear_acceleration + parent_angular_acceleration.cross(centrifugal_offset) + centripetal_acceleration_vector;
}
Vector3 AeroInfluencer3D::get_angular_acceleration() const {
	Node* parent = get_parent();
	if (AeroInfluencer3D* parent_influencer = Object::cast_to<AeroInfluencer3D>(parent)) return parent_influencer->get_angular_acceleration();
	if (AeroBody3D* parent_body = Object::cast_to<AeroBody3D>(parent)) return parent_body->get_angular_acceleration();
	return Vector3();
}
Vector3 AeroInfluencer3D::get_current_force() const {
	return current_force;
}
Vector3 AeroInfluencer3D::get_current_torque() const {
	return current_torque;
}
