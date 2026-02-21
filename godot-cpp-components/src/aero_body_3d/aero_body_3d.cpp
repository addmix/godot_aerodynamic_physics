#include "aero_body_3d.h"

using namespace godot;

void AeroBody3D::_bind_methods() {
	// substep override
	ClassDB::bind_method(D_METHOD("set_substeps_override", "p_substeps"), &AeroBody3D::set_substeps_override);
	ClassDB::bind_method(D_METHOD("get_substeps_override"), &AeroBody3D::get_substeps_override);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "substeps_override"), "set_substeps_override", "get_substeps_override");

	//function bindings
	ClassDB::bind_method(D_METHOD("add_aero_atmosphere", "p_aero_atmosphere"), &AeroBody3D::add_aero_atmosphere);
	ClassDB::bind_method(D_METHOD("remove_aero_atmosphere", "p_aero_atmosphere"), &AeroBody3D::remove_aero_atmosphere);
	

	//experimental_energy_tracking;

	//debug bindings
	ADD_GROUP("Debug", "");

	ADD_SUBGROUP("Visibility", "");
	//debug visibility
	ClassDB::bind_method(D_METHOD("set_show_debug", "visible"), &AeroBody3D::set_show_debug);
	ClassDB::bind_method(D_METHOD("get_show_debug"), &AeroBody3D::get_show_debug);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "show_debug"), "set_show_debug", "get_show_debug");
	ClassDB::bind_method(D_METHOD("set_update_debug", "update"), &AeroBody3D::set_update_debug);
	ClassDB::bind_method(D_METHOD("get_update_debug"), &AeroBody3D::get_update_debug);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "update_debug"), "set_update_debug", "get_update_debug");
	ClassDB::bind_method(D_METHOD("set_show_wing_debug_vectors", "show"), &AeroBody3D::set_show_wing_debug_vectors);
	ClassDB::bind_method(D_METHOD("get_show_wing_debug_vectors"), &AeroBody3D::get_show_wing_debug_vectors);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "show_wing_debug_vectors"), "set_show_wing_debug_vectors", "get_show_wing_debug_vectors");
	ClassDB::bind_method(D_METHOD("set_show_lift_vectors", "show"), &AeroBody3D::set_show_lift_vectors);
	ClassDB::bind_method(D_METHOD("get_show_lift_vectors"), &AeroBody3D::get_show_lift_vectors);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "show_lift_vectors"), "set_show_lift_vectors", "get_show_lift_vectors");
	ClassDB::bind_method(D_METHOD("set_show_drag_vectors", "show"), &AeroBody3D::set_show_drag_vectors);
	ClassDB::bind_method(D_METHOD("get_show_drag_vectors"), &AeroBody3D::get_show_drag_vectors);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "show_drag_vectors"), "set_show_drag_vectors", "get_show_drag_vectors");
	ClassDB::bind_method(D_METHOD("set_show_linear_velocity", "show"), &AeroBody3D::set_show_linear_velocity);
	ClassDB::bind_method(D_METHOD("get_show_linear_velocity"), &AeroBody3D::get_show_linear_velocity);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "show_linear_velocity"), "set_show_linear_velocity", "get_show_linear_velocity");
	ClassDB::bind_method(D_METHOD("set_show_angular_velocity", "show"), &AeroBody3D::set_show_angular_velocity);
	ClassDB::bind_method(D_METHOD("get_show_angular_velocity"), &AeroBody3D::get_show_angular_velocity);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "show_angular_velocity"), "set_show_angular_velocity", "get_show_angular_velocity");
	ClassDB::bind_method(D_METHOD("set_show_center_of_lift", "show"), &AeroBody3D::set_show_center_of_lift);
	ClassDB::bind_method(D_METHOD("get_show_center_of_lift"), &AeroBody3D::get_show_center_of_lift);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "show_center_of_lift"), "set_show_center_of_lift", "get_show_center_of_lift");
	ClassDB::bind_method(D_METHOD("set_show_center_of_drag", "show"), &AeroBody3D::set_show_center_of_drag);
	ClassDB::bind_method(D_METHOD("get_show_center_of_drag"), &AeroBody3D::get_show_center_of_drag);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "show_center_of_drag"), "set_show_center_of_drag", "get_show_center_of_drag");
	ClassDB::bind_method(D_METHOD("set_show_center_of_mass", "show"), &AeroBody3D::set_show_center_of_mass);
	ClassDB::bind_method(D_METHOD("get_show_center_of_mass"), &AeroBody3D::get_show_center_of_mass);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "show_center_of_mass"), "set_show_center_of_mass", "get_show_center_of_mass");
	ClassDB::bind_method(D_METHOD("set_show_center_of_thrust", "show"), &AeroBody3D::set_show_center_of_thrust);
	ClassDB::bind_method(D_METHOD("get_show_center_of_thrust"), &AeroBody3D::get_show_center_of_thrust);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "show_center_of_thrust"), "set_show_center_of_thrust", "get_show_center_of_thrust");

	ADD_SUBGROUP("Options", "");
	ClassDB::bind_method(D_METHOD("set_debug_linear_velocity", "p_velocity"), &AeroBody3D::set_debug_linear_velocity);
	ClassDB::bind_method(D_METHOD("get_debug_linear_velocity"), &AeroBody3D::get_debug_linear_velocity);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "debug_linear_velocity"), "set_debug_linear_velocity", "get_debug_linear_velocity");
	ClassDB::bind_method(D_METHOD("set_debug_angular_velocity", "p_velocity"), &AeroBody3D::set_debug_angular_velocity);
	ClassDB::bind_method(D_METHOD("get_debug_angular_velocity"), &AeroBody3D::get_debug_angular_velocity);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "debug_angular_velocity"), "set_debug_angular_velocity", "get_debug_angular_velocity");
	ClassDB::bind_method(D_METHOD("set_debug_scale", "p_scale"), &AeroBody3D::set_debug_scale);
	ClassDB::bind_method(D_METHOD("get_debug_scale"), &AeroBody3D::get_debug_scale);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "debug_scale"), "set_debug_scale", "get_debug_scale");
	ClassDB::bind_method(D_METHOD("set_debug_width", "p_width"), &AeroBody3D::set_debug_width);
	ClassDB::bind_method(D_METHOD("get_debug_width"), &AeroBody3D::get_debug_width);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "debug_width"), "set_debug_width", "get_debug_width");
	ClassDB::bind_method(D_METHOD("set_debug_center_width", "p_width"), &AeroBody3D::set_debug_center_width);
	ClassDB::bind_method(D_METHOD("get_debug_center_width"), &AeroBody3D::get_debug_center_width);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "debug_center_width"), "set_debug_center_width", "get_debug_center_width");


	ADD_GROUP("Do not show in inspector", "");
	ADD_SUBGROUP("", "");
	ClassDB::bind_method(D_METHOD("get_substeps"), &AeroBody3D::get_substeps);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "substeps"), "", "get_substeps");
	ClassDB::bind_method(D_METHOD("get_aero_influencers"), &AeroBody3D::get_aero_influencers);
	ClassDB::bind_method(D_METHOD("get_atmosphere_areas"), &AeroBody3D::get_atmosphere_areas);
	
	
	//ADD_PROPERTY(PropertyInfo(Variant::, ""), "", "");
	ClassDB::bind_method(D_METHOD("get_prediction_timestep_fraction"), &AeroBody3D::get_prediction_timestep_fraction);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "prediction_timestep_fraction", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_prediction_timestep_fraction");
	ClassDB::bind_method(D_METHOD("get_current_force"), &AeroBody3D::get_current_force);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "current_force", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_current_force");
	ClassDB::bind_method(D_METHOD("get_current_torque"), &AeroBody3D::get_current_torque);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "current_torque", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_current_torque");
	ClassDB::bind_method(D_METHOD("get_current_gravity"), &AeroBody3D::get_current_gravity);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "current_gravity", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_current_gravity");
	//set_linear_velocity
	ClassDB::bind_method(D_METHOD("get_linear_velocity_substep"), &AeroBody3D::get_linear_velocity_substep);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "linear_velocity_substep", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_linear_velocity_substep");
	//set_angular_velocity
	ClassDB::bind_method(D_METHOD("get_angular_velocity_substep"), &AeroBody3D::get_angular_velocity_substep);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "angular_velocity_substep", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_angular_velocity_substep");
	ClassDB::bind_method(D_METHOD("get_linear_acceleration"), &AeroBody3D::get_linear_acceleration);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "linear_acceleration", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_linear_acceleration");
	//ClassDB::bind_method(D_METHOD("get_angular_acceleration"), &AeroBody3D::get_angular_acceleration);
	//ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "angular_acceleration", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_angular_acceleration");
	ClassDB::bind_method(D_METHOD("get_last_linear_velocity"), &AeroBody3D::get_last_linear_velocity);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "last_linear_velocity", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_last_linear_velocity");
	ClassDB::bind_method(D_METHOD("get_last_angular_velocity"), &AeroBody3D::get_last_angular_velocity);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "last_angular_velocity", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_last_angular_velocity");
	ClassDB::bind_method(D_METHOD("get_wind"), &AeroBody3D::get_wind);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "wind", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_wind");
	ClassDB::bind_method(D_METHOD("get_air_velocity"), &AeroBody3D::get_air_velocity);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "air_velocity", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_air_velocity");
	ClassDB::bind_method(D_METHOD("get_local_air_velocity"), &AeroBody3D::get_local_air_velocity);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "local_air_velocity", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_local_air_velocity");
	ClassDB::bind_method(D_METHOD("get_local_angular_velocity"), &AeroBody3D::get_local_angular_velocity);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "local_angular_velocity", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_local_angular_velocity");
	ClassDB::bind_method(D_METHOD("get_air_speed"), &AeroBody3D::get_air_speed);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "air_speed", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_air_speed");
	ClassDB::bind_method(D_METHOD("get_mach"), &AeroBody3D::get_mach);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "mach", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_mach");
	ClassDB::bind_method(D_METHOD("get_air_density"), &AeroBody3D::get_air_density);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "air_density", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_air_density");
	ClassDB::bind_method(D_METHOD("get_air_pressure"), &AeroBody3D::get_air_pressure);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "air_pressure", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_air_pressure");
	ClassDB::bind_method(D_METHOD("get_angle_of_attack"), &AeroBody3D::get_angle_of_attack);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "angle_of_attack", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_angle_of_attack");
	ClassDB::bind_method(D_METHOD("get_sideslip_angle"), &AeroBody3D::get_sideslip_angle);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "sideslip_angle", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_sideslip_angle");
	ClassDB::bind_method(D_METHOD("get_altitude"), &AeroBody3D::get_altitude);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "altitude", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_altitude");
	ClassDB::bind_method(D_METHOD("get_bank_angle"), &AeroBody3D::get_bank_angle);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "bank_angle", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_bank_angle");
	ClassDB::bind_method(D_METHOD("get_heading"), &AeroBody3D::get_heading);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "heading", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_heading");
	ClassDB::bind_method(D_METHOD("get_inclination"), &AeroBody3D::get_inclination);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "inclination", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "", "get_inclination");
}

