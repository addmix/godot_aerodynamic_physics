#ifndef AERO_INFLUENCER_3D
#define AERO_INFLUENCER_3D

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <vector>
#include <godot_cpp/core/gdvirtual.gen.inc>
#include <godot_cpp/variant/utility_functions.hpp>
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
	
	int64_t mirror_id = 0;
	int mirror_axis = 0;
	int mirror_scaling_fix_axis = 0;
	bool _duplicate = false;
	AeroInfluencer3D* mirror_duplicate = nullptr;
	//set while the simulator itself writes transforms, so those writes don't raise flight_model_changed
	bool suppress_flight_model_changed = false;
	
	Ref<Resource> actuation_config;//AeroInfluencerControlConfig actuation_config; //TODO
	int control_rotation_order = 0;
	
	bool omit_from_debug = false;
	double debug_scale = 0.1;
	double debug_scaling_factor = 2.0;
	double debug_width = 0.1;
	bool show_debug = false;
	
	bool show_force = true;
	bool show_torque = false;
	bool show_lift = true;
	bool show_drag = true;
	bool show_thrust = false;
	
	AeroBody3D *aero_body = nullptr;
	AeroInfluencer3D *parent_influencer = nullptr;
	std::vector<AeroInfluencer3D*> aero_influencers;
	
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

protected:
	Vector3 current_force;
	Vector3 current_torque;
private:
	
	Node3D *force_debug_vector = nullptr;
	Node3D *torque_debug_vector = nullptr;
	Node3D *lift_debug_vector = nullptr;
	Node3D *drag_debug_vector = nullptr;
	Node3D *thrust_debug_vector = nullptr;
	
	Transform3D last_transform = Transform3D();
	
	bool calculate_forces_overridden = false;
	bool update_transform_substep_overridden = false;
	bool update_control_transform_overridden = false;
	bool linear_velocity_substep_overridden = false;
	bool angular_velocity_substep_overridden = false;
	bool body_sleep_overridden = false;
	bool in_body_sleep_override = false;
	
	Transform3D local_transform_cache = Transform3D();
	Transform3D global_transform_cache = Transform3D();
