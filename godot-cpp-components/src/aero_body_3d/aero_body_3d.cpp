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
	ClassDB::bind_method(D_METHOD("set_show_torque", "show"), &AeroBody3D::set_show_torque);
	ClassDB::bind_method(D_METHOD("get_show_torque"), &AeroBody3D::get_show_torque);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "show_torque"), "set_show_torque", "get_show_torque");
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
	ClassDB::bind_method(D_METHOD("set_debug_scaling_factor", "p_factor"), &AeroBody3D::set_debug_scaling_factor);
	ClassDB::bind_method(D_METHOD("get_debug_scaling_factor"), &AeroBody3D::get_debug_scaling_factor);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "debug_scaling_factor"), "set_debug_scaling_factor", "get_debug_scaling_factor");
	ClassDB::bind_method(D_METHOD("set_influencer_debug_width", "p_width"), &AeroBody3D::set_influencer_debug_width);
	ClassDB::bind_method(D_METHOD("get_influencer_debug_width"), &AeroBody3D::get_influencer_debug_width);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "influencer_debug_width"), "set_influencer_debug_width", "get_influencer_debug_width");
	ClassDB::bind_method(D_METHOD("set_debug_center_width", "p_width"), &AeroBody3D::set_debug_center_width);
	ClassDB::bind_method(D_METHOD("get_debug_center_width"), &AeroBody3D::get_debug_center_width);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "debug_center_width"), "set_debug_center_width", "get_debug_center_width");


	ClassDB::bind_method(D_METHOD("get_amount_of_active_influencers"), &AeroBody3D::get_amount_of_active_influencers);
	ClassDB::bind_method(D_METHOD("get_control_command", "axis_name"), &AeroBody3D::get_control_command);
	ClassDB::bind_method(D_METHOD("get_relative_position"), &AeroBody3D::get_relative_position);
	ClassDB::bind_method(D_METHOD("get_drag_direction"), &AeroBody3D::get_drag_direction);
	ClassDB::bind_method(D_METHOD("interrupt_sleep"), &AeroBody3D::interrupt_sleep);

	//don't show these in inspector
	ADD_GROUP("", "");
	ADD_SUBGROUP("", "");
	ClassDB::bind_method(D_METHOD("get_substeps"), &AeroBody3D::get_substeps);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "substeps", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_substeps");
	ClassDB::bind_method(D_METHOD("get_current_substep"), &AeroBody3D::get_current_substep);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "current_substep", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_current_substep");
	ClassDB::bind_method(D_METHOD("get_aero_influencers"), &AeroBody3D::get_aero_influencers);
	ClassDB::bind_method(D_METHOD("get_atmosphere_areas"), &AeroBody3D::get_atmosphere_areas);
	ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "atmosphere_areas", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_atmosphere_areas");
	
	
	//ADD_PROPERTY(PropertyInfo(Variant::, ""), "", "");
	ClassDB::bind_method(D_METHOD("get_prediction_timestep_fraction"), &AeroBody3D::get_prediction_timestep_fraction);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "prediction_timestep_fraction", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_prediction_timestep_fraction");
	ClassDB::bind_method(D_METHOD("get_current_force"), &AeroBody3D::get_current_force);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "current_force", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_current_force");
	ClassDB::bind_method(D_METHOD("get_current_torque"), &AeroBody3D::get_current_torque);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "current_torque", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_current_torque");
	ClassDB::bind_method(D_METHOD("get_current_gravity"), &AeroBody3D::get_current_gravity);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "current_gravity", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_current_gravity");
	//set_linear_velocity
	ClassDB::bind_method(D_METHOD("get_linear_velocity_substep"), &AeroBody3D::get_linear_velocity_substep);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "linear_velocity_substep", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_linear_velocity_substep");
	//set_angular_velocity
	ClassDB::bind_method(D_METHOD("get_angular_velocity_substep"), &AeroBody3D::get_angular_velocity_substep);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "angular_velocity_substep", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_angular_velocity_substep");
	ClassDB::bind_method(D_METHOD("get_linear_acceleration"), &AeroBody3D::get_linear_acceleration);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "linear_acceleration", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_linear_acceleration");
	ClassDB::bind_method(D_METHOD("get_angular_acceleration"), &AeroBody3D::get_angular_acceleration);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "angular_acceleration", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_angular_acceleration");
	ClassDB::bind_method(D_METHOD("get_last_linear_velocity"), &AeroBody3D::get_last_linear_velocity);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "last_linear_velocity", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_last_linear_velocity");
	ClassDB::bind_method(D_METHOD("get_last_angular_velocity"), &AeroBody3D::get_last_angular_velocity);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "last_angular_velocity", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_last_angular_velocity");
	ClassDB::bind_method(D_METHOD("get_wind"), &AeroBody3D::get_wind);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "wind", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_wind");
	ClassDB::bind_method(D_METHOD("get_air_velocity"), &AeroBody3D::get_air_velocity);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "air_velocity", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_air_velocity");
	ClassDB::bind_method(D_METHOD("get_local_air_velocity"), &AeroBody3D::get_local_air_velocity);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "local_air_velocity", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_local_air_velocity");
	ClassDB::bind_method(D_METHOD("get_local_angular_velocity"), &AeroBody3D::get_local_angular_velocity);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "local_angular_velocity", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_local_angular_velocity");
	ClassDB::bind_method(D_METHOD("get_air_speed"), &AeroBody3D::get_air_speed);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "air_speed", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_air_speed");
	ClassDB::bind_method(D_METHOD("get_mach"), &AeroBody3D::get_mach);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "mach", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_mach");
	ClassDB::bind_method(D_METHOD("get_air_density"), &AeroBody3D::get_air_density);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "air_density", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_air_density");
	ClassDB::bind_method(D_METHOD("get_air_pressure"), &AeroBody3D::get_air_pressure);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "air_pressure", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_air_pressure");
	ClassDB::bind_method(D_METHOD("get_angle_of_attack"), &AeroBody3D::get_angle_of_attack);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "angle_of_attack", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_angle_of_attack");
	ClassDB::bind_method(D_METHOD("get_sideslip_angle"), &AeroBody3D::get_sideslip_angle);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "sideslip_angle", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_sideslip_angle");
	ClassDB::bind_method(D_METHOD("get_altitude"), &AeroBody3D::get_altitude);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "altitude", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_altitude");
	ClassDB::bind_method(D_METHOD("get_bank_angle"), &AeroBody3D::get_bank_angle);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "bank_angle", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_bank_angle");
	ClassDB::bind_method(D_METHOD("get_heading"), &AeroBody3D::get_heading);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "heading", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_heading");
	ClassDB::bind_method(D_METHOD("get_inclination"), &AeroBody3D::get_inclination);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "inclination", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE), "", "get_inclination");
}

