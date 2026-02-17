#include "manual_aero_surface_config.h"

using namespace godot;

void ManualAeroSurfaceConfig::_bind_methods() {
    ClassDB::bind_method(D_METHOD("get_lift_coefficient", "angle_of_attack"), &ManualAeroSurfaceConfig::get_lift_coefficient);
    ClassDB::bind_method(D_METHOD("get_drag_coefficient", "angle_of_attack"), &ManualAeroSurfaceConfig::get_drag_coefficient);

    ClassDB::bind_method(D_METHOD("set_min_lift_coefficient", "value"), &ManualAeroSurfaceConfig::set_min_lift_coefficient);
	ClassDB::bind_method(D_METHOD("get_min_lift_coefficient"), &ManualAeroSurfaceConfig::get_min_lift_coefficient);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "min_lift_coefficient"), "set_min_lift_coefficient", "get_min_lift_coefficient");
    ClassDB::bind_method(D_METHOD("set_max_lift_coefficient", "value"), &ManualAeroSurfaceConfig::set_max_lift_coefficient);
	ClassDB::bind_method(D_METHOD("get_max_lift_coefficient"), &ManualAeroSurfaceConfig::get_max_lift_coefficient);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "max_lift_coefficient"), "set_max_lift_coefficient", "get_max_lift_coefficient");
    ClassDB::bind_method(D_METHOD("set_lift_aoa_curve", "p_config"), &ManualAeroSurfaceConfig::set_lift_aoa_curve);
	ClassDB::bind_method(D_METHOD("get_lift_aoa_curve"), &ManualAeroSurfaceConfig::get_lift_aoa_curve);
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "lift_aoa_curve", PROPERTY_HINT_RESOURCE_TYPE, "AeroInfluencerControlConfig"), "set_lift_aoa_curve", "get_lift_aoa_curve");

    ClassDB::bind_method(D_METHOD("set_min_drag_coefficient", "value"), &ManualAeroSurfaceConfig::set_min_drag_coefficient);
	ClassDB::bind_method(D_METHOD("get_min_drag_coefficient"), &ManualAeroSurfaceConfig::get_min_drag_coefficient);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "min_drag_coefficient"), "set_min_drag_coefficient", "get_min_drag_coefficient");
    ClassDB::bind_method(D_METHOD("set_max_drag_coefficient", "value"), &ManualAeroSurfaceConfig::set_max_drag_coefficient);
	ClassDB::bind_method(D_METHOD("get_max_drag_coefficient"), &ManualAeroSurfaceConfig::get_max_drag_coefficient);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "max_drag_coefficient"), "set_max_drag_coefficient", "get_max_drag_coefficient");
    ClassDB::bind_method(D_METHOD("set_drag_aoa_curve", "p_config"), &ManualAeroSurfaceConfig::set_drag_aoa_curve);
	ClassDB::bind_method(D_METHOD("get_drag_aoa_curve"), &ManualAeroSurfaceConfig::get_drag_aoa_curve);
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "drag_aoa_curve", PROPERTY_HINT_RESOURCE_TYPE, "AeroInfluencerControlConfig"), "set_drag_aoa_curve", "get_drag_aoa_curve");

    ClassDB::bind_method(D_METHOD("set_sweep_drag_multiplier_curve", "p_config"), &ManualAeroSurfaceConfig::set_sweep_drag_multiplier_curve);
	ClassDB::bind_method(D_METHOD("get_sweep_drag_multiplier_curve"), &ManualAeroSurfaceConfig::get_sweep_drag_multiplier_curve);
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "sweep_drag_multiplier_curve", PROPERTY_HINT_RESOURCE_TYPE, "AeroInfluencerControlConfig"), "set_sweep_drag_multiplier_curve", "get_sweep_drag_multiplier_curve");

    ClassDB::bind_method(D_METHOD("set_drag_at_mach_multiplier_curve", "p_config"), &ManualAeroSurfaceConfig::set_drag_at_mach_multiplier_curve);
	ClassDB::bind_method(D_METHOD("get_drag_at_mach_multiplier_curve"), &ManualAeroSurfaceConfig::get_drag_at_mach_multiplier_curve);
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "drag_at_mach_multiplier_curve", PROPERTY_HINT_RESOURCE_TYPE, "AeroInfluencerControlConfig"), "set_drag_at_mach_multiplier_curve", "get_drag_at_mach_multiplier_curve");
}

