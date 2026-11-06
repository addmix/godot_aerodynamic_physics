#include "manual_aero_surface_config.h"

using namespace godot;

void ManualAeroSurfaceConfig::_bind_methods() {
    ClassDB::bind_method(D_METHOD("get_lift_coefficient", "angle_of_attack"), &ManualAeroSurfaceConfig::get_lift_coefficient);
    ClassDB::bind_method(D_METHOD("get_drag_coefficient", "angle_of_attack"), &ManualAeroSurfaceConfig::get_drag_coefficient);
    ClassDB::bind_method(D_METHOD("get_drag_at_sweep_angle", "sweep_angle"), &ManualAeroSurfaceConfig::get_drag_at_sweep_angle);
    ClassDB::bind_method(D_METHOD("get_drag_multiplier_at_mach", "mach"), &ManualAeroSurfaceConfig::get_drag_multiplier_at_mach);

	//ClassDB::bind_method(D_METHOD("set_min_lift_coefficient", "value"), &ManualAeroSurfaceConfig::set_min_lift_coefficient);
	//ClassDB::bind_method(D_METHOD("get_min_lift_coefficient"), &ManualAeroSurfaceConfig::get_min_lift_coefficient);
	//ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "min_lift_coefficient"), "set_min_lift_coefficient", "get_min_lift_coefficient");
	//ClassDB::bind_method(D_METHOD("set_max_lift_coefficient", "value"), &ManualAeroSurfaceConfig::set_max_lift_coefficient);
	//ClassDB::bind_method(D_METHOD("get_max_lift_coefficient"), &ManualAeroSurfaceConfig::get_max_lift_coefficient);
	//ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "max_lift_coefficient"), "set_max_lift_coefficient", "get_max_lift_coefficient");
    ClassDB::bind_method(D_METHOD("set_lift_aoa_curve", "p_config"), &ManualAeroSurfaceConfig::set_lift_aoa_curve);
	ClassDB::bind_method(D_METHOD("get_lift_aoa_curve"), &ManualAeroSurfaceConfig::get_lift_aoa_curve);
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "lift_aoa_curve", PROPERTY_HINT_RESOURCE_TYPE, "Curve"), "set_lift_aoa_curve", "get_lift_aoa_curve");

    ClassDB::bind_method(D_METHOD("set_min_drag_coefficient", "value"), &ManualAeroSurfaceConfig::set_min_drag_coefficient);
	ClassDB::bind_method(D_METHOD("get_min_drag_coefficient"), &ManualAeroSurfaceConfig::get_min_drag_coefficient);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "min_drag_coefficient", PROPERTY_HINT_RANGE, "0,100,0.001,or_greater,exp,suffix:cD"), "set_min_drag_coefficient", "get_min_drag_coefficient");
    ClassDB::bind_method(D_METHOD("set_max_drag_coefficient", "value"), &ManualAeroSurfaceConfig::set_max_drag_coefficient);
	ClassDB::bind_method(D_METHOD("get_max_drag_coefficient"), &ManualAeroSurfaceConfig::get_max_drag_coefficient);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "max_drag_coefficient", PROPERTY_HINT_RANGE, "0,100,0.001,or_greater,exp,suffix:cD"), "set_max_drag_coefficient", "get_max_drag_coefficient");
    ClassDB::bind_method(D_METHOD("set_drag_aoa_curve", "p_config"), &ManualAeroSurfaceConfig::set_drag_aoa_curve);
	ClassDB::bind_method(D_METHOD("get_drag_aoa_curve"), &ManualAeroSurfaceConfig::get_drag_aoa_curve);
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "drag_aoa_curve", PROPERTY_HINT_RESOURCE_TYPE, "Curve"), "set_drag_aoa_curve", "get_drag_aoa_curve");

    ClassDB::bind_method(D_METHOD("set_sweep_drag_multiplier_curve", "p_config"), &ManualAeroSurfaceConfig::set_sweep_drag_multiplier_curve);
	ClassDB::bind_method(D_METHOD("get_sweep_drag_multiplier_curve"), &ManualAeroSurfaceConfig::get_sweep_drag_multiplier_curve);
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "sweep_drag_multiplier_curve", PROPERTY_HINT_RESOURCE_TYPE, "Curve"), "set_sweep_drag_multiplier_curve", "get_sweep_drag_multiplier_curve");

    ClassDB::bind_method(D_METHOD("set_drag_at_mach_multiplier_curve", "p_config"), &ManualAeroSurfaceConfig::set_drag_at_mach_multiplier_curve);
	ClassDB::bind_method(D_METHOD("get_drag_at_mach_multiplier_curve"), &ManualAeroSurfaceConfig::get_drag_at_mach_multiplier_curve);
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "drag_at_mach_multiplier_curve", PROPERTY_HINT_RESOURCE_TYPE, "Curve"), "set_drag_at_mach_multiplier_curve", "get_drag_at_mach_multiplier_curve");
}

