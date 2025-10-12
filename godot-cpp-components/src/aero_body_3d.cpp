#include "aero_body_3d.h"

using namespace godot;

void AeroBody3D::_bind_methods() {
	// substep override
	ClassDB::bind_method(D_METHOD("set_substeps_override", "p_substeps"), &AeroBody3D::set_substeps_override);
	ClassDB::bind_method(D_METHOD("get_substeps_override"), &AeroBody3D::get_substeps_override);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "substeps_override"), "set_substeps_override", "get_substeps_override");
	
	//register function so we can use it with a signal.
	ClassDB::bind_method(D_METHOD("on_child_entered_tree", "node"), &AeroBody3D::on_child_entered_tree);
	ClassDB::bind_method(D_METHOD("on_child_exiting_tree", "node"), &AeroBody3D::on_child_exiting_tree);

	ClassDB::bind_method(D_METHOD("get_substeps"), &AeroBody3D::get_substeps);
	ClassDB::bind_method(D_METHOD("get_aero_influencers"), &AeroBody3D::get_aero_influencers);
	ClassDB::bind_method(D_METHOD("get_prediction_timestep_fraction"), &AeroBody3D::get_prediction_timestep_fraction);
	ClassDB::bind_method(D_METHOD("get_current_force"), &AeroBody3D::get_current_force);
	ClassDB::bind_method(D_METHOD("get_current_torque"), &AeroBody3D::get_current_torque);
	ClassDB::bind_method(D_METHOD("get_current_gravity"), &AeroBody3D::get_current_gravity);
	ClassDB::bind_method(D_METHOD("get_last_linear_velocity"), &AeroBody3D::get_last_linear_velocity);
	ClassDB::bind_method(D_METHOD("get_last_angular_velocity"), &AeroBody3D::get_last_angular_velocity);
	ClassDB::bind_method(D_METHOD("get_wind"), &AeroBody3D::get_wind);
	ClassDB::bind_method(D_METHOD("get_air_velocity"), &AeroBody3D::get_air_velocity);
	ClassDB::bind_method(D_METHOD("get_local_air_velocity"), &AeroBody3D::get_local_air_velocity);
	ClassDB::bind_method(D_METHOD("get_local_angular_velocity"), &AeroBody3D::get_local_angular_velocity);
	ClassDB::bind_method(D_METHOD("get_air_speed"), &AeroBody3D::get_air_speed);
	ClassDB::bind_method(D_METHOD("get_mach"), &AeroBody3D::get_mach);
	ClassDB::bind_method(D_METHOD("get_air_density"), &AeroBody3D::get_air_density);
	ClassDB::bind_method(D_METHOD("get_air_pressure"), &AeroBody3D::get_air_pressure);
	ClassDB::bind_method(D_METHOD("get_angle_of_attack"), &AeroBody3D::get_angle_of_attack);
	ClassDB::bind_method(D_METHOD("get_sideslip_angle"), &AeroBody3D::get_sideslip_angle);
	ClassDB::bind_method(D_METHOD("get_altitude"), &AeroBody3D::get_altitude);
	ClassDB::bind_method(D_METHOD("get_bank_angle"), &AeroBody3D::get_bank_angle);
	ClassDB::bind_method(D_METHOD("get_heading"), &AeroBody3D::get_heading);
	ClassDB::bind_method(D_METHOD("get_inclination"), &AeroBody3D::get_inclination);

	ClassDB::bind_method(D_METHOD("integrate_forces_callback", "body_state"), &AeroBody3D::integrate_forces);
	//debug bindings
	ADD_GROUP("Debug", "");
	//debug visibility
	ClassDB::bind_method(D_METHOD("set_show_debug", "visible"), &AeroBody3D::set_show_debug);
	ClassDB::bind_method(D_METHOD("get_show_debug"), &AeroBody3D::get_show_debug);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "show_debug"), "set_show_debug", "get_show_debug");
	bool update_debug;
	bool show_wing_debug_vectors;
	bool show_lift_vectors;
	bool show_drag_vectors;
	bool show_linear_velocity;
	bool show_angular_velocity;
	bool show_center_of_lift;
	bool show_center_of_drag;
	bool show_center_of_mass;
	bool show_center_of_thrust;
	
	//debug options
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
}