ManualAeroSurfaceConfig::ManualAeroSurfaceConfig() {}
ManualAeroSurfaceConfig::~ManualAeroSurfaceConfig() {}

double ManualAeroSurfaceConfig::get_lift_coefficient(double angle_of_attack) {
    double sample = lift_aoa_curve->sample_baked(UtilityFunctions::remap(angle_of_attack, -Math_PI, Math_PI, lift_aoa_curve->get_min_domain(), lift_aoa_curve->get_max_domain()));
    
    if (sample >= 0.0) {
        sample *= max_lift_coefficient / lift_aoa_curve->get_max_value();
    }
    else {
        sample *= abs(min_lift_coefficient / lift_aoa_curve->get_min_value());
    }

    return sample;
}
double ManualAeroSurfaceConfig::get_drag_coefficient(double angle_of_attack) {
    double sample = drag_aoa_curve->sample_baked(UtilityFunctions::remap(angle_of_attack, -Math_PI, Math_PI, drag_aoa_curve->get_min_domain(), drag_aoa_curve->get_max_domain()));
    
    if (sample >= 0.0) {
        sample *= max_drag_coefficient / drag_aoa_curve->get_max_value();
    }
    else {
        sample *= abs(min_drag_coefficient / drag_aoa_curve->get_min_value());
    }

    return sample;
}



void ManualAeroSurfaceConfig::set_min_lift_coefficient(double value) {min_lift_coefficient = value;}
double ManualAeroSurfaceConfig::get_min_lift_coefficient() {return min_lift_coefficient;}
void ManualAeroSurfaceConfig::set_max_lift_coefficient(double value) {max_lift_coefficient = value;}
double ManualAeroSurfaceConfig::get_max_lift_coefficient() {return max_lift_coefficient;}

void ManualAeroSurfaceConfig::set_lift_aoa_curve(const Ref<Curve> &p_curve) {lift_aoa_curve = p_curve;}
Ref<Curve> ManualAeroSurfaceConfig::get_lift_aoa_curve() {return lift_aoa_curve;}

void ManualAeroSurfaceConfig::set_min_drag_coefficient(double value) {min_drag_coefficient = value;}
double ManualAeroSurfaceConfig::get_min_drag_coefficient() {return min_drag_coefficient;}
void ManualAeroSurfaceConfig::set_max_drag_coefficient(double value) {max_drag_coefficient = value;}
double ManualAeroSurfaceConfig::get_max_drag_coefficient() {return max_drag_coefficient;}

void ManualAeroSurfaceConfig::set_drag_aoa_curve(const Ref<Curve> &p_curve) {drag_aoa_curve = p_curve;}
Ref<Curve> ManualAeroSurfaceConfig::get_drag_aoa_curve() {return drag_aoa_curve;}

void ManualAeroSurfaceConfig::set_sweep_drag_multiplier_curve(const Ref<Curve> &p_curve) {sweep_drag_multiplier_curve = p_curve; }
Ref<Curve> ManualAeroSurfaceConfig::get_sweep_drag_multiplier_curve() {return sweep_drag_multiplier_curve;}
double ManualAeroSurfaceConfig::get_drag_at_sweep_angle(double sweep_angle) {
    return sweep_drag_multiplier_curve->sample_baked(UtilityFunctions::abs(UtilityFunctions::remap(sweep_angle, 0.0, Math_PI, sweep_drag_multiplier_curve->get_min_domain(), sweep_drag_multiplier_curve->get_max_domain())));
}
void ManualAeroSurfaceConfig::set_drag_at_mach_multiplier_curve(const Ref<Curve> &p_curve) {drag_at_mach_multiplier_curve = p_curve;}
Ref<Curve> ManualAeroSurfaceConfig::get_drag_at_mach_multiplier_curve() {return drag_at_mach_multiplier_curve;}
double ManualAeroSurfaceConfig::get_drag_multiplier_at_mach(double mach) {
    return drag_at_mach_multiplier_curve->sample_baked(mach);
}