AeroBody3D::AeroBody3D() {
	set_linear_damp_mode(DAMP_MODE_REPLACE);
	set_angular_damp_mode(DAMP_MODE_REPLACE);
	set_center_of_mass_mode(CENTER_OF_MASS_MODE_CUSTOM);

	linear_velocity_substep = get_linear_velocity();
	angular_velocity_substep = get_angular_velocity();

	if (not this->is_connected("child_entered_tree", callable_mp(this, &AeroBody3D::on_child_entered_tree))) {
		connect("child_entered_tree", callable_mp(this, &AeroBody3D::on_child_entered_tree));
	}
	if (not this->is_connected("child_exiting_tree", callable_mp(this, &AeroBody3D::on_child_exiting_tree))) {
		connect("child_exiting_tree", callable_mp(this, &AeroBody3D::on_child_exiting_tree));
	}
	

	
	PhysicsServer3D::get_singleton()->body_set_force_integration_callback(get_rid(), callable_mp(this, &AeroBody3D::integrate_forces));

	vector_3d_script = ResourceLoader::get_singleton()->load("res://addons/godot_aerodynamic_physics/utils/vector_3d/vector_3d.gd");
	point_3d_script = ResourceLoader::get_singleton()->load("res://addons/godot_aerodynamic_physics/utils/point_3d/point_3d.gd");
}