ManualAeroSurfaceConfig::ManualAeroSurfaceConfig() {}
ManualAeroSurfaceConfig::~ManualAeroSurfaceConfig() {}

void ManualAeroSurfaceConfig::_build_default_curves() const {
	if (_curves_built) return;
	_curves_built = true;

	default_lift_curve = Ref<Curve>(memnew(Curve));
	default_lift_curve->set_script(ResourceLoader::get_singleton()->load("res://addons/godot_aerodynamic_physics/core/easy_lift_curve.gd"));
	default_lift_curve->call("recalculate");

	default_drag_curve = ResourceLoader::get_singleton()->load("res://addons/godot_aerodynamic_physics/core/resources/default_drag_aoa_curve.tres")->duplicate();
	default_sweep_curve = ResourceLoader::get_singleton()->load("res://addons/godot_aerodynamic_physics/core/resources/default_sweep_drag_multiplier.tres")->duplicate();
	default_mach_curve = ResourceLoader::get_singleton()->load("res://addons/godot_aerodynamic_physics/core/resources/default_drag_at_mach_curve.tres")->duplicate();
}

double ManualAeroSurfaceConfig::get_lift_coefficient(double angle_of_attack) const {
	_build_default_curves();
	const Ref<Curve> &curve = lift_aoa_curve.is_valid() ? lift_aoa_curve : default_lift_curve;
	double sample = curve->sample_baked(Math::remap((real_t) angle_of_attack, (real_t) -Math::PI, (real_t) Math::PI, curve->get_min_domain(), curve->get_max_domain()));
	return sample;
}
double ManualAeroSurfaceConfig::get_drag_coefficient(double angle_of_attack) const {
    _build_default_curves();
    const Ref<Curve> &curve = drag_aoa_curve.is_valid() ? drag_aoa_curve : default_drag_curve;
    double sample = curve->sample_baked(Math::remap((real_t) angle_of_attack, (real_t) -Math::PI, (real_t) Math::PI, curve->get_min_domain(), curve->get_max_domain()));
    return Math::remap((real_t) sample, curve->get_min_value(), curve->get_max_value(), (real_t) min_drag_coefficient, (real_t) max_drag_coefficient);
}



//void ManualAeroSurfaceConfig::set_min_lift_coefficient(double value) {min_lift_coefficient = value;}
//double ManualAeroSurfaceConfig::get_min_lift_coefficient() {return min_lift_coefficient;}
//void ManualAeroSurfaceConfig::set_max_lift_coefficient(double value) {max_lift_coefficient = value;}
//double ManualAeroSurfaceConfig::get_max_lift_coefficient() {return max_lift_coefficient;}

void ManualAeroSurfaceConfig::set_lift_aoa_curve(const Ref<Curve> &p_curve) {lift_aoa_curve = p_curve;}
Ref<Curve> ManualAeroSurfaceConfig::get_lift_aoa_curve() const {return lift_aoa_curve;}

void ManualAeroSurfaceConfig::set_min_drag_coefficient(double value) {min_drag_coefficient = value;}
double ManualAeroSurfaceConfig::get_min_drag_coefficient() const {return min_drag_coefficient;}
void ManualAeroSurfaceConfig::set_max_drag_coefficient(double value) {max_drag_coefficient = value;}
double ManualAeroSurfaceConfig::get_max_drag_coefficient() const {return max_drag_coefficient;}

void ManualAeroSurfaceConfig::set_drag_aoa_curve(const Ref<Curve> &p_curve) {drag_aoa_curve = p_curve;}
Ref<Curve> ManualAeroSurfaceConfig::get_drag_aoa_curve() const {return drag_aoa_curve;}

void ManualAeroSurfaceConfig::set_sweep_drag_multiplier_curve(const Ref<Curve> &p_curve) {sweep_drag_multiplier_curve = p_curve; }
Ref<Curve> ManualAeroSurfaceConfig::get_sweep_drag_multiplier_curve() const {return sweep_drag_multiplier_curve;}
double ManualAeroSurfaceConfig::get_drag_at_sweep_angle(double sweep_angle) const {
    _build_default_curves();
    const Ref<Curve> &curve = sweep_drag_multiplier_curve.is_valid() ? sweep_drag_multiplier_curve : default_sweep_curve;
    return curve->sample_baked(Math::abs(Math::remap((real_t) sweep_angle, (real_t) 0.0, (real_t) Math::PI, curve->get_min_domain(), curve->get_max_domain())));
}
void ManualAeroSurfaceConfig::set_drag_at_mach_multiplier_curve(const Ref<Curve> &p_curve) {drag_at_mach_multiplier_curve = p_curve;}
Ref<Curve> ManualAeroSurfaceConfig::get_drag_at_mach_multiplier_curve() const {return drag_at_mach_multiplier_curve;}
double ManualAeroSurfaceConfig::get_drag_multiplier_at_mach(double mach) const {
    _build_default_curves();
    return (drag_at_mach_multiplier_curve.is_valid() ? drag_at_mach_multiplier_curve : default_mach_curve)->sample_baked(mach);
}