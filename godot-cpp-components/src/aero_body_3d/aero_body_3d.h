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
#include "aero_influencer_3d/aero_influencer_3d.h"
#include "aero_units/aero_units.h"

namespace godot {

struct ForceAndTorque {
    Vector3 force{};
    Vector3 torque{};

    ForceAndTorque() = default;
    ForceAndTorque(const Vector3& f, const Vector3& t)
        : force(f), torque(t) {}
    ForceAndTorque& operator+=(const ForceAndTorque other) {
        force += other.force;
        torque += other.torque;
        return *this;
    }
	ForceAndTorque& operator/=(const float divisor) {
		force /= divisor;
		torque /= divisor;
		return *this;
	}
	ForceAndTorque operator/(float divisor) const {
		ForceAndTorque result = *this;
		result /= divisor;
		return result;
	}
};

class AeroInfluencer3D;//forward declaration

class AeroBody3D : public VehicleBody3D {
	GDCLASS(AeroBody3D, VehicleBody3D)
private:
	int substeps_override = -1;
	int substeps = 1;
	double prediction_timestep_fraction = 1;
	TypedArray<AeroInfluencer3D> aero_influencers;
	Vector3 current_force = Vector3(0, 0, 0);
	Vector3 current_torque = Vector3(0, 0, 0);
	Vector3 current_gravity = Vector3(0, 0, 0);
	Vector3 last_linear_velocity = Vector3(0, 0, 0);
	Vector3 last_angular_velocity = Vector3(0, 0, 0);
	Vector3 linear_velocity_prediction = Vector3(0, 0, 0);
	Vector3 angular_velocity_prediction = Vector3(0, 0, 0);
	Vector3 wind = Vector3(0, 0, 0);
	Vector3 air_velocity = Vector3(0, 0, 0);
	Vector3 local_air_velocity = Vector3(0, 0, 0);
	Vector3 local_angular_velocity = Vector3(0, 0, 0);
	double air_speed = 0;
	double mach = 0;
	double air_density = 1.225;
	double air_pressure = 101325.0;
	double angle_of_attack = 0;
	double sideslip_angle = 0;
	double altitude = 0;
	double bank_angle = 0;
	double heading = 0;
	double inclination = 0;

	void integrate_forces(PhysicsDirectBodyState3D *body_state);
	

	//debug //unimplemented
	
	//debug visibility
	bool show_debug = false;
	bool update_debug = true;
	bool show_wing_debug_vectors = true;
	bool show_lift_vectors = true;
	bool show_drag_vectors = true;
	bool show_linear_velocity = true;
	bool show_angular_velocity = false;
	bool show_center_of_lift = true;
	bool show_center_of_drag = true;
	bool show_center_of_mass = true;
	bool show_center_of_thrust = true;
	
	//debug options
	Vector3 debug_linear_velocity = Vector3(0, -10, -100);
	Vector3 debug_angular_velocity = Vector3();
	double debug_scale = 1.0;
	double debug_width = 0.1;
	double debug_center_width = 0.2;

	Ref<GDScript> point_3d_script = nullptr;
	Ref<GDScript> vector_3d_script = nullptr;
	Node3D *center_of_mass_debug_point = nullptr;
	Node3D *linear_velocity_vector = nullptr;
	Node3D *angular_velocity_vector = nullptr;

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
	ForceAndTorque calculate_forces(PhysicsDirectBodyState3D *body_state);
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
	ForceAndTorque calculate_aerodynamic_forces(double substep_delta);

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