AeroBody3D::~AeroBody3D() {
	// Add your cleanup here.
}

void AeroBody3D::_enter_tree() {
	if (Engine::get_singleton()->is_editor_hint()) {
		update_configuration_warnings();
	}
}
void AeroBody3D::on_child_entered_tree(Node *p_node) {
	AeroInfluencer3D* influencer = Object::cast_to<AeroInfluencer3D>(p_node);
	if (!influencer) return;

	aero_influencers.append(influencer);
	influencer->set_aero_body(this);

	influencer->set_show_debug(get_show_debug());
	influencer->set_debug_scale(get_debug_scale());
	influencer->set_debug_width(get_debug_width());
}
void AeroBody3D::on_child_exiting_tree(Node *p_node) {
	AeroInfluencer3D* influencer = Object::cast_to<AeroInfluencer3D>(p_node);
	if (!influencer) return;

	aero_influencers.erase(influencer);
	influencer->set_aero_body(nullptr);
}
void AeroBody3D::_ready() {
	set_substeps(get_substeps());
	set_show_debug(show_debug);
	set_collision_layer_value(ProjectSettings::get_singleton()->get_setting("physics/aerodynamics/atmosphere_area_collision_layer", 15), true);

	if (Engine::get_singleton()->is_editor_hint()) {
		update_configuration_warnings();
	}
}

/*
//PackedStringArray AeroBody3D::_get_configuration_warnings() const {}
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray([])
	var default_linear_damp : float = ProjectSettings.get_setting("physics/3d/default_linear_damp", 0.0)
	if linear_damp_mode == DAMP_MODE_COMBINE:
		if default_linear_damp + linear_damp > 0.0:
			warnings.append("Linear damping is greater than 0. Unexpected aerodynamic characteristics will be present.")
	else:
		if linear_damp > 0.0:
			warnings.append("Linear damping is greater than 0. Unexpected aerodynamic characteristics will be present.")

	var default_angular_damp : float = ProjectSettings.get_setting("physics/3d/default_angular_damp", 0.0)
	if angular_damp_mode == DAMP_MODE_COMBINE:
		if default_angular_damp + angular_damp > 0.0:
			warnings.append("Angular damping is greater than 0. Unexpected aerodynamic characteristics will be present.")
	else:
		if angular_damp > 0.0:
			warnings.append("Angular damping is greater than 0. Unexpected aerodynamic characteristics will be present.")
	
	return warnings
*/

void AeroBody3D::_physics_process(double delta) {
	if (show_debug and update_debug) {
		_update_debug();
	}	
}

// I'd bet that there's a more performant way to implement this.
// integrate_forces is single-threaded, however I believe that RigidBody has an internal 
// physics update routine that is parallelized.
void AeroBody3D::integrate_forces(PhysicsDirectBodyState3D *body_state) {
	if (is_overriding_body_sleep()) {
		interrupt_sleep();
	}
	
	if (body_state->is_sleeping() or substeps == 0) return;

	last_linear_velocity = uncommitted_last_linear_velocity;
	last_angular_velocity = uncommitted_last_angular_velocity;

	current_gravity = body_state->get_total_gravity();

	//this probably doesn't need to run every frame
	if (not Engine::get_singleton()->is_editor_hint()) {
		set_center_of_mass(body_state->get_center_of_mass());
	}

	linear_velocity_substep = body_state->get_linear_velocity();
	angular_velocity_substep = body_state->get_angular_velocity();

	ForceAndTorque total_force_and_torque = calculate_forces(body_state->get_step());

	body_state->apply_central_force(total_force_and_torque.force);
	body_state->apply_torque(total_force_and_torque.torque);

	//TODO - should this be done every substep?
	linear_acceleration = (body_state->get_linear_velocity() - last_linear_velocity) / body_state->get_step();
	angular_acceleration = (body_state->get_angular_velocity() - last_angular_velocity) / body_state->get_step();
	
	uncommitted_last_linear_velocity = body_state->get_linear_velocity();
	uncommitted_last_angular_velocity = body_state->get_angular_velocity();
}