AeroBody3D::AeroBody3D() {
	// Initialize any variables here.
	set_substeps_override(-1);
	set_substeps(1);
	set_center_of_mass_mode(CENTER_OF_MASS_MODE_CUSTOM);

	
	linear_velocity_prediction = RigidBody3D::get_linear_velocity();
	angular_velocity_prediction = RigidBody3D::get_angular_velocity();

	if (not this->is_connected("child_entered_tree", Callable(this, "on_child_entered_tree"))) {
		this->connect("child_entered_tree", Callable(this, "on_child_entered_tree"));
	}
	if (not this->is_connected("child_exiting_tree", Callable(this, "on_child_exiting_tree"))) {
		this->connect("child_exiting_tree", Callable(this, "on_child_exiting_tree"));
	}
	

	PhysicsServer3D::get_singleton()->body_set_force_integration_callback(get_rid(), Callable(this, "integrate_forces_callback"));

	//vector_3d_script = ResourceLoader::get_singleton()->load("res://addons/godot_aerodynamic_physics/utils/vector_3d/vector_3d.gd");
	//point_3d_script = ResourceLoader::get_singleton()->load("res://addons/godot_aerodynamic_physics/utils/point_3d/point_3d.gd");
}

AeroBody3D::~AeroBody3D() {
	// Add your cleanup here.
}

void AeroBody3D::_enter_tree() {
	//update_configuration_warnings();
}
void AeroBody3D::_ready() {
	//set_show_debug(show_debug);
}
void AeroBody3D::on_child_entered_tree(Node *p_node) {
	if (p_node->is_class("AeroInfluencer3D")) {
		AeroInfluencer3D* influencer = (AeroInfluencer3D*) p_node;

		aero_influencers.append(influencer);
		influencer->set_aero_body(this);
	}
}
void AeroBody3D::on_child_exiting_tree(Node *p_node) {
	if (p_node->is_class("AeroInfluencer3D")) {
		AeroInfluencer3D* influencer = (AeroInfluencer3D*) p_node;

		aero_influencers.erase(p_node);
		influencer->set_aero_body(nullptr);
	}
}

//PackedStringArray AeroBody3D::_get_configuration_warnings() const {}
void AeroBody3D::_process(double delta) {}
void AeroBody3D::_physics_process(double delta) {}
/*
	if (show_debug and update_debug) {
		_update_debug();
	}
}*/

void AeroBody3D::integrate_forces(PhysicsDirectBodyState3D *body_state) {
	//start timing
	//PhysicsDirectBodyState3D* body_state = (PhysicsDirectBodyState3D*) (Object*) p_variant;

	if (body_state->is_sleeping() or substeps == 0) return;

	current_gravity = body_state->get_total_gravity();

	PackedVector3Array total_force_and_torque = calculate_forces(body_state);
	current_force = total_force_and_torque[0];
	current_torque = total_force_and_torque[1];
	
	body_state->apply_central_force(current_force);
	body_state->apply_torque(current_torque);

	//end timing
}