int AeroBody3D::substeps = 1;

void AeroBody3D::refresh_transform_cache() {
	global_transform_cache = get_global_transform();

	for (AeroInfluencer3D* influencer : aero_influencers) {
		if (not influencer) continue;

		influencer->update_transform_cache(global_transform_cache);
	}
}
const Transform3D &AeroBody3D::get_cached_global_transform() const {
	return global_transform_cache;
}
Basis AeroBody3D::get_cached_global_basis() const {
	return global_transform_cache.basis;
}

static Callable *substeps_refresh_callable = nullptr;

void AeroBody3D::initialize_substeps() {
	refresh_substeps();

	substeps_refresh_callable = memnew(Callable(callable_mp_static(&AeroBody3D::refresh_substeps)));
	ProjectSettings::get_singleton()->connect("settings_changed", *substeps_refresh_callable);
}
void AeroBody3D::finalize_substeps() {
	if (not substeps_refresh_callable) return;

	ProjectSettings::get_singleton()->disconnect("settings_changed", *substeps_refresh_callable);
	memdelete(substeps_refresh_callable);
	substeps_refresh_callable = nullptr;
}
void AeroBody3D::refresh_substeps() {
	substeps = (int) ProjectSettings::get_singleton()->get_setting("physics/aerodynamics/substeps", 1);
}