ForceAndTorque AeroBody3D::calculate_forces(double delta) {
	//this is necessary to prevent velocity accumulation with debug in the editor
	if (Engine::get_singleton()->is_editor_hint()) {
		linear_velocity_substep = get_linear_velocity();
		angular_velocity_substep = get_angular_velocity();
	}

	altitude = AeroUnits::get_singleton()->get_altitude(this);
	mach = AeroUnits::get_singleton()->speed_to_mach_at_altitude(air_speed, altitude);
	air_density = AeroUnits::get_singleton()->get_density_at_altitude(altitude);
	air_pressure = AeroUnits::get_singleton()->get_pressure_at_altitude(altitude);
	
	wind = Vector3();
	for (int i = 0; i < atmosphere_areas.size(); i++) {
		Area3D* atmosphere = Object::cast_to<Area3D>(atmosphere_areas[i]);
		if (not atmosphere) continue;
		if (atmosphere->get("per_influencer_positioning")) continue;

		Variant wind_result = atmosphere->call("get_wind_at_position", get_global_position());
		
		wind += (Vector3) wind_result;
		if (atmosphere->get("override_density")) {
			air_density = atmosphere->call("get_density_at_position", get_global_position());
		}
	}
	
	bank_angle = get_rotation().z;
	heading = get_rotation().y;
	inclination = get_rotation().x;

	
	ForceAndTorque last_force_and_torque;
	ForceAndTorque total_force_and_torque;

	substep_delta = delta * prediction_timestep_fraction;
	for (int substep = 0; substep < substeps; substep++) {
		current_substep = substep;
		
		air_velocity = -get_linear_velocity_substep() + wind;
		air_speed = air_velocity.length();

		local_air_velocity = get_global_transform().get_basis().xform_inv(air_velocity);
		local_angular_velocity = get_global_transform().get_basis().xform_inv(angular_velocity_substep);
		angle_of_attack = get_global_basis().get_column(1).angle_to(-air_velocity) - (Math_PI / 2.0);
		sideslip_angle = get_global_basis().get_column(0).angle_to(air_velocity) - (Math_PI / 2.0);
		relative_position = calculate_relative_position();
		drag_direction = calculate_drag_direction();

		_update_transform_substep(substep_delta);

		ForceAndTorque substep_force_and_torque_sum;
		for (int i = 0; i < aero_influencers.size(); i++) {
			AeroInfluencer3D* influencer = Object::cast_to<AeroInfluencer3D>(aero_influencers[i]);
			if (not influencer) continue;
			if (influencer->is_disabled()) continue;

			ForceAndTorque force_and_torque = influencer->calculate_forces_with_override(substep_delta);
			
			substep_force_and_torque_sum += force_and_torque;
		}

		total_force_and_torque += substep_force_and_torque_sum;
		last_force_and_torque = substep_force_and_torque_sum;

		linear_velocity_substep = calculate_linear_velocity_substep(last_force_and_torque.force) + current_gravity * substep_delta;
		angular_velocity_substep = calculate_angular_velocity_substep(last_force_and_torque.torque);

	}

	total_force_and_torque /= substeps;

	current_force = total_force_and_torque.force;
	current_torque = total_force_and_torque.torque;

	/*
	#other features needed for energy tracking to work:
	#- separate thrust(energy creation) and drag(energy loss) from regular forces
	#- possibly
	if experimental_energy_tracking:
		#linear inertia calcs
		var pre_kinetic_energy : float = 0.5 * mass * linear_velocity.length_squared()
		var velocity_change : Vector3 = (current_force * delta) / mass
		var velocity_change_length : float = velocity_change.length()
		var post_kinetic_energy : float = 0.5 * mass * (linear_velocity + velocity_change).length_squared()
		
		#angular inertia calcs
		var real_inertia : Basis = get_inverse_inertia_tensor().inverse()
		var inertia_around_angular_velocity_axis : float = (real_inertia * angular_velocity.normalized()).dot(angular_velocity.normalized())
		var pre_rotational_kinetic_energy : float = 0.5 * inertia_around_angular_velocity_axis * angular_velocity.length_squared()
		var angular_velocity_change : Vector3 = get_inverse_inertia_tensor() * (current_torque * delta)
		var angular_velocity_change_length : float = angular_velocity_change.length()
		var post_rotational_kinetic_energy : float = 0.5 * inertia_around_angular_velocity_axis * (angular_velocity + angular_velocity_change).length_squared()
		
		#kinetic energy is clamped, to avoid integration errors when forces are too high.
		var clamped_kinetic_energy : float = clamp(post_kinetic_energy + post_rotational_kinetic_energy, 0, pre_kinetic_energy + pre_rotational_kinetic_energy)
		
		#calculate the proportion of energy between linear and angular, which will
		#be needed to convert the total clamped energy back into velocities
		var angular_energy_proportion : float = post_rotational_kinetic_energy / (post_kinetic_energy + post_rotational_kinetic_energy)
		
		
		#depending on the difference between the original post_kinetic_energy and pre_kinetic_energy
		#use a lerp on this (linear_velocity + velocity_change).normalized() term so that the resulting
		#vector is pointing in the correct direction
		var linear_energy : float = clamped_kinetic_energy * (1.0 - angular_energy_proportion)
		var velocity : Vector3 = (linear_velocity + velocity_change).normalized() * sqrt(linear_energy / (0.5 * mass))
		velocity_change = (velocity - linear_velocity)#.limit_length(velocity_change_length)
		
		velocity_change *= mass
		velocity_change /= delta
		total_force_and_torque[0] = velocity_change
		current_force = total_force_and_torque[0]
		
		#this angular energy section might not be working perfectly.
		var angular_energy : float = clamped_kinetic_energy * angular_energy_proportion
		#this inertia term might need to be changed, cuz calculating the inertia around the (angular_velocity + angular_velocity_change) axis might be more correct.
		var new_angular_velocity : Vector3 = Vector3.ZERO
		if not inertia_around_angular_velocity_axis == 0.0:
			new_angular_velocity = (angular_velocity + angular_velocity_change).normalized() * sqrt(angular_energy / (0.5 * inertia_around_angular_velocity_axis))
		
		angular_velocity_change = (new_angular_velocity - angular_velocity)#.limit_length(angular_velocity_change_length)
		#same here, might need to use a different inertia axis
		angular_velocity_change *= inertia_around_angular_velocity_axis
		angular_velocity_change /= delta
		total_force_and_torque[1] = angular_velocity_change
		current_torque = total_force_and_torque[1]
	*/

	return total_force_and_torque;
}
void AeroBody3D::_update_transform_substep(double substep_delta) {
	if (not Engine::get_singleton()->is_editor_hint()) {
		for (int i = 0; i < aero_influencers.size(); i++) {
			AeroInfluencer3D* influencer = Object::cast_to<AeroInfluencer3D>(aero_influencers[i]);
			if (not influencer) continue;
			if (influencer->is_disabled()) continue;

			influencer->_update_transform_substep(substep_delta);
		}
	}
}

