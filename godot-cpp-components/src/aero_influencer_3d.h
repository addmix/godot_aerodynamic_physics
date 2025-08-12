#ifndef AERO_INFLUENCER_3D
#define AERO_INFLUENCER_3D

#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/core/gdvirtual.gen.inc>
#include "aero_body_3d.h"

namespace godot {

class AeroBody3D; //forward declaraction

class AeroInfluencer3D : public Node3D {
	GDCLASS(AeroInfluencer3D, Node3D)
private:
	bool disabled;
	
	bool enable_automatic_control;
	Vector3 control_command;
	double throttle_command;
	double brake_command;
	Vector3 max_actuation;
	Vector3 pitch_contribution;
	Vector3 yaw_contribution;
	Vector3 roll_contribution;
	Vector3 brake_contribution;

	bool show_debug;
	bool omit_from_debug;
	double debug_scale;
	double debug_width;
	
	bool show_force;
	bool show_torque;

	AeroBody3D *aero_body;
	TypedArray<AeroInfluencer3D> aero_influencers;

	bool override_body_sleep;

	Transform3D default_transform;
	Vector3 world_air_velocity;
	Vector3 linear_velocity;
	Vector3 angular_velocity;
	Vector3 last_linear_velocity;
	Vector3 last_angular_velocity;
	double air_density;
	Vector3 relative_position;
	double altitude;

	Vector3 local_air_velocity;
	double air_speed;

	double mach;
	double dynamic_pressure;

	Vector3 _current_force;
	Vector3 _current_torque;

	//force_debug_vector : AeroDebugVector3D
	//torque_debug_vector : AeroDebugVector3D

	void on_enter_tree();
	void on_ready();
	void on_process(double delta);
	void on_physics_process(double delta);

	
protected:
	static void _bind_methods();
	void _notification(int p_notification);

	GDVIRTUAL1R(PackedVector3Array, _calculate_forces, double);
public:
	AeroInfluencer3D();
	~AeroInfluencer3D();

	//void _init();
	//void _enter_tree();
	void on_child_enter_tree(const Node node);
	void on_child_exit_tree(const Node node);
	//void _physics_process(const double delta);
	PackedVector3Array calculate_forces_with_override(double substep_delta);
	PackedVector3Array calculate_forces(double substep_delta);
	void _update_transform_substep(double substep_delta);
	void _update_control_transform(double substep_delta);
	void set_overriding_body_sleep(bool override);
	bool is_overriding_body_sleep();
	void set_void(Vector3 value);
	Vector3 get_relative_position();
	Vector3 get_world_air_velocity();
	Vector3 get_linear_velocity();
	Vector3 get_angular_velocity();
	Vector3 get_centrifugal_offset();
	Vector3 get_linear_acceleration();
	Vector3 get_angular_acceleration();
	void update_debug_visibility();
	void update_debug_scale();
	void update_debug_vectors();

	void set_disabled(const int p_substeps);
	int is_disabled() const;
	void set_enable_automatic_control(const bool p_enable_automatic_control);
	bool get_enable_automatic_control() const;
	void set_control_command(const Vector3 p_control_command);
	Vector3 get_control_command() const;
	Vector3 get_current_force();
	void set_current_force(Vector3 force);
	Vector3 get_current_torque();
	void set_current_torque(Vector3 torque);
	
	void set_throttle_command(const double p_throttle_command);
	double get_throttle_command() const;
	void set_brake_command(const double p_brake_command);
	double get_brake_command() const;
	void set_max_actuation(const Vector3 p_max_actuation);
	Vector3 get_max_actuation() const;
	void set_pitch_contribution(const Vector3 p_pitch_contribution);
	Vector3 get_pitch_contribution() const;
	void set_yaw_contribution(const Vector3 p_yaw_contribution);
	Vector3 get_yaw_contribution() const;
	void set_roll_contribution(const Vector3 p_roll_contribution);
	Vector3 get_roll_contribution() const;
	void set_brake_contribution(const Vector3 p_brake_contribution);
	Vector3 get_brake_contribution() const;
	void set_aero_body(AeroBody3D *new_body);
	void set_aero_influencers(const TypedArray<AeroInfluencer3D> new_arr);
	TypedArray<AeroInfluencer3D> get_aero_influencers() const;
	double get_dynamic_pressure();
	double get_mach();
	double get_air_speed();

	void on_child_entered_tree(const Variant &node);
	void on_child_exiting_tree(const Variant &node);
};

}

#endif