AeroBody3D::AeroBody3D() {
	set_linear_damp_mode(DAMP_MODE_REPLACE);
	set_angular_damp_mode(DAMP_MODE_REPLACE);
	set_center_of_mass_mode(CENTER_OF_MASS_MODE_CUSTOM);

	linear_velocity_substep = get_linear_velocity();
	angular_velocity_substep = get_angular_velocity();
	
	PhysicsServer3D::get_singleton()->body_set_force_integration_callback(get_rid(), callable_mp(this, &AeroBody3D::integrate_forces));

	mass_debug_point = AeroUtils::create_debug_point_node("MassDebugPoint", Color(1.0, 1.0, 0.0), true, debug_center_width);
	force_debug_vector = AeroUtils::create_debug_vector_node("ForceDebugVector", Color(1.0, 1.0, 1.0), true, debug_width);
	torque_debug_vector = AeroUtils::create_debug_vector_node("TorqueDebugVector", Color(0.0, 0.0, 0.0), true, debug_width);
	lift_debug_vector = AeroUtils::create_debug_vector_node("LiftDebugVector", Color(0.0, 1.0, 1.0), true, debug_width);
	drag_debug_vector = AeroUtils::create_debug_vector_node("DragDebugVector", Color(1.0, 0.0, 0.0), true, debug_width);
	thrust_debug_vector = AeroUtils::create_debug_vector_node("ThrustDebugVector", Color(1.0, 0.0, 1.0), true, debug_width);
	linear_velocity_vector = AeroUtils::create_debug_vector_node("LinearVelocityVector", Color(0.0, 0.5, 0.5), false, debug_width);
	angular_velocity_vector = AeroUtils::create_debug_vector_node("AngularVelocityVector", Color(0.0, 0.333, 0.0), false, debug_width);
}

AeroBody3D::~AeroBody3D() {
	// Add your cleanup here.
}

void AeroBody3D::_enter_tree() {
	set_collision_layer_value(ProjectSettings::get_singleton()->get_setting("physics/aerodynamics/atmosphere_area_collision_layer", 15), true);

	if (Engine::get_singleton()->is_editor_hint()) {
		update_configuration_warnings();
	}
}
void AeroBody3D::_ready() {
	for (AeroInfluencer3D* influencer : aero_influencers) {
		if (influencer) influencer->generate_mirror();
	}

	if (mass_debug_point and not mass_debug_point->get_parent()) {
		mass_debug_point->add_child(force_debug_vector, INTERNAL_MODE_FRONT);
		mass_debug_point->add_child(lift_debug_vector, INTERNAL_MODE_FRONT);
		mass_debug_point->add_child(drag_debug_vector, INTERNAL_MODE_FRONT);
		mass_debug_point->add_child(thrust_debug_vector, INTERNAL_MODE_FRONT);
		mass_debug_point->add_child(torque_debug_vector, INTERNAL_MODE_FRONT);
		mass_debug_point->add_child(linear_velocity_vector, INTERNAL_MODE_FRONT);
		mass_debug_point->add_child(angular_velocity_vector, INTERNAL_MODE_FRONT);
		add_child(mass_debug_point, INTERNAL_MODE_FRONT);
	}

	set_show_debug(show_debug);
	_update_debug_scale();

	if (Engine::get_singleton()->is_editor_hint()) {
		update_configuration_warnings();
	}
}

