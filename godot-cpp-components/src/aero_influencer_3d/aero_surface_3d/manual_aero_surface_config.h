#ifndef MANUAL_AERO_SURFACE_CONFIG
#define MANUAL_AERO_SURFACE_CONFIG

#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/classes/curve.hpp>

namespace godot {

class ManualAeroSurfaceConfig : public Resource {
	GDCLASS(ManualAeroSurfaceConfig, Resource);
private:
    double min_lift_coefficient = -1.6;
    double max_lift_coefficient = 1.6;
    Ref<Curve> lift_aoa_curve = ResourceLoader::get_singleton()->load("res://addons/godot_aerodynamic_physics/core/resources/default_lift_aoa_curve.tres");
	double min_drag_coefficient = 0.01;
	double max_drag_coefficient = 0.8;
	Ref<Curve> drag_aoa_curve = ResourceLoader::get_singleton()->load("res://addons/godot_aerodynamic_physics/core/resources/default_drag_aoa_curve.tres");
	Ref<Curve> sweep_drag_multiplier_curve = ResourceLoader::get_singleton()->load("res://addons/godot_aerodynamic_physics/core/resources/default_sweep_drag_multiplier.tres");
	Ref<Curve> drag_at_mach_multiplier_curve = ResourceLoader::get_singleton()->load("res://addons/godot_aerodynamic_physics/core/resources/default_drag_at_mach_curve.tres");
protected:
	static void _bind_methods();
public:
	//init/deinit, and godot virtual overrides.
	ManualAeroSurfaceConfig();
	~ManualAeroSurfaceConfig();

	double get_lift_coefficient(double angle_of_attack);
	double get_drag_coefficient(double angle_of_attack);

	void set_min_lift_coefficient(double value);
	double get_min_lift_coefficient();
    void set_max_lift_coefficient(double value);
	double get_max_lift_coefficient();
    void set_lift_aoa_curve(const Ref<Curve> &p_curve);
	Ref<Curve> get_lift_aoa_curve();
	void set_min_drag_coefficient(double value);
	double get_min_drag_coefficient();
	void set_max_drag_coefficient(double value);
	double get_max_drag_coefficient();
	void set_drag_aoa_curve(const Ref<Curve> &p_curve);
	Ref<Curve> get_drag_aoa_curve();
	void set_sweep_drag_multiplier_curve(const Ref<Curve> &p_curve);
	double get_drag_at_sweep_angle(double sweep_angle);
	Ref<Curve> get_sweep_drag_multiplier_curve();
	void set_drag_at_mach_multiplier_curve(const Ref<Curve> &p_curve);
	Ref<Curve> get_drag_at_mach_multiplier_curve();
	double get_drag_multiplier_at_mach(double mach);
};

}

#endif