#ifndef AERO_BODY_3D
#define AERO_BODY_3D

#include <godot_cpp/classes/vehicle_body3d.hpp>
#include <godot_cpp/classes/project_settings.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/physics_direct_body_state3d.hpp>
#include "aero_influencer_3d.h"

namespace godot {

class AeroInfluencer3D;//forward declaration

class AeroBody3D : public VehicleBody3D {
	GDCLASS(AeroBody3D, VehicleBody3D)
private:
	int substeps_override;
	int substeps;
	double prediction_timestep_fraction;
	TypedArray<AeroInfluencer3D> aero_influencers;
	Vector3 current_force;
	Vector3 current_torque;
	Vector3 current_gravity;
	Vector3 last_linear_velocity;
	Vector3 last_angular_velocity;
	Vector3 linear_velocity_prediction;
	Vector3 angular_velocity_prediction;
	Vector3 wind;
	Vector3 air_velocity;
	Vector3 local_air_velocity;
	Vector3 local_angular_velocity;
	double air_speed;
	double mach;
	double air_density;
	double air_pressure;
	double angle_of_attack;
	double sideslip_angle;
	double altitude;
	double bank_angle;
	double heading;
	double inclination;

	void on_enter_tree();
	void on_ready();
	void on_process(double delta) const;
	void on_physics_process(double delta) const;
	void integrate_forces(PhysicsDirectBodyState3D *body_state);
protected:
	static void _bind_methods();
	void _notification(int p_notification);
	void set_substeps(const int substeps);
	//void set_prediction_timestep_fraction(const double fraction);
	void set_aero_influencers(const TypedArray<AeroInfluencer3D> new_arr);
public:
	AeroBody3D();
	~AeroBody3D();
	void on_child_entered_tree(Node *p_node);
	void on_child_exiting_tree(Node *p_node);
	
	double substep_delta;
	void set_substeps_override(const int p_substeps);
	int get_substeps_override() const;
	//void set_substeps(const int p_substeps);
	int get_substeps() const;
	double get_prediction_timestep_fraction() const;
	TypedArray<AeroInfluencer3D> get_aero_influencers() const;
	PackedVector3Array calculate_forces(PhysicsDirectBodyState3D *body_state);
	Vector3 get_current_force() const;
	Vector3 get_current_torque() const;
	Vector3 get_current_gravity() const;
	Vector3 get_last_linear_velocity() const;
	Vector3 get_last_angular_velocity() const;
	Vector3 get_wind() const;
	Vector3 get_air_velocity() const;
	Vector3 get_local_air_velocity() const;
	Vector3 get_local_angular_velocity() const;
	double get_air_speed() const;
	double get_mach() const;
	double get_air_density() const;
	double get_air_pressure() const;
	double get_angle_of_attack() const;
	double get_sideslip_angle() const;
	double get_altitude() const;
	double get_bank_angle() const;
	double get_heading() const;
	double get_inclination() const;


	Vector3 predict_linear_velocity(Vector3 force);
	Vector3 predict_angular_velocity(Vector3 torque);
	PackedVector3Array calculate_aerodynamic_forces(Vector3 linear_velocity, Vector3 angular_velocity, double air_density, double substep_delta);

	int get_amount_of_active_influencers();
	Vector3 get_relative_position();
	Vector3 get_linear_velocity();
	Vector3 get_angular_velocity();
	Vector3 get_linear_acceleration();
	Vector3 get_angular_acceleration();
};

}

#endif