Vector3 AeroBody3D::calculate_linear_velocity_substep(const Vector3 force) const { return linear_velocity_substep + (force / get_mass() * substep_delta); }
Vector3 AeroBody3D::calculate_angular_velocity_substep(const Vector3 torque) const { return angular_velocity_substep + (get_inverse_inertia_tensor().xform(torque) * substep_delta); }
Vector3 AeroBody3D::calculate_relative_position() const { return get_global_basis().xform(-get_center_of_mass()); }
Vector3 AeroBody3D::calculate_drag_direction() const { return air_velocity.normalized(); }
//Vector3 AeroBody3D::calculate_linear_acceleration() const {
//	return (linear_velocity_substep - last_linear_velocity) / substep_delta;
//}
//Vector3 AeroBody3D::calculate_angular_acceleration() const {
//	return (angular_velocity_substep - last_angular_velocity) / substep_delta;
//}



double AeroBody3D::get_control_command(StringName axis_name) {
	Node* control_component = get_node_or_null("AeroControlComponent"); //wrong, bad, need to implement AeroNodeUtils.get_first_child_of_type()
	if (not control_component) return 0.0;
	
	Variant result = control_component->call("get_control_command", axis_name);
	return (double) result;
}
bool AeroBody3D::is_overriding_body_sleep() const {
	bool overriding = false;

	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = Object::cast_to<AeroInfluencer3D>(aero_influencers[i]);
		if (not influencer) continue;
		if (influencer->is_disabled()) continue;

		overriding = overriding or influencer->is_overriding_body_sleep();
	}

	return overriding;
}

void AeroBody3D::interrupt_sleep() {
	set_sleeping(false);
}

TypedArray<AeroInfluencer3D> AeroBody3D::get_aero_influencers() const { return aero_influencers; }
TypedArray<Area3D> AeroBody3D::get_atmosphere_areas() const { return atmosphere_areas; }

void AeroBody3D::add_aero_atmosphere(const Area3D* atmosphere) { atmosphere_areas.append(atmosphere); }
void AeroBody3D::remove_aero_atmosphere(const Area3D* atmosphere) { atmosphere_areas.erase(atmosphere); }

void AeroBody3D::set_substeps_override(const int p_substeps) {substeps_override = p_substeps;}
int AeroBody3D::get_substeps_override() const {return substeps_override;}
void AeroBody3D::set_substeps(const int p_substeps) {
	substeps = p_substeps;
	prediction_timestep_fraction = 1.0 / (double) substeps;
}
int AeroBody3D::get_substeps() const {
	if (substeps_override > -1){
		return substeps_override;
	}
	
	return (int) ProjectSettings::get_singleton()->get_setting("physics/3d/aerodynamics/substeps", 1);
}
double AeroBody3D::get_prediction_timestep_fraction() const {return prediction_timestep_fraction;}
double AeroBody3D::get_substep_delta() const { return substep_delta; }
int AeroBody3D::get_current_substep() const { return current_substep; }