PackedVector3Array AeroBody3D::calculate_forces(PhysicsDirectBodyState3D *body_state) {
	wind = Vector3();
	air_velocity = -body_state->get_linear_velocity() + wind;
	air_speed = air_velocity.length();

	if (has_node("/root/AeroUnits")) {
		Node AeroUnits = *get_node_or_null("/root/AeroUnits");
		altitude = AeroUnits.call("get_altitude", this);
		mach = AeroUnits.call("speed_to_mach_at_altitude", air_speed, altitude);
		air_density = AeroUnits.call("get_density_at_altitude", altitude);
		air_pressure = AeroUnits.call("get_pressure_at_altitude", altitude);
	}
	
	local_air_velocity = get_global_transform().get_basis().xform_inv(air_velocity);
	local_angular_velocity = get_global_transform().get_basis().xform_inv(body_state->get_angular_velocity());
	angle_of_attack = get_global_basis().get_column(1).angle_to(-air_velocity) - (Math_PI / 2.0);
	sideslip_angle = get_global_basis().get_column(0).angle_to(air_velocity) - (Math_PI / 2.0);
	bank_angle = get_rotation().z;
	heading = get_rotation().y;
	inclination = get_rotation().x;

	if (not Engine::get_singleton()->is_editor_hint()) {
		set_center_of_mass(body_state->get_center_of_mass());
	}

	substep_delta = body_state->get_step() / substeps;

	PackedVector3Array last_force_and_torque = PackedVector3Array(Array());
	last_force_and_torque.append(Vector3()); //idk how to properly instantiate the array with items.
	last_force_and_torque.append(Vector3());
	PackedVector3Array total_force_and_torque = last_force_and_torque;

	linear_velocity_prediction = body_state->get_linear_velocity();
	angular_velocity_prediction = body_state->get_angular_velocity();

	for (int substep = 0; substep < substeps; substep++) {
		last_linear_velocity = linear_velocity_prediction;
		last_angular_velocity = angular_velocity_prediction;

		if (not Engine::get_singleton()->is_editor_hint()) {
			for (int i = 0; i < aero_influencers.size(); i++) {
				AeroInfluencer3D* influencer = (AeroInfluencer3D*) (Object*) aero_influencers[i];
				if (influencer->is_disabled()) continue;

				influencer->_update_transform_substep(substep_delta);
			}
		}

		linear_velocity_prediction = predict_linear_velocity(last_force_and_torque[0] + body_state->get_total_gravity() * get_mass());
		angular_velocity_prediction = predict_angular_velocity(last_force_and_torque[1]);
		last_force_and_torque = calculate_aerodynamic_forces(substep_delta);

		total_force_and_torque[0] += last_force_and_torque[0];
		total_force_and_torque[1] += last_force_and_torque[1];
	}

	total_force_and_torque[0] = total_force_and_torque[0] / substeps;
	total_force_and_torque[1] = total_force_and_torque[1] / substeps;

	return total_force_and_torque;
}

PackedVector3Array AeroBody3D::calculate_aerodynamic_forces(double substep_delta) {
	Vector3 force;
	Vector3 torque;

	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = (AeroInfluencer3D*) (Object*) aero_influencers[i];

		if (influencer->is_disabled()) {
			PackedVector3Array total_force_and_torque = PackedVector3Array();
			total_force_and_torque.append(force);
			total_force_and_torque.append(torque);
			return total_force_and_torque;
		}

		Vector3 relative_position = get_global_basis().xform(influencer->get_position() - get_center_of_mass());
		PackedVector3Array force_and_torque = influencer->calculate_forces_with_override(substep_delta);
		
		force += force_and_torque[0];
		torque += force_and_torque[1];
	}

	PackedVector3Array total_force_and_torque = PackedVector3Array();
	total_force_and_torque.append(force);
	total_force_and_torque.append(torque);
	return total_force_and_torque;
}

Vector3 AeroBody3D::predict_linear_velocity(Vector3 force) {
	return get_linear_velocity() + get_physics_process_delta_time() * (prediction_timestep_fraction * force / get_mass());
}
Vector3 AeroBody3D::predict_angular_velocity(Vector3 torque) {
	return get_angular_velocity() + get_physics_process_delta_time() * prediction_timestep_fraction * (get_inverse_inertia_tensor().xform(torque));
}



