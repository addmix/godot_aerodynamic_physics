#ifndef AERO_BODY_3D
#define AERO_BODY_3D

#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/templates/vector.hpp>
#include <vector>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/vehicle_body3d.hpp>
#include <godot_cpp/classes/area3d.hpp>
#include <godot_cpp/classes/project_settings.hpp>
#include <godot_cpp/variant/callable.hpp>
#include <godot_cpp/variant/callable_method_pointer.hpp>
#include <godot_cpp/core/memory.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/physics_direct_body_state3d.hpp>
#include "aero_influencer_3d/aero_influencer_3d.h"
#include "aero_units/aero_units.h"


// TODO
// TODO - Go through and set const in relevant places
// TODO

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
	ForceAndTorque& operator/=(float divisor) {
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

	//exports and config properties
	int substeps_override = -1;
	static int substeps;
	int current_substep = 0;
	//experimental_energy_tracking


	//debug
	
	//debug visibility
	bool show_debug = false;
	bool update_debug = true;
	bool show_wing_debug_vectors = true;
	bool show_lift = true;
	bool show_drag = true;
	bool show_torque = false;
	bool show_linear_velocity = true;
	bool show_angular_velocity = true;
	bool show_center_of_lift = true;
	bool show_center_of_drag = true;
	bool show_center_of_mass = true;
	bool show_center_of_thrust = true;
	
	//debug options
	Vector3 debug_linear_velocity = Vector3(0, -10, -100);
	Vector3 debug_angular_velocity = Vector3();
	double debug_scale = 0.1;
	double debug_scaling_factor = 2.0;
	double debug_width = 0.3;
	double debug_influencer_width = 0.1;
	double debug_center_width = 0.4;

	////std::vector<AeroInfluencer3D*>
	std::vector<AeroInfluencer3D*> aero_influencers; //pointer list, so the substep loops don't box Variants
	//aero_surfaces
	Vector3 current_force = Vector3(0, 0, 0);
	Vector3 current_torque = Vector3(0, 0, 0);
	Vector3 current_gravity = Vector3(0, 0, 0);
	Vector3 last_linear_velocity = Vector3(0, 0, 0);
	Vector3 last_angular_velocity = Vector3(0, 0, 0);
	Vector3 uncommitted_last_linear_velocity = Vector3(0, 0, 0);
	Vector3 uncommitted_last_angular_velocity = Vector3(0, 0, 0);
	Vector3 linear_acceleration = Vector3(0, 0, 0);
	Vector3 angular_acceleration = Vector3(0, 0, 0);
	Vector3 linear_velocity_substep = Vector3(0, 0, 0);
	Vector3 angular_velocity_substep = Vector3(0, 0, 0);
	
	Vector3 wind = Vector3(0, 0, 0);
	Transform3D global_transform_cache = Transform3D();
	Vector3 air_velocity = Vector3(0, 0, 0);
	Vector3 local_air_velocity = Vector3(0, 0, 0);
	Vector3 local_angular_velocity = Vector3(0, 0, 0);
	double air_speed = 0;
	double mach = 0;
	double altitude = 0;
	double air_density = 1.225;
	double air_pressure = 101325.0;

	Vector3 relative_position = Vector3();
	Vector3 drag_direction = Vector3();

	double angle_of_attack = 0;
	double sideslip_angle = 0;
	double bank_angle = 0;
	double heading = 0;
	double inclination = 0;

	////std::vector<AeroAtmosphere3D*>
	std::vector<Area3D*> atmosphere_areas;

	
	Node3D *linear_velocity_vector = nullptr;
	Node3D *angular_velocity_vector = nullptr;

	Node3D *force_debug_vector = nullptr;
	Node3D *torque_debug_vector = nullptr;
	Node3D *lift_debug_vector = nullptr;
	Node3D *drag_debug_vector = nullptr;

	Node3D *mass_debug_point = nullptr;
	Node3D *thrust_debug_vector = nullptr;
protected:
	
public:
	//init/deinit, and godot virtual overrides.
	static void _bind_methods();
	static void initialize_substeps();
	static void finalize_substeps();
	static void refresh_substeps();
	AeroBody3D();
	~AeroBody3D();
	
	void _ready() override;
	void _enter_tree() override;
	void _physics_process(double delta) override;
	PackedStringArray _get_configuration_warnings() const override;
	void integrate_forces(PhysicsDirectBodyState3D *body_state);

	
	ForceAndTorque calculate_forces(double delta);
	void _update_transform_substep(double substep_delta);
	Vector3 calculate_relative_position() const;
	Vector3 calculate_drag_direction() const;
	//Vector3 calculate_linear_acceleration() const;
	//Vector3 calculate_angular_acceleration() const;
	Vector3 calculate_linear_velocity_substep(Vector3 force) const;
	Vector3 calculate_angular_velocity_substep(Vector3 torque) const;
	
	double get_control_command(StringName axis_name); //unimplemented
	bool is_overriding_body_sleep() const; //unimplemented
	void interrupt_sleep();
	
	TypedArray<AeroInfluencer3D> get_aero_influencers() const;
	TypedArray<Area3D> get_atmosphere_areas() const;
	const std::vector<Area3D*> &get_atmosphere_areas_internal() const;

	void add_aero_influencer(AeroInfluencer3D* influencer);
	void remove_aero_influencer(AeroInfluencer3D* influencer);

	void add_aero_atmosphere(Area3D* atmosphere);
	void remove_aero_atmosphere(Area3D* atmosphere);
	
	

	


	//setters and getters




	void set_substeps_override(int p_substeps);
	int get_substeps_override() const;
	int get_substeps() const;

	void refresh_transform_cache();
	const Transform3D &get_cached_global_transform() const;
	Basis get_cached_global_basis() const;
	double get_prediction_timestep_fraction() const;
	double get_substep_delta() const;
	int get_current_substep() const;
	//experimental_energy_tracking


	int get_amount_of_active_influencers() const;
	Vector3 get_relative_position() const;
	Vector3 get_drag_direction() const;
	Vector3 get_linear_velocity_substep() const;
	Vector3 get_angular_velocity_substep() const;
	Vector3 get_linear_acceleration() const;
	Vector3 get_angular_acceleration() const;

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

	//debug
	void _update_debug();
	void _update_debug_visibility();
	void _update_debug_scale();

	void set_show_debug(bool value);
	bool get_show_debug() const;

	void set_update_debug(bool value);
	bool get_update_debug() const;

	void set_show_wing_debug_vectors(bool value);
	bool get_show_wing_debug_vectors() const;

	void set_show_lift_vectors(bool value);
	bool get_show_lift_vectors() const;

	void set_show_drag_vectors(bool value);
	bool get_show_drag_vectors() const;

	void set_show_torque(bool value);
	bool get_show_torque() const;

	void set_show_linear_velocity(bool value);
	bool get_show_linear_velocity() const;

	void set_show_angular_velocity(bool value);
	bool get_show_angular_velocity() const;

	void set_show_center_of_lift(bool value);
	bool get_show_center_of_lift() const;

	void set_show_center_of_drag(bool value);
	bool get_show_center_of_drag() const;

	void set_show_center_of_mass(bool value);
	bool get_show_center_of_mass() const;

	void set_show_center_of_thrust(bool value);
	bool get_show_center_of_thrust() const;
	
	//debug options
	void set_debug_linear_velocity(Vector3 value);
	Vector3 get_debug_linear_velocity() const;

	void set_debug_angular_velocity(Vector3 value);
	Vector3 get_debug_angular_velocity() const;

	void set_debug_scale(double value);
	double get_debug_scale() const;

	void set_debug_width(double value);
	double get_debug_width() const;

	void set_debug_scaling_factor(double value);
	double get_debug_scaling_factor() const;

	void set_influencer_debug_width(double value);
	double get_influencer_debug_width() const;

	void set_debug_center_width(double value);
	double get_debug_center_width() const;








	
};

}

#endif