int AeroBody3D::get_amount_of_active_influencers() const {
	int count = 0;
	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = Object::cast_to<AeroInfluencer3D>(aero_influencers[i]);
		if (not influencer) continue;
		if (not influencer->is_disabled()) count += 1;
	}

	return count;
}
Vector3 AeroBody3D::get_relative_position() const { return relative_position; }
Vector3 AeroBody3D::get_drag_direction() const { return drag_direction; }
Vector3 AeroBody3D::get_linear_velocity_substep() const { return linear_velocity_substep; }
Vector3 AeroBody3D::get_angular_velocity_substep() const { return angular_velocity_substep; }
Vector3 AeroBody3D::get_linear_acceleration() const {return linear_acceleration;}
//Vector3 AeroBody3D::get_angular_acceleration() const {return angular_acceleration;}
Vector3 AeroBody3D::get_current_force() const {return current_force;}
Vector3 AeroBody3D::get_current_torque() const {return current_torque;}
Vector3 AeroBody3D::get_current_gravity() const {return current_gravity;}
Vector3 AeroBody3D::get_last_linear_velocity() const {return last_linear_velocity;}
Vector3 AeroBody3D::get_last_angular_velocity() const {return last_angular_velocity;}
Vector3 AeroBody3D::get_wind() const {return wind;}
Vector3 AeroBody3D::get_air_velocity() const {return air_velocity;}
Vector3 AeroBody3D::get_local_air_velocity() const {return local_air_velocity;}
Vector3 AeroBody3D::get_local_angular_velocity() const {return local_angular_velocity;}
double AeroBody3D::get_air_speed() const {return air_speed;}
double AeroBody3D::get_mach() const {return mach;}
double AeroBody3D::get_air_density() const {return air_density;}
double AeroBody3D::get_air_pressure() const {return air_pressure;}
double AeroBody3D::get_angle_of_attack() const {return angle_of_attack;}
double AeroBody3D::get_sideslip_angle() const {return sideslip_angle;}
double AeroBody3D::get_altitude() const {return altitude;}
double AeroBody3D::get_bank_angle() const {return bank_angle;}
double AeroBody3D::get_heading() const {return heading;}
double AeroBody3D::get_inclination() const {return inclination;}










// Debug vector section