Vector3 AeroBody3D::get_relative_position() {
	return get_global_basis().xform(-get_center_of_mass());
}
Vector3 AeroBody3D::get_linear_velocity() {
	return linear_velocity_prediction;
}
Vector3 AeroBody3D::get_angular_velocity() {
	return angular_velocity_prediction;
}
Vector3 AeroBody3D::get_linear_acceleration() {
	return (linear_velocity_prediction - last_linear_velocity) / substep_delta;
}
Vector3 AeroBody3D::get_angular_acceleration() {
	return (angular_velocity_prediction - last_angular_velocity) / substep_delta;
}



// Debug vector section






void AeroBody3D::set_substeps_override(const int p_substeps) {substeps_override = p_substeps;}
int AeroBody3D::get_substeps_override() const {return substeps_override;}
void AeroBody3D::set_substeps(const int p_substeps) {
	substeps = p_substeps;
	prediction_timestep_fraction = (double) 1.0f / (double) substeps;
}
int AeroBody3D::get_substeps() const {
	if (substeps_override > -1){
		return substeps_override;
	}
	
	return (int) ProjectSettings::get_singleton()->get_setting("physics/3d/aerodynamics/substeps", 1);
}

void AeroBody3D::set_aero_influencers(const TypedArray<AeroInfluencer3D> new_arr) {
	aero_influencers.assign(new_arr);
	
	//example of how to get a pointer to a node in the typed array.
	// Also TypedArray operator [] will still return Variant
	// so you will need to do this weird cast to get node types
	//if(aero_influencers.size() > 0) {
	//    AeroInfluencer3D* node = (AeroInfluencer3D*) (Object*) nodes[0]; 
	//}
}

TypedArray<AeroInfluencer3D> AeroBody3D::get_aero_influencers() const { return aero_influencers; }
double AeroBody3D::get_prediction_timestep_fraction() const {return prediction_timestep_fraction;}
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



int AeroBody3D::get_amount_of_active_influencers() {
	int count = 0;
	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = (AeroInfluencer3D*) (Object*) aero_influencers[i];
		if (not influencer->is_disabled()) count += 1;
	}

	return count;
}
//debug
void AeroBody3D::_update_debug() {
	if (not is_inside_tree()) return;
	/*
	aero_surfaces = []
	for i : AeroInfluencer3D in aero_influencers:
		if i is AeroSurface3D:
			aero_surfaces.append(i)
	
	mass_debug_point.position = center_of_mass
	#thrust_debug_vector.position = center of thrust
	*/
	
	Vector3 linear_velocity_to_use = RigidBody3D::get_linear_velocity();
	Vector3 angular_velocity_to_use = RigidBody3D::get_angular_velocity();

	if (Engine::get_singleton()->is_editor_hint()) {
		//Godot doesn't run physics engine in-editor.
		//A consequence of this is that get_linear_velocity doesn't work.
		//Instead, we must access linear_velocity directly.
		//We don't want to overwrite user configured linear velocity, so we must use this workaround.
		//Vector3 original_linear_velocity = RigidBody3D::get_linear_velocity();
		//Vector3 original_angular_velocity = RigidBody3D::get_angular_velocity();
		//RigidBody3D::set_linear_velocity(debug_linear_velocity);
		//RigidBody3D::set_angular_velocity(debug_angular_velocity);
		PackedVector3Array last_force_and_torque = calculate_aerodynamic_forces(get_physics_process_delta_time());
		//RigidBody3D::set_linear_velocity(original_linear_velocity);
		//RigidBody3D::set_angular_velocity(original_angular_velocity);

		linear_velocity_to_use = debug_linear_velocity;
		angular_velocity_to_use = debug_angular_velocity;
	}
	
	if (is_inside_tree()) {
		if (linear_velocity_vector) {
			//linear_velocity_vector->set_deferred("value", get_global_basis().xform_inv(linear_velocity_to_use));
		}
		if (angular_velocity_vector) {
			//angular_velocity_vector->set_deferred("value", get_global_basis().xform_inv(angular_velocity_to_use));
		}
	}

	//linear_velocity_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(linear_velocity_to_use, 2.0)
	//angular_velocity_vector.value = global_transform.basis.inverse() * AeroMathUtils.v3log_with_base(angular_velocity_to_use, 2.0)
	

	if (aero_influencers.size() > 0) {
		int amount_of_aero_influencers = aero_influencers.size();
		double force_sum = 0.0;
		Vector3 force_vector_sum = Vector3();
		
		for (int i = 0; i < aero_influencers.size(); i++) {
			AeroInfluencer3D* influencer = (AeroInfluencer3D*) (Object*) aero_influencers[i];

			if (/*influencer.omit_from_debug or */influencer->is_disabled()) {
				amount_of_aero_influencers -= 1;
				continue;
			}
				
			force_vector_sum += influencer->get_current_force();
		}
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
	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = (AeroInfluencer3D*) (Object*) aero_influencers[i];
		influencer->update_debug();
	}
}