public:
	//functions, init, deinint, overrides, etc
	static void _bind_methods(); //_init(), kinda
	AeroInfluencer3D(); //_init()
	~AeroInfluencer3D(); //deinit
	virtual void _notification(int what);
	
	GDVIRTUAL1R(PackedVector3Array, _calculate_forces, double);
	
	void _ready() override;
	void refresh_virtual_override_cache();
	void _enter_tree() override;
	void _exit_tree() override;
	void _physics_process(double delta) override;
	
	void generate_mirror();
	void update_mirror_transform();
	void notify_flight_model_changed();
	void set_suppress_flight_model_changed(bool p_suppress);
	bool get_suppress_flight_model_changed() const;
	void set_mirror_id(int64_t p_id);
	int64_t get_mirror_id() const;
	Transform3D calculate_mirrored_transform(const Transform3D &p_transform) const;
	
	bool is_mirrored() const;
	bool is_mirror_pending() const;
	static void map_mirror_sources(AeroInfluencer3D *p_source, AeroInfluencer3D *p_mirror);
	static int64_t new_mirror_id();
	AeroInfluencer3D *get_sibling_mirror(int64_t p_id) const;
	void adopt_mirror(AeroInfluencer3D *p_copy);
	static void set_owner_recursive(Node *p_node, Node *p_owner);
	
	
	ForceAndTorque calculate_forces_with_override(double substep_delta);
	virtual ForceAndTorque calculate_forces(double substep_delta);
	void _update_transform_substep(double substep_delta);
	GDVIRTUAL1(_update_transform_substep, double);
	void _update_transform_substep_with_override(double substep_delta);
	void _update_control_transform(double substep_delta);
	GDVIRTUAL1(_update_control_transform, double);
	void _update_control_transform_with_override(double substep_delta);
	bool is_overriding_body_sleep() const;
	GDVIRTUAL0R(bool, is_overriding_body_sleep);
	bool is_overriding_body_sleep_with_override();
	
	Vector3 calculate_relative_position() const;
	Vector3 calculate_world_air_velocity() const;
	Vector3 calculate_linear_velocity_substep() const;
	GDVIRTUAL0R(Vector3, calculate_linear_velocity_substep);
	Vector3 calculate_linear_velocity_substep_with_override();
	Vector3 calculate_angular_velocity_substep() const;
	GDVIRTUAL0R(Vector3, calculate_angular_velocity_substep);
	Vector3 calculate_angular_velocity_substep_with_override();
	Vector3 calculate_centrifugal_offset();
	Vector3 calculate_linear_acceleration();
	Vector3 calculate_angular_acceleration() const;
	
	double get_control_command(StringName axis_name);
	
	void update_debug_vectors();
	
	void update_transform_cache(const Transform3D &parent_global_transform);
	void set_cached_transform(const Transform3D &p_transform);
	
	const Transform3D &get_cached_local_transform() const;
	const Transform3D &get_cached_global_transform() const;
	Basis get_cached_global_basis() const;
	Vector3 get_cached_position() const;
	
	
	
	//setters and getters
	void set_disabled(int p_disabled);
	int is_disabled() const;
	
	void set_can_override_body_sleep(bool override);
	bool get_can_override_body_sleep() const;
	
	void set_mirror_axis(int axis);
	int get_mirror_axis() const;
	void set_mirror_scaling_fix_axis(int axis);
	int get_mirror_scaling_fix_axis() const;
	void set_duplicate(bool value);
	bool is_duplicate() const;
	AeroInfluencer3D* get_mirror_duplicate() const;
	
	void set_actuation_config(const Ref<Resource> &p_config);
	void watch_config_resource(const Ref<Resource> &p_previous, const Ref<Resource> &p_next);
	Ref<Resource> get_actuation_config() const;
	void set_control_rotation_order(int rotation_order);
	int get_control_rotation_order() const;
	
	void update_debug_visibility();
	GDVIRTUAL0(update_debug_visibility);
	void set_omit_from_debug(bool omit);
	bool is_omitted_from_debug() const;
	void set_debug_scale(double value);
	double get_debug_scale() const;
	void set_debug_scaling_factor(double scaling_factor);
	double get_debug_scaling_factor() const;
	void set_debug_width(double value);
	double get_debug_width() const;
	void set_show_debug(bool value);
	bool get_show_debug() const;
	
	void set_show_force(bool show);
	bool get_show_force() const;
	void set_show_torque(bool show);
	bool get_show_torque() const;
	void set_show_lift(bool show);
	bool get_show_lift() const;
	void set_show_drag(bool show);
	bool get_show_drag() const;
	void set_show_thrust(bool show);
	bool get_show_thrust() const;
	
	void set_aero_body(AeroBody3D* new_body);
	AeroBody3D* get_aero_body() const;
	void set_aero_influencers(const TypedArray<AeroInfluencer3D> &new_arr);
	TypedArray<AeroInfluencer3D> get_aero_influencers() const;
	
	void set_default_transform(Transform3D new_transform);
	Transform3D get_default_transform() const;
	double get_altitude() const;
	double get_air_density() const;
	Vector3 get_relative_position() const;
	Vector3 get_linear_velocity_substep() const;
	Vector3 get_angular_velocity_substep() const;
	Vector3 get_local_air_velocity() const;
	Vector3 get_world_air_velocity() const;
	Vector3 get_drag_direction() const;
	double get_air_speed() const;
	double get_mach() const;
	double get_dynamic_pressure() const;
	Vector3 get_centrifugal_offset();
	GDVIRTUAL0R(Vector3, get_centrifugal_offset);
	Vector3 get_linear_acceleration();
	Vector3 get_angular_acceleration() const;
	Vector3 get_current_force() const;
	Vector3 get_current_torque() const;
};

}

#endif