//debug
void AeroBody3D::_update_debug() {
	//TODO - implement the rest of the debug vectors

	//_update_debug_visibility()
	//_update_debug_scale()
	//
	//mass_debug_point.position = center_of_mass

	/*
	aero_surfaces = []
	for i : AeroInfluencer3D in aero_influencers:
		if i is AeroSurface3D:
			aero_surfaces.append(i)
	*/
	
	Vector3 linear_velocity_to_use = get_linear_velocity();
	Vector3 angular_velocity_to_use = get_angular_velocity();
	
	if (Engine::get_singleton()->is_editor_hint()) {
		linear_velocity_to_use = debug_linear_velocity;
		angular_velocity_to_use = debug_angular_velocity;

		//Godot doesn't run physics engine in-editor.
		//A consequence of this is that get_linear_velocity doesn't work.
		//Instead, we must access linear_velocity directly.
		//We don't want to overwrite user configured linear velocity, so we must use this workaround.
		
		//Vector3 original_linear_velocity = RigidBody3D::get_linear_velocity();
		//Vector3 original_angular_velocity = RigidBody3D::get_angular_velocity();
		//RigidBody3D::set_linear_velocity(debug_linear_velocity);
		//RigidBody3D::set_angular_velocity(debug_angular_velocity);
		//substep_delta = 1.0 / float(ProjectSettings.get_setting("physics/common/physics_ticks_per_second")) / SUBSTEPS
		//TODO
		//ForceAndTorque last_force_and_torque = calculate_aerodynamic_forces(get_physics_process_delta_time());
		
		//RigidBody3D::set_linear_velocity(original_linear_velocity);
		//RigidBody3D::set_angular_velocity(original_angular_velocity);

		
	}
	



	
	//OLD DEBUG IMPLEMENTATION
	if (mass_debug_point) {
		mass_debug_point->set_position(get_center_of_mass());
	}
	if (linear_velocity_vector) {
		linear_velocity_vector->set("value", get_global_basis().xform_inv(linear_velocity_to_use) * debug_scale);
	}
	if (angular_velocity_vector) {
		angular_velocity_vector->set_deferred("value", get_global_basis().xform_inv(angular_velocity_to_use) * debug_scale);
	}
	//thrust_debug_vector.position = center of thrust
	

	int amount_of_aero_influencers = aero_influencers.size();
	double force_sum = 0.0;
	Vector3 force_vector_sum = Vector3();
	
	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = Object::cast_to<AeroInfluencer3D>(aero_influencers[i]);
		if (not influencer) continue;

		if (influencer->is_omitted_from_debug() or influencer->is_disabled()) {
			amount_of_aero_influencers -= 1;
			continue;
		}
			
		force_vector_sum += influencer->get_current_force();
	}
	
	/*
	#lift and drag debug
	var amount_of_aero_surfaces : int = aero_surfaces.size()
	for surface : AeroSurface3D in aero_surfaces:
		if surface.omit_from_debug or surface.disabled:
			amount_of_aero_surfaces -= 1
	
	if amount_of_aero_surfaces > 0:
		var lift_sum := 0.0
		var lift_sum_vector := Vector3.ZERO
		var drag_sum := 0.0
		var drag_sum_vector := Vector3.ZERO
		var lift_position_sum := Vector3.ZERO
		var drag_position_sum := Vector3.ZERO
		for surface : AeroSurface3D in aero_surfaces:
			if surface.omit_from_debug:
				continue
			
			lift_sum += surface.lift_force
			lift_sum_vector += surface._current_lift
			drag_sum += surface.drag_force
			drag_sum_vector += surface._current_drag
			lift_position_sum += surface.transform.origin * surface.lift_force
			drag_position_sum += surface.transform.origin * surface.drag_force
		
		if lift_sum_vector.is_finite() and drag_sum_vector.is_finite():
			lift_debug_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(lift_sum_vector / amount_of_aero_surfaces, 2.0)
			drag_debug_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(drag_sum_vector / amount_of_aero_surfaces, 2.0)
			
			if is_equal_approx(lift_sum, 0.0):
				lift_sum = 1.0
			lift_debug_vector.position = lift_position_sum / amount_of_aero_surfaces / (lift_sum / amount_of_aero_surfaces) 
			if is_equal_approx(drag_sum, 0.0):
				drag_sum = 1.0
			drag_debug_vector.position = drag_position_sum / amount_of_aero_surfaces / (drag_sum / amount_of_aero_surfaces)
		*/

	/*
	NEW DEBUG IMPLEMENTATION
	force_debug_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(current_force, 2.0)
	torque_debug_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(current_torque, 2.0)
	
	linear_velocity_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(linear_velocity_to_use, 2.0)
	angular_velocity_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(angular_velocity_to_use, 2.0)
	
	#force and torque debug
	if aero_influencers.size() > 0:
		var get_aero_influencer_array : Callable = func x(influencer)-> Array[AeroInfluencer3D]:
			var influencers : Array[AeroInfluencer3D] = influencer.aero_influencers.duplicate()
			for _influencer : AeroInfluencer3D in influencer.aero_influencers:
				influencers.append_array(_influencer.aero_influencers)
			return influencers
		
		var recursive_aero_influencers : Array[AeroInfluencer3D] = get_aero_influencer_array.call(self)
		var amount_of_aero_influencers : int = recursive_aero_influencers.size()
		var force_sum := 0.0
		var force_vector_sum := Vector3.ZERO
		var force_position_sum := Vector3.ZERO
		var lift_sum := 0.0
		var lift_vector_sum := Vector3.ZERO
		var lift_position_sum := Vector3.ZERO
		var drag_sum := 0.0
		var drag_vector_sum := Vector3.ZERO
		var drag_position_sum := Vector3.ZERO
		var thrust_sum := 0.0
		var thrust_vector_sum := Vector3.ZERO
		var thrust_position_sum := Vector3.ZERO
		
		
		#this is flawed, it needs to be recursive, and use the current influencer's force instead of it's force sum of child influencers
		
		
		
		for influencer : AeroInfluencer3D in recursive_aero_influencers:
			#skip omitted or disabled influencers, and don't add them to the debug vectors
			if influencer.omit_from_debug or influencer.disabled:
				amount_of_aero_influencers -= 1
				continue
			
			var force_vector := influencer._current_force
			var force := force_vector.length()
			force_sum += force
			force_vector_sum += force_vector
			force_position_sum += influencer.relative_position * force
			
			var drag_vector : Vector3 = max(force_vector.dot(get_drag_direction()), 0.0) * get_drag_direction()
			var drag := drag_vector.length()
			drag_sum += drag
			drag_vector_sum += drag_vector
			drag_position_sum += influencer.relative_position * drag
			
			var lift_vector := force_vector - force_vector.dot(get_drag_direction()) * get_drag_direction()
			var lift := lift_vector.length()
			lift_sum += lift
			lift_vector_sum += lift_vector
			lift_position_sum += influencer.relative_position * lift
			
			var thrust_vector : Vector3 = min(force_vector.dot(get_drag_direction()), 0.0) * get_drag_direction()
			var thrust := thrust_vector.length()
			thrust_sum += thrust
			thrust_vector_sum += thrust_vector
			thrust_position_sum += influencer.relative_position * thrust
		
		force_debug_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(force_vector_sum, debug_scaling_factor) * debug_scale
		if not is_equal_approx(force_sum, 0.0):
			force_debug_vector.position = global_transform.basis.inverse() * (force_position_sum / force_sum)
		drag_debug_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(drag_vector_sum, debug_scaling_factor) * debug_scale
		if not is_equal_approx(drag_sum, 0.0):
			drag_debug_vector.position = global_transform.basis.inverse() * (drag_position_sum / drag_sum)
		lift_debug_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(lift_vector_sum, debug_scaling_factor) * debug_scale
		if not is_equal_approx(lift_sum, 0.0):
			lift_debug_vector.position = global_transform.basis.inverse() * (lift_position_sum / lift_sum)
		thrust_debug_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(thrust_vector_sum, debug_scaling_factor) * debug_scale
		if not is_equal_approx(thrust_sum, 0.0):
			thrust_debug_vector.position = global_transform.basis.inverse() * (thrust_position_sum / thrust_sum)
	
	*/
	for (int x = 0; x < aero_influencers.size(); x++) {
		AeroInfluencer3D* influencer = (AeroInfluencer3D*) (Object*) aero_influencers[x];
		influencer->update_debug();
	}
}