PackedStringArray AeroBody3D::_get_configuration_warnings() const {
	PackedStringArray warnings;

	double default_linear_damp = ProjectSettings::get_singleton()->get_setting("physics/3d/default_linear_damp", 0.0);
	if (get_linear_damp_mode() == DAMP_MODE_COMBINE) {
		if (default_linear_damp + get_linear_damp() > 0.0) {
			warnings.append("Linear damping is greater than 0. Non-simulated drag will be present.");
		}
	} else {
		if (get_linear_damp() > 0.0) {
			warnings.append("Linear damping is greater than 0. Non-simulated drag will be present.");
		}
	}

	double default_angular_damp = ProjectSettings::get_singleton()->get_setting("physics/3d/default_angular_damp", 0.0);
	if (get_angular_damp_mode() == DAMP_MODE_COMBINE) {
		if (default_angular_damp + get_angular_damp() > 0.0) {
			warnings.append("Angular damping is greater than 0. Non-simulated drag will be present.");
		}
	} else {
		if (get_angular_damp() > 0.0) {
			warnings.append("Angular damping is greater than 0. Non-simulated drag will be present.");
		}
	}

	return warnings;
}

void AeroBody3D::_physics_process(double delta) {
	if (show_debug and update_debug) {
		_update_debug();
	}	
}

// I'd bet that there's a more performant way to implement this.
// integrate_forces is single-threaded, however I believe that RigidBody has an internal 
// physics update routine that is parallelized.
void AeroBody3D::integrate_forces(PhysicsDirectBodyState3D *body_state) {
	//only query the influencers when the body is actually asleep, and only wake it if one of them overrides sleep
	if (body_state->is_sleeping() and is_overriding_body_sleep()) {
		interrupt_sleep();
	}
	
	if (body_state->is_sleeping() or get_substeps() == 0) return;

	last_linear_velocity = uncommitted_last_linear_velocity;
	last_angular_velocity = uncommitted_last_angular_velocity;

	current_gravity = body_state->get_total_gravity();

	//I'm not sure if this is relevant in the C++ port.
	//it was needed in GDScript because the center_of_mass property wasn't updated from the body_state center of mass
	//if (not Engine::get_singleton()->is_editor_hint()) {
	//	set_center_of_mass(body_state->get_transform().get_basis().xform_inv(body_state->get_center_of_mass()));
	//}

	linear_velocity_substep = body_state->get_linear_velocity();
	angular_velocity_substep = body_state->get_angular_velocity();

	refresh_transform_cache();

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

	if (AeroUnits::get_singleton()) {
		altitude = AeroUnits::get_singleton()->get_altitude(this);
		mach = AeroUnits::get_singleton()->speed_to_mach_at_altitude(air_speed, altitude);
		air_density = AeroUnits::get_singleton()->get_density_at_altitude(altitude);
		air_pressure = AeroUnits::get_singleton()->get_pressure_at_altitude(altitude);
	} else {
		altitude = 0.0;
		mach = 0.0;
		air_density = 1.225;
		air_pressure = 101325.0;
	}
	
	wind = Vector3();
	for (Area3D* atmosphere : atmosphere_areas) {
		if (not atmosphere) continue;
		if (atmosphere->get("per_influencer_positioning")) continue;

		Variant wind_result = atmosphere->call("get_wind_at_position", get_global_position());
		
		wind += (Vector3) wind_result;
		if (atmosphere->get("override_density")) {
			air_density = atmosphere->call("get_density_at_position", get_global_position());
		}
	}
	
	Vector3 global_euler = global_transform_cache.basis.get_euler();
	bank_angle = global_euler.z;
	heading = global_euler.y;
	inclination = global_euler.x;

	
	ForceAndTorque last_force_and_torque;
	ForceAndTorque total_force_and_torque;

	int substep_count = get_substeps();
	double substep_delta = get_substep_delta();
	for (int substep = 0; substep < substep_count; substep++) {
		current_substep = substep;
		
		air_velocity = -get_linear_velocity_substep() + wind;
		air_speed = air_velocity.length();

		local_air_velocity = global_transform_cache.basis.xform_inv(air_velocity);
		local_angular_velocity = global_transform_cache.basis.xform_inv(angular_velocity_substep);
		angle_of_attack = global_transform_cache.basis.get_column(1).angle_to(-air_velocity) - (Math::PI / 2.0);
		sideslip_angle = global_transform_cache.basis.get_column(0).angle_to(air_velocity) - (Math::PI / 2.0); 
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

		if (Engine::get_singleton()->is_editor_hint()) break; //only simulate 1 substep: see https://github.com/addmix/godot_aerodynamic_physics/issues/35
	}

	total_force_and_torque /= substep_count;

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

			influencer->_update_transform_substep_with_override(substep_delta);
		}
	}
}