//debug visibility
void AeroBody3D::set_show_debug(const bool value) {
	show_debug = value;
	
	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = (AeroInfluencer3D*) (Object*) aero_influencers[i];
		influencer->set_show_debug(show_debug);
	}

	/*
	if (show_debug) {
		
		if (not linear_velocity_vector) {
			linear_velocity_vector = memnew(MeshInstance3D);
			linear_velocity_vector->set_script(vector_3d_script);

			linear_velocity_vector->set("width", debug_width);
			linear_velocity_vector->set("color", Color(0, 0.5, 0.5));
			add_child(linear_velocity_vector, INTERNAL_MODE_FRONT);
		}
		if (not angular_velocity_vector) {
			angular_velocity_vector = memnew(MeshInstance3D);
			angular_velocity_vector->set_script(vector_3d_script);
			
			angular_velocity_vector->set("width", debug_width);
			angular_velocity_vector->set("color", Color(0, 0.333, 0));
			add_child(angular_velocity_vector, INTERNAL_MODE_FRONT);

			angular_velocity_vector->set_visible(false); //angular velocity vector isn't very useful, so it's hidden for my sanity
		}

		_update_debug();
	} else {
		if (linear_velocity_vector) {
			linear_velocity_vector->queue_free();
			linear_velocity_vector = nullptr;
		}
		if (angular_velocity_vector) {
			angular_velocity_vector->queue_free();
			angular_velocity_vector = nullptr;
		}
	}*/
}
bool AeroBody3D::get_show_debug() const {return show_debug;}


void AeroBody3D::set_update_debug(const bool value) {update_debug = value;}
bool AeroBody3D::get_update_debug() const {return update_debug;}

void AeroBody3D::set_show_wing_debug_vectors(const bool value) {show_wing_debug_vectors = value;}
bool AeroBody3D::get_show_wing_debug_vectors() const {return show_wing_debug_vectors;}

void AeroBody3D::set_show_lift_vectors(const bool value) {show_lift_vectors = value;}
bool AeroBody3D::get_show_lift_vectors() const {return show_lift_vectors;}

void AeroBody3D::set_show_drag_vectors(const bool value) {show_drag_vectors = value;}
bool AeroBody3D::get_show_drag_vectors() const {return show_drag_vectors;}

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

	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = (AeroInfluencer3D*) (Object*) aero_influencers[i];
		influencer->set_debug_scale(debug_scale);
	}
}
double AeroBody3D::get_debug_scale() const {return debug_scale;}

void AeroBody3D::set_debug_width(const double value) {
	debug_width = value;

	
	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = (AeroInfluencer3D*) (Object*) aero_influencers[i];
		influencer->set_debug_width(debug_width);
	}

	/*
	if (not is_inside_tree()) return;
	if (linear_velocity_vector) {
		linear_velocity_vector->set("width", debug_width);
	}
	if (angular_velocity_vector) {
		angular_velocity_vector->set("width", debug_width);
	}
	*/
}
double AeroBody3D::get_debug_width() const {return debug_width;}

void AeroBody3D::set_debug_center_width(const double value) {
	debug_center_width = value;
}
double AeroBody3D::get_debug_center_width() const {return debug_center_width;}