//debug visibility
void AeroBody3D::set_show_debug(const bool value) {
	//TODO - implement the rest of the debug vectors
	
	show_debug = value;
	
	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = Object::cast_to<AeroInfluencer3D>(aero_influencers[i]);
		if (not influencer) continue;
		influencer->set_show_debug(show_debug);
	}
	
	if (show_debug) {

		if (not mass_debug_point) {
			mass_debug_point = memnew(MeshInstance3D);
			mass_debug_point->set_script(point_3d_script);
			mass_debug_point->set_name("CenterOfMassDebug");

			mass_debug_point->set("width", debug_center_width);
			mass_debug_point->set("color", Color(1.0, 1.0, 0.0));
			mass_debug_point->set("checker", true);
			add_child(mass_debug_point, INTERNAL_MODE_FRONT);
		}
		if (not linear_velocity_vector) {
			linear_velocity_vector = memnew(MeshInstance3D);
			linear_velocity_vector->set_script(vector_3d_script);
			linear_velocity_vector->set_name("LinearVelocityDebug");

			linear_velocity_vector->set("width", debug_width);
			linear_velocity_vector->set("color", Color(0, 0.5, 0.5));
			add_child(linear_velocity_vector, INTERNAL_MODE_FRONT);
		}
		if (not angular_velocity_vector) {
			angular_velocity_vector = memnew(MeshInstance3D);
			angular_velocity_vector->set_script(vector_3d_script);
			
			angular_velocity_vector->set_visible(false); //angular velocity vector isn't very useful, so it's hidden for my sanity
			angular_velocity_vector->set("width", debug_width);
			angular_velocity_vector->set("color", Color(0, 0.333, 0));
			add_child(angular_velocity_vector, INTERNAL_MODE_FRONT);
		}
		
		_update_debug();
	} else {
		if (mass_debug_point != nullptr) {
			mass_debug_point->queue_free();
			mass_debug_point = nullptr;
		}
		if (linear_velocity_vector != nullptr) {
			linear_velocity_vector->queue_free();
			linear_velocity_vector = nullptr;
		}
		if (angular_velocity_vector != nullptr) {
			angular_velocity_vector->queue_free();
			angular_velocity_vector = nullptr;
		}
		
	}

	/*
	#update aerosurface visibility
	
	for influencer : AeroInfluencer3D in aero_influencers:
		influencer.update_debug_visibility(show_debug and show_wing_debug_vectors)
	
	#update self visibility
	force_debug_vector.visible = show_debug
	torque_debug_vector.visible = show_debug and show_torque
	
	linear_velocity_vector.visible = show_debug and show_linear_velocity
	angular_velocity_vector.visible = show_debug and show_angular_velocity

	lift_debug_vector.visible = show_debug and show_center_of_lift
	drag_debug_vector.visible = show_debug and show_center_of_drag

	mass_debug_point.visible = show_debug and show_center_of_mass
	thrust_debug_vector.visible = show_debug and show_center_of_thrust
	*/
}
bool AeroBody3D::get_show_debug() const {return show_debug;}


void AeroBody3D::set_update_debug(const bool value) {update_debug = value;}
bool AeroBody3D::get_update_debug() const {return update_debug;}

void AeroBody3D::set_show_wing_debug_vectors(const bool value) {show_wing_debug_vectors = value;}
bool AeroBody3D::get_show_wing_debug_vectors() const {return show_wing_debug_vectors;}

void AeroBody3D::set_show_lift_vectors(const bool value) {show_lift = value;}
bool AeroBody3D::get_show_lift_vectors() const {return show_lift;}

void AeroBody3D::set_show_drag_vectors(const bool value) {show_drag = value;}
bool AeroBody3D::get_show_drag_vectors() const {return show_drag;}

void AeroBody3D::set_show_linear_velocity(const bool value) {show_linear_velocity = value;}
bool AeroBody3D::get_show_linear_velocity() const {return show_linear_velocity;}

void AeroBody3D::set_show_angular_velocity(const bool value) {show_angular_velocity = value;}
bool AeroBody3D::get_show_angular_velocity() const {return show_angular_velocity;}

void AeroBody3D::set_show_center_of_lift(const bool value) {show_center_of_lift = value;}
bool AeroBody3D::get_show_center_of_lift() const {return show_center_of_lift;}

void AeroBody3D::set_show_center_of_drag(const bool value) {show_center_of_drag = value;}
bool AeroBody3D::get_show_center_of_drag() const {return show_center_of_drag;}

void AeroBody3D::set_show_center_of_mass(const bool value) {show_center_of_mass = value;}
bool AeroBody3D::get_show_center_of_mass() const {return show_center_of_mass;}

void AeroBody3D::set_show_center_of_thrust(const bool value) {show_center_of_thrust = value;}
bool AeroBody3D::get_show_center_of_thrust() const {return show_center_of_thrust;}

//debug options
void AeroBody3D::set_debug_linear_velocity(const Vector3 value) {debug_linear_velocity = value;}
Vector3 AeroBody3D::get_debug_linear_velocity() const {return debug_linear_velocity;}

void AeroBody3D::set_debug_angular_velocity(const Vector3 value) {debug_angular_velocity = value;}
Vector3 AeroBody3D::get_debug_angular_velocity() const {return debug_angular_velocity;}

void AeroBody3D::set_debug_scale(const double value) {
	debug_scale = value;
	//TODO
	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = Object::cast_to<AeroInfluencer3D>(aero_influencers[i]);
		if (not influencer) continue;
		influencer->set_debug_scale(debug_scale);
	}
}
double AeroBody3D::get_debug_scale() const {return debug_scale;}

void AeroBody3D::set_debug_width(const double value) {
	debug_width = value;
	//TODO
	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = Object::cast_to<AeroInfluencer3D>(aero_influencers[i]);
		if (not influencer) continue;
		influencer->set_debug_width(debug_width);
	}

	if (show_debug) {
		mass_debug_point->set("width", debug_center_width);
		linear_velocity_vector->set("width", debug_width);
		angular_velocity_vector->set("width", debug_width);
	}
}
double AeroBody3D::get_debug_width() const {return debug_width;}

void AeroBody3D::set_debug_center_width(const double value) {
	debug_center_width = value;
	//TODO
}
double AeroBody3D::get_debug_center_width() const {return debug_center_width;}