Vector3 AeroBody3D::calculate_linear_velocity_substep(Vector3 force) const { return linear_velocity_substep + (force / get_mass() * get_substep_delta()); }
Vector3 AeroBody3D::calculate_angular_velocity_substep(Vector3 torque) const { return angular_velocity_substep + (get_inverse_inertia_tensor().xform(torque) * get_substep_delta()); }
Vector3 AeroBody3D::calculate_relative_position() const { return get_global_basis().xform(-get_center_of_mass()); }
Vector3 AeroBody3D::calculate_drag_direction() const { return air_velocity.normalized(); }
//Vector3 AeroBody3D::calculate_linear_acceleration() const {
//	return (linear_velocity_substep - last_linear_velocity) / substep_delta;
//}
//Vector3 AeroBody3D::calculate_angular_acceleration() const {
//	return (angular_velocity_substep - last_angular_velocity) / substep_delta;
//}



double AeroBody3D::get_control_command(StringName axis_name) {
	Node* control_component = AeroUtils::get_first_child_of_type(this, "AeroControlComponent");
	if (control_component) {
		return (double) control_component->call("get_control_command", axis_name);
	}
	return 0.0;
}
bool AeroBody3D::is_overriding_body_sleep() const {
	bool overriding = false;

	for (AeroInfluencer3D* influencer : aero_influencers) {
		if (not influencer) continue;
		if (influencer->is_disabled()) continue;

		overriding = overriding or influencer->is_overriding_body_sleep_with_override();
	}

	return overriding;
}

void AeroBody3D::interrupt_sleep() {
	set_sleeping(false);
}

TypedArray<AeroInfluencer3D> AeroBody3D::get_aero_influencers() const {
	TypedArray<AeroInfluencer3D> result;
	result.resize((int) aero_influencers.size());
	for (size_t i = 0; i < aero_influencers.size(); i++) {
		result[(int) i] = aero_influencers[i];
	}
	return result;
}
TypedArray<Area3D> AeroBody3D::get_atmosphere_areas() const {
	TypedArray<Area3D> result;
	result.resize((int) atmosphere_areas.size());
	for (size_t i = 0; i < atmosphere_areas.size(); i++) {
		result[(int) i] = atmosphere_areas[i];
	}
	return result;
}
const std::vector<Area3D*> &AeroBody3D::get_atmosphere_areas_internal() const { return atmosphere_areas; }

void AeroBody3D::add_aero_influencer(AeroInfluencer3D* influencer) { aero_influencers.push_back(influencer); }
void AeroBody3D::remove_aero_influencer(AeroInfluencer3D* influencer) {
	for (size_t i = 0; i < aero_influencers.size(); i++) {
		if (aero_influencers[i] == influencer) {
			aero_influencers.erase(aero_influencers.begin() + i);
			break;
		}
	}
}

void AeroBody3D::add_aero_atmosphere(Area3D* atmosphere) { atmosphere_areas.push_back(atmosphere); }
void AeroBody3D::remove_aero_atmosphere(Area3D* atmosphere) {
	for (size_t i = 0; i < atmosphere_areas.size(); i++) {
		if (atmosphere_areas[i] == atmosphere) {
			atmosphere_areas.erase(atmosphere_areas.begin() + i);
			break;
		}
	}
}

void AeroBody3D::set_substeps_override(int p_substeps) {substeps_override = p_substeps;}
int AeroBody3D::get_substeps_override() const {return substeps_override;}
int AeroBody3D::get_substeps() const {
	if (substeps_override > -1){
		return substeps_override;
	}
	
	return substeps;
}
double AeroBody3D::get_prediction_timestep_fraction() const {return 1.0 / (double)get_substeps();}
double AeroBody3D::get_substep_delta() const { return get_physics_process_delta_time() * get_prediction_timestep_fraction(); }
int AeroBody3D::get_current_substep() const { return current_substep; }



