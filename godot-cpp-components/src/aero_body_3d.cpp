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
}

AeroBody3D::AeroBody3D() {
	// Initialize any variables here.
	set_substeps_override(-1);
	set_substeps(1);

	linear_velocity_prediction = RigidBody3D::get_linear_velocity();
	angular_velocity_prediction = RigidBody3D::get_angular_velocity();

	//ResourceLoader::get_singleton()->load("");
}

AeroBody3D::~AeroBody3D() {
	// Add your cleanup here.
}

void AeroBody3D::_notification(int p_notification) {
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
void AeroBody3D::on_enter_tree() {
	update_configuration_warnings();
}
void AeroBody3D::on_ready() {
	this->connect("child_entered_tree", Callable(this, "on_child_entered_tree"));
	this->connect("child_exiting_tree", Callable(this, "on_child_exiting_tree"));
	PhysicsServer3D::get_singleton()->body_set_force_integration_callback(get_rid(), Callable(this, "integrate_forces_callback"));
}
void AeroBody3D::on_child_entered_tree(Node *p_node) {
	//UtilityFunctions::print("child added ", typed_node->get_name());

	if (p_node->is_class("AeroInfluencer3D")) {
		AeroInfluencer3D* influencer = (AeroInfluencer3D*) p_node;

		aero_influencers.append(influencer);
		influencer->set_aero_body(this);
	}
}
void AeroBody3D::on_child_exiting_tree(Node *p_node) {
	//UtilityFunctions::print("child removed ", typed_node->get_name());

	if (p_node->is_class("AeroInfluencer3D")) {
		AeroInfluencer3D* influencer = (AeroInfluencer3D*) p_node;

		aero_influencers.erase(p_node);
		influencer->set_aero_body(nullptr);
	}
}
void AeroBody3D::on_process(double delta) const {}

/*
void AeroBody3D::_get_configuration_warnings(){
	
}
*/

void AeroBody3D::on_physics_process(double delta) const {
	/*
	if (show_debug and update_debug) {
		_update_debug();
	}
	*/
}

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
		last_force_and_torque = calculate_aerodynamic_forces(linear_velocity_prediction, angular_velocity_prediction, air_density, substep_delta);

		total_force_and_torque[0] += last_force_and_torque[0];
		total_force_and_torque[1] += last_force_and_torque[1];
	}

	total_force_and_torque[0] = total_force_and_torque[0] / substeps;
	total_force_and_torque[1] = total_force_and_torque[1] / substeps;

	return total_force_and_torque;
}

PackedVector3Array AeroBody3D::calculate_aerodynamic_forces(Vector3 linear_velocity, Vector3 angular_velocity, double air_density, double substep_delta) {
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
	//UtilityFunctions::print("set aero influencer array ", new_arr);
	//uf::print("set array ", new_arr);
	aero_influencers.assign(new_arr);
	
	//example of how to get a pointer to a node in the typed array.
	// Also TypedArray operator [] will still return Variant
	// so you will need to do this weird cast to get node types
	//if(aero_influencers.size() > 0) {
	//    AeroInfluencer3D* node = (AeroInfluencer3D*) (Object*) nodes[0]; 
	//}
}

TypedArray<AeroInfluencer3D> AeroBody3D::get_aero_influencers() const { return aero_influencers; }
//void AeroBody3D::set_prediction_timestep_fraction(const double fraction) {prediction_timestep_fraction = fraction;}
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



int AeroBody3D::get_amount_of_active_influencers(){
	int count = 0;
	for (int i = 0; i < aero_influencers.size(); i++) {
		AeroInfluencer3D* influencer = (AeroInfluencer3D*) (Object*) aero_influencers[i];
		if (not influencer->is_disabled()) count += 1;
	}

	return count;
}
