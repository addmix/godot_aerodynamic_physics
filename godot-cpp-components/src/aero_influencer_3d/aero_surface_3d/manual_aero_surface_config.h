#ifndef MANUAL_AERO_SURFACE_CONFIG
#define MANUAL_AERO_SURFACE_CONFIG

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/classes/curve.hpp>

namespace godot {

class ManualAeroSurfaceConfig : public Resource {
	GDCLASS(ManualAeroSurfaceConfig, Resource);
private:
	//double min_lift_coefficient = -1.6;
	//double max_lift_coefficient = 1.6;
	Ref<Curve> lift_aoa_curve;
	double min_drag_coefficient = 0.02;
	double max_drag_coefficient = 1.0;
	Ref<Curve> drag_aoa_curve;
	Ref<Curve> sweep_drag_multiplier_curve;
	Ref<Curve> drag_at_mach_multiplier_curve;

	mutable bool _curves_built = false;
	mutable Ref<Curve> default_lift_curve;
	mutable Ref<Curve> default_drag_curve;
	mutable Ref<Curve> default_sweep_curve;
	mutable Ref<Curve> default_mach_curve;
	void _build_default_curves() const;
protected:
	static void _bind_methods();
public:
	//init/deinit, and godot virtual overrides.
	ManualAeroSurfaceConfig();
	~ManualAeroSurfaceConfig();

	double get_lift_coefficient(double angle_of_attack) const;
	double get_drag_coefficient(double angle_of_attack) const;

	//void set_min_lift_coefficient(double value);
	//double get_min_lift_coefficient();
	//void set_max_lift_coefficient(double value);
	//double get_max_lift_coefficient();
    void set_lift_aoa_curve(const Ref<Curve> &p_curve);
	Ref<Curve> get_lift_aoa_curve() const;
	void set_min_drag_coefficient(double value);
	double get_min_drag_coefficient() const;
	void set_max_drag_coefficient(double value);
	double get_max_drag_coefficient() const;
	void set_drag_aoa_curve(const Ref<Curve> &p_curve);
	Ref<Curve> get_drag_aoa_curve() const;
	void set_sweep_drag_multiplier_curve(const Ref<Curve> &p_curve);
	double get_drag_at_sweep_angle(double sweep_angle) const;
	Ref<Curve> get_sweep_drag_multiplier_curve() const;
	void set_drag_at_mach_multiplier_curve(const Ref<Curve> &p_curve);
	Ref<Curve> get_drag_at_mach_multiplier_curve() const;
	double get_drag_multiplier_at_mach(double mach) const;
};

}

#endif