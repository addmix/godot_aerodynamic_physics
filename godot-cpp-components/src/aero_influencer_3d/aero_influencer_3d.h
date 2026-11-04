#ifndef AERO_INFLUENCER_3D
#define AERO_INFLUENCER_3D

#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/core/gdvirtual.gen.inc>
#include "aero_body_3d/aero_body_3d.h"
#include "aero_utils/aero_utils.h"

namespace godot {

struct ForceAndTorque;
class AeroBody3D; //forward declaraction

class AeroInfluencer3D : public Node3D {
	GDCLASS(AeroInfluencer3D, Node3D)
private:
	//export properties and config values
	bool disabled = false;
	bool can_override_body_sleep = true;
	
	int mirror_axis = 0;
	int mirror_scaling_fix_axis = 0;
	int _mirror_scaling_fix_axis = 0;
	bool _duplicate = false;
	AeroInfluencer3D* mirror_duplicate = nullptr;

	Ref<Resource> actuation_config;//AeroInfluencerControlConfig actuation_config; //TODO
	int control_rotation_order = 0;
	
	bool omit_from_debug = false;
	double debug_scale = 0.1;
	double debug_scaling_factor = 2.0;
	double debug_width = 0.05;
	bool show_debug = false;

	bool show_force = true;
	bool show_torque = false;
	bool show_lift = true;
	bool show_drag = true;
	bool show_thrust = false;

	//internal values (not export properties)
	AeroBody3D *aero_body = nullptr;
	//see if it's possible/probably to convert this to a native array
	//std::vector<AeroInfluencer3D*>
	TypedArray<AeroInfluencer3D> aero_influencers;

	Transform3D default_transform = Transform3D();

	double altitude = 0.0;
	double air_density = 1.225;
	Vector3 relative_position;
	Vector3 linear_velocity_substep;
	Vector3 angular_velocity_substep;
	Vector3 last_linear_velocity;
	Vector3 last_angular_velocity;
	Vector3 local_air_velocity;
	Vector3 world_air_velocity;
	Vector3 drag_direction;
	double air_speed = 0.0;
	double mach = 0.0;
	double dynamic_pressure = 0.0;

	Vector3 current_force;
	Vector3 current_torque;

	Node3D *force_debug_vector = nullptr;
	Node3D *torque_debug_vector = nullptr;
	Node3D *lift_debug_vector = nullptr;
	Node3D *drag_debug_vector = nullptr;
	Node3D *thrust_debug_vector = nullptr;

	Transform3D last_transform = Transform3D();
public:
	//functions, init, deinint, overrides, etc
	static void _bind_methods(); //_init(), kinda
	AeroInfluencer3D(); //_init()
	~AeroInfluencer3D(); //deinit
	virtual void _notification(int what);
	
	GDVIRTUAL1R(PackedVector3Array, _calculate_forces, double);
	
	void _ready() override;
	void _enter_tree() override;
	void _exit_tree() override;
	void _physics_process(double delta) override;

	void generate_mirror();

	ForceAndTorque calculate_forces_with_override(double substep_delta);
	virtual ForceAndTorque calculate_forces(double substep_delta);
	void _update_transform_substep(double substep_delta);
	GDVIRTUAL1(_update_transform_substep, double);
	void _update_control_transform(double substep_delta);
	GDVIRTUAL1(_update_control_transform, double);
	bool is_overriding_body_sleep();
	GDVIRTUAL0R(bool, is_overriding_body_sleep);

	Vector3 calculate_relative_position();
	Vector3 calculate_world_air_velocity();
	Vector3 calculate_linear_velocity_substep();
	Vector3 calculate_angular_velocity_substep();
	Vector3 calculate_centrifugal_offset();
	Vector3 calculate_linear_acceleration();
	Vector3 calculate_angular_acceleration();

	double get_control_command(StringName axis_name);
	
	void update_debug_scale();
	void update_debug_vectors();
	void update_debug();


	
	//setters and getters
	void set_disabled(const int p_disabled);
	int is_disabled() const;

	void set_can_override_body_sleep(bool override);
	bool get_can_override_body_sleep();

	void set_mirror_axis(int axis);
	int get_mirror_axis();
	void set_mirror_scaling_fix_axis(int axis);
	int get_mirror_scaling_fix_axis() const;
	void set_duplicate(const bool value);
	bool is_duplicate() const; //doesn't need setter because it is never expected to be changed outside of aeroinfluencer 
	AeroInfluencer3D* get_mirror_duplicate();
	
	void set_actuation_config(const Ref<Resource> &p_config);
	Ref<Resource> get_actuation_config() const;
	void set_control_rotation_order(int rotation_order);
	int get_control_rotation_order();
	
	void update_debug_visibility();
	GDVIRTUAL0(update_debug_visibility);
	void set_omit_from_debug(const bool omit);
	bool is_omitted_from_debug() const;
	void set_debug_scale(const double value);
	double get_debug_scale() const;
	void set_debug_scaling_factor(const double scaling_factor);
	double get_debug_scaling_factor() const;
	void set_debug_width(const double value);
	double get_debug_width() const;
	void set_show_debug(const bool value);
	bool get_show_debug() const;

	void set_show_force(bool show);
	bool get_show_force();
	void set_show_torque(bool show);
	bool get_show_torque();
	void set_show_lift(bool show);
	bool get_show_lift();
	void set_show_drag(bool show);
	bool get_show_drag();
	void set_show_thrust(bool show);
	bool get_show_thrust();

	void set_aero_body(AeroBody3D* new_body);
	AeroBody3D* get_aero_body() const;
	void set_aero_influencers(const TypedArray<AeroInfluencer3D> &new_arr);
	TypedArray<AeroInfluencer3D> get_aero_influencers() const;
	
	void set_default_transform(const Transform3D new_transform);
	Transform3D get_default_transform() const;
	double get_altitude() const;
	double get_air_density() const;
	Vector3 get_relative_position() const;
	Vector3 get_linear_velocity_substep();
	GDVIRTUAL0R(Vector3, get_linear_velocity_substep);
	Vector3 get_angular_velocity_substep();
	GDVIRTUAL0R(Vector3, get_angular_velocity_substep);
	Vector3 get_local_air_velocity() const;
	Vector3 get_world_air_velocity() const;
	Vector3 get_drag_direction() const;
	double get_air_speed() const;
	double get_mach() const;
	double get_dynamic_pressure() const;
	Vector3 get_centrifugal_offset() const;
	Vector3 get_linear_acceleration() const;
	Vector3 get_angular_acceleration() const;
	Vector3 get_current_force() const;
	Vector3 get_current_torque() const;
};

}

#endif