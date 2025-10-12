#ifndef AERO_BODY_3D
#define AERO_BODY_3D

#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/gd_script.hpp>
#include <godot_cpp/classes/vehicle_body3d.hpp>
#include <godot_cpp/classes/project_settings.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/physics_direct_body_state3d.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
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

	void integrate_forces(PhysicsDirectBodyState3D *body_state);
	

	//debug //unimplemented
	
	//debug visibility
	bool show_debug;
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
	Vector3 debug_linear_velocity = Vector3(0, -10, -100);
	Vector3 debug_angular_velocity = Vector3();
	double debug_scale = 1.0;
	double debug_width = 0.1;
	double debug_center_width = 0.2;

	Ref<GDScript> point_3d_script;
	Ref<GDScript> vector_3d_script;
	Node3D *linear_velocity_vector;
	Node3D *angular_velocity_vector;

protected:
	static void _bind_methods();
	void set_substeps(const int substeps);
	void set_aero_influencers(const TypedArray<AeroInfluencer3D> new_arr);
public:
	//init/deinit, and godot virtual overrides.
	AeroBody3D();
	~AeroBody3D();
	void on_child_entered_tree(Node *p_node);
	void on_child_exiting_tree(Node *p_node);
	
	void _ready() override;
	void _enter_tree() override;
	//void _exit_tree() override;
	void _process(double delta) override;
	void _physics_process(double delta) override;
	//PackedStringArray _get_configuration_warnings() const override;

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

	Vector3 predict_linear_velocity(const Vector3 force);
	Vector3 predict_angular_velocity(const Vector3 torque);
	PackedVector3Array calculate_aerodynamic_forces(double substep_delta);

	int get_amount_of_active_influencers();
	Vector3 get_relative_position();
	Vector3 get_linear_velocity();
	Vector3 get_angular_velocity();
	Vector3 get_linear_acceleration();
	Vector3 get_angular_acceleration();

	double get_control_command(const StringName axis_name); //unimplemented
	bool is_overriding_body_sleep() const; //unimplemented
	void interrupt_sleep() const;


	//debug
	void _update_debug();

	void set_show_debug(const bool value);
	bool get_show_debug() const;

	void set_update_debug(const bool value);
	bool get_update_debug() const;

	void set_show_wing_debug_vectors(const bool value);
	bool get_show_wing_debug_vectors() const;

	void set_show_lift_vectors(const bool value);
	bool get_show_lift_vectors() const;

	void set_show_drag_vectors(const bool value);
	bool get_show_drag_vectors() const;

	void set_show_linear_velocity(const bool value);
	bool get_show_linear_velocity() const;

	void set_show_angular_velocity(const bool value);
	bool get_show_angular_velocity() const;

	void set_show_center_of_lift(const bool value);
	bool get_show_center_of_lift() const;

	void set_show_center_of_drag(const bool value);
	bool get_show_center_of_drag() const;

	void set_show_center_of_mass(const bool value);
	bool get_show_center_of_mass() const;

	void set_show_center_of_thrust(const bool value);
	bool get_show_center_of_thrust() const;
	
	//debug options
	void set_debug_linear_velocity(const Vector3 value);
	Vector3 get_debug_linear_velocity() const;

	void set_debug_angular_velocity(const Vector3 value);
	Vector3 get_debug_angular_velocity() const;

	void set_debug_scale(const double value);
	double get_debug_scale() const;

	void set_debug_width(const double value);
	double get_debug_width() const;

	void set_debug_center_width(const double value);
	double get_debug_center_width() const;
};

}

#endif