int AeroBody3D::get_amount_of_active_influencers() const {
	int count = 0;
	for (AeroInfluencer3D* influencer : aero_influencers) {
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
Vector3 AeroBody3D::get_angular_acceleration() const {return angular_acceleration;}
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
void AeroBody3D::_update_debug_visibility() {
	for (AeroInfluencer3D* influencer : aero_influencers) {
		if (not influencer) continue;
		influencer->set_show_debug(show_debug and show_wing_debug_vectors);
	}

	if (force_debug_vector) force_debug_vector->set_visible(show_debug);
	if (torque_debug_vector) torque_debug_vector->set_visible(show_debug and show_torque);
	if (linear_velocity_vector) linear_velocity_vector->set_visible(show_debug and show_linear_velocity);
	if (angular_velocity_vector) angular_velocity_vector->set_visible(show_debug and show_angular_velocity);
	if (lift_debug_vector) lift_debug_vector->set_visible(show_debug and show_center_of_lift);
	if (drag_debug_vector) drag_debug_vector->set_visible(show_debug and show_center_of_drag);
	if (mass_debug_point) mass_debug_point->set_visible(show_debug and show_center_of_mass);
	if (thrust_debug_vector) thrust_debug_vector->set_visible(show_debug and show_center_of_thrust);
}

void AeroBody3D::_update_debug_scale() {
	for (AeroInfluencer3D* influencer : aero_influencers) {
		if (not influencer) continue;
		influencer->set_debug_scale(debug_scale);
		influencer->set_debug_scaling_factor(debug_scaling_factor);
		influencer->set_debug_width(debug_influencer_width);
	}

	if (linear_velocity_vector) linear_velocity_vector->set("width", debug_width);
	if (angular_velocity_vector) angular_velocity_vector->set("width", debug_width);
	if (force_debug_vector) force_debug_vector->set("width", debug_width);
	if (torque_debug_vector) torque_debug_vector->set("width", debug_width);
	if (lift_debug_vector) lift_debug_vector->set("width", debug_width);
	if (drag_debug_vector) drag_debug_vector->set("width", debug_width);
	if (thrust_debug_vector) thrust_debug_vector->set("width", debug_width);
	if (mass_debug_point) mass_debug_point->set("width", debug_center_width);
}

void AeroBody3D::_update_debug() {
	if (not is_inside_tree()) return;

	//integrate_forces doesn't run in the editor, so keep the caches fresh for the debug pass
	refresh_transform_cache();

	if (mass_debug_point) mass_debug_point->set_position(get_center_of_mass());

	Vector3 linear_velocity_to_use = get_linear_velocity();
	Vector3 angular_velocity_to_use = get_angular_velocity();
	
	if (Engine::get_singleton()->is_editor_hint()) {
		linear_velocity_to_use = debug_linear_velocity;
		angular_velocity_to_use = debug_angular_velocity;

		//Godot doesn't run the physics engine in-editor, so calculate the forces manually with the debug velocities.
		Vector3 original_linear_velocity = get_linear_velocity();
		Vector3 original_angular_velocity = get_angular_velocity();
		set_linear_velocity(debug_linear_velocity);
		set_angular_velocity(debug_angular_velocity);
		calculate_forces(get_substep_delta());
		set_linear_velocity(original_linear_velocity);
		set_angular_velocity(original_angular_velocity);
	}

	Basis inverse_basis = get_global_transform().get_basis().inverse();

	if (force_debug_vector) force_debug_vector->set("value", inverse_basis.xform(AeroUtils::v3log_with_base(current_force, 2.0)));
	if (torque_debug_vector) torque_debug_vector->set("value", inverse_basis.xform(AeroUtils::v3log_with_base(current_torque, 2.0)));
	if (linear_velocity_vector) linear_velocity_vector->set("value", inverse_basis.xform(AeroUtils::v3log_with_base(linear_velocity_to_use, 2.0)));
	if (angular_velocity_vector) angular_velocity_vector->set("value", inverse_basis.xform(AeroUtils::v3log_with_base(angular_velocity_to_use, 2.0)));

	//accumulate per-influencer forces
	Vector<Node*> all_influencers;
	AeroUtils::get_descendants_of_type(this, "AeroInfluencer3D", all_influencers);

	if (all_influencers.size() > 0) {
		double force_sum = 0.0;
		Vector3 force_vector_sum = Vector3();
		Vector3 force_position_sum = Vector3();
		double lift_sum = 0.0;
		Vector3 lift_vector_sum = Vector3();
		Vector3 lift_position_sum = Vector3();
		double drag_sum = 0.0;
		Vector3 drag_vector_sum = Vector3();
		Vector3 drag_position_sum = Vector3();
		double thrust_sum = 0.0;
		Vector3 thrust_vector_sum = Vector3();
		Vector3 thrust_position_sum = Vector3();

		Vector3 drag_direction = get_drag_direction();

		for (int i = 0; i < all_influencers.size(); i++) {
			AeroInfluencer3D* influencer = Object::cast_to<AeroInfluencer3D>(all_influencers[i]);
			if (not influencer) continue;
			//skip omitted or disabled influencers, they don't contribute to the debug vectors
			if (influencer->is_omitted_from_debug() or influencer->is_disabled()) continue;

			Vector3 force_vector = influencer->get_current_force();
			double force = force_vector.length();
			force_sum += force;
			force_vector_sum += force_vector;
			force_position_sum += influencer->get_relative_position() * force;

			Vector3 drag_vector = Math::max(force_vector.dot(drag_direction), 0.0) * drag_direction;
			double drag = drag_vector.length();
			drag_sum += drag;
			drag_vector_sum += drag_vector;
			drag_position_sum += influencer->get_relative_position() * drag;

			Vector3 lift_vector = force_vector - force_vector.dot(drag_direction) * drag_direction;
			double lift = lift_vector.length();
			lift_sum += lift;
			lift_vector_sum += lift_vector;
			lift_position_sum += influencer->get_relative_position() * lift;

			Vector3 thrust_vector = Math::min(force_vector.dot(drag_direction), 0.0) * drag_direction;
			double thrust = thrust_vector.length();
			thrust_sum += thrust;
			thrust_vector_sum += thrust_vector;
			thrust_position_sum += influencer->get_relative_position() * thrust;
		}

		if (force_debug_vector) {
			force_debug_vector->set("value", inverse_basis.xform(AeroUtils::v3log_with_base(force_vector_sum, debug_scaling_factor)) * debug_scale);
			if (not Math::is_equal_approx(force_sum, 0.0)) force_debug_vector->set_position(inverse_basis.xform(force_position_sum / force_sum));
		}
		if (drag_debug_vector) {
			drag_debug_vector->set("value", inverse_basis.xform(AeroUtils::v3log_with_base(drag_vector_sum, debug_scaling_factor)) * debug_scale);
			if (not Math::is_equal_approx(drag_sum, 0.0)) drag_debug_vector->set_position(inverse_basis.xform(drag_position_sum / drag_sum));
		}
		if (lift_debug_vector) {
			lift_debug_vector->set("value", inverse_basis.xform(AeroUtils::v3log_with_base(lift_vector_sum, debug_scaling_factor)) * debug_scale);
			if (not Math::is_equal_approx(lift_sum, 0.0)) lift_debug_vector->set_position(inverse_basis.xform(lift_position_sum / lift_sum));
		}
		if (thrust_debug_vector) {
			thrust_debug_vector->set("value", inverse_basis.xform(AeroUtils::v3log_with_base(thrust_vector_sum, debug_scaling_factor)) * debug_scale);
			if (not Math::is_equal_approx(thrust_sum, 0.0)) thrust_debug_vector->set_position(inverse_basis.xform(thrust_position_sum / thrust_sum));
		}
	}

	for (AeroInfluencer3D* influencer : aero_influencers) {
		if (not influencer) continue;
		influencer->update_debug_vectors();
	}
}

//debug visibility
void AeroBody3D::set_show_debug(bool value) {
	show_debug = value;
	_update_debug_visibility();
}
bool AeroBody3D::get_show_debug() const {return show_debug;}


void AeroBody3D::set_update_debug(bool value) {update_debug = value;}
bool AeroBody3D::get_update_debug() const {return update_debug;}

void AeroBody3D::set_show_wing_debug_vectors(bool value) {
	show_wing_debug_vectors = value;
	_update_debug_visibility();
}
bool AeroBody3D::get_show_wing_debug_vectors() const {return show_wing_debug_vectors;}

void AeroBody3D::set_show_lift_vectors(bool value) {
	show_lift = value;
	_update_debug_visibility();
}
bool AeroBody3D::get_show_lift_vectors() const {return show_lift;}

void AeroBody3D::set_show_drag_vectors(bool value) {
	show_drag = value;
	_update_debug_visibility();
}
bool AeroBody3D::get_show_drag_vectors() const {return show_drag;}

void AeroBody3D::set_show_linear_velocity(bool value) {
	show_linear_velocity = value;
	_update_debug_visibility();
}
bool AeroBody3D::get_show_linear_velocity() const {return show_linear_velocity;}

void AeroBody3D::set_show_angular_velocity(bool value) {
	show_angular_velocity = value;
	_update_debug_visibility();
}
bool AeroBody3D::get_show_angular_velocity() const {return show_angular_velocity;}

void AeroBody3D::set_show_center_of_lift(bool value) {
	show_center_of_lift = value;
	_update_debug_visibility();
}
bool AeroBody3D::get_show_center_of_lift() const {return show_center_of_lift;}

void AeroBody3D::set_show_torque(bool value) {
	show_torque = value;
	_update_debug_visibility();
}
bool AeroBody3D::get_show_torque() const {return show_torque;}

void AeroBody3D::set_show_center_of_drag(bool value) {
	show_center_of_drag = value;
	_update_debug_visibility();
}
bool AeroBody3D::get_show_center_of_drag() const {return show_center_of_drag;}

void AeroBody3D::set_show_center_of_mass(bool value) {
	show_center_of_mass = value;
	_update_debug_visibility();
}
bool AeroBody3D::get_show_center_of_mass() const {return show_center_of_mass;}

void AeroBody3D::set_show_center_of_thrust(bool value) {
	show_center_of_thrust = value;
	_update_debug_visibility();
}
bool AeroBody3D::get_show_center_of_thrust() const {return show_center_of_thrust;}

//debug options
void AeroBody3D::set_debug_linear_velocity(Vector3 value) {debug_linear_velocity = value;}
Vector3 AeroBody3D::get_debug_linear_velocity() const {return debug_linear_velocity;}

void AeroBody3D::set_debug_angular_velocity(Vector3 value) {debug_angular_velocity = value;}
Vector3 AeroBody3D::get_debug_angular_velocity() const {return debug_angular_velocity;}

void AeroBody3D::set_debug_scale(double value) {
	debug_scale = value;
	_update_debug_scale();
}
double AeroBody3D::get_debug_scale() const {return debug_scale;}

void AeroBody3D::set_debug_scaling_factor(double value) {
	debug_scaling_factor = value;
	_update_debug_scale();
}
double AeroBody3D::get_debug_scaling_factor() const {return debug_scaling_factor;}

void AeroBody3D::set_debug_width(double value) {
	debug_width = value;
	_update_debug_scale();
}
double AeroBody3D::get_debug_width() const {return debug_width;}

void AeroBody3D::set_influencer_debug_width(double value) {
	debug_influencer_width = value;
	_update_debug_scale();
}
double AeroBody3D::get_influencer_debug_width() const {return debug_influencer_width;}

void AeroBody3D::set_debug_center_width(double value) {
	debug_center_width = value;
	_update_debug_scale();
}
double AeroBody3D::get_debug_center_width() const {return debug_center_width;}
