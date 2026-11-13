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

void ManualAeroSurfaceConfig::apply_default_curves() const {
	if (lift_aoa_curve.is_null()) {
		Ref<Curve> curve = Ref<Curve>(memnew(Curve));
		curve->set_script(ResourceLoader::get_singleton()->load("res://addons/godot_aerodynamic_physics/core/easy_lift_curve.gd"));
		curve->call("recalculate");
		lift_aoa_curve = curve;
	}
	
	if (drag_aoa_curve.is_null()) drag_aoa_curve = ResourceLoader::get_singleton()->load("res://addons/godot_aerodynamic_physics/core/resources/default_drag_aoa_curve.tres")->duplicate();
	if (sweep_drag_multiplier_curve.is_null()) sweep_drag_multiplier_curve = ResourceLoader::get_singleton()->load("res://addons/godot_aerodynamic_physics/core/resources/default_sweep_drag_multiplier.tres")->duplicate();
	if (drag_at_mach_multiplier_curve.is_null()) drag_at_mach_multiplier_curve = ResourceLoader::get_singleton()->load("res://addons/godot_aerodynamic_physics/core/resources/default_drag_at_mach_curve.tres")->duplicate();
	
	if (not curves_watched) {
		//defaults are assigned lazily from const getters, so the change watch has to be installed through a const_cast
		ManualAeroSurfaceConfig *self = const_cast<ManualAeroSurfaceConfig *>(this);
		watch_curve(self, Ref<Curve>(), lift_aoa_curve);
		watch_curve(self, Ref<Curve>(), drag_aoa_curve);
		watch_curve(self, Ref<Curve>(), sweep_drag_multiplier_curve);
		watch_curve(self, Ref<Curve>(), drag_at_mach_multiplier_curve);
		curves_watched = true;
	}
}

double ManualAeroSurfaceConfig::get_lift_coefficient(double angle_of_attack) const {
	apply_default_curves();
	double sample = lift_aoa_curve->sample_baked(Math::remap((real_t) angle_of_attack, (real_t) -Math::PI, (real_t) Math::PI, lift_aoa_curve->get_min_domain(), lift_aoa_curve->get_max_domain()));
	return sample;
}
double ManualAeroSurfaceConfig::get_drag_coefficient(double angle_of_attack) const {
    apply_default_curves();
    double sample = drag_aoa_curve->sample_baked(Math::remap((real_t) angle_of_attack, (real_t) -Math::PI, (real_t) Math::PI, drag_aoa_curve->get_min_domain(), drag_aoa_curve->get_max_domain()));
    return Math::remap((real_t) sample, drag_aoa_curve->get_min_value(), drag_aoa_curve->get_max_value(), (real_t) min_drag_coefficient, (real_t) max_drag_coefficient);
}



//void ManualAeroSurfaceConfig::set_min_lift_coefficient(double value) {min_lift_coefficient = value;}
//double ManualAeroSurfaceConfig::get_min_lift_coefficient() {return min_lift_coefficient;}
//void ManualAeroSurfaceConfig::set_max_lift_coefficient(double value) {max_lift_coefficient = value;}
//double ManualAeroSurfaceConfig::get_max_lift_coefficient() {return max_lift_coefficient;}

void ManualAeroSurfaceConfig::watch_curve(ManualAeroSurfaceConfig *p_config, const Ref<Curve> &p_previous, const Ref<Curve> &p_next) {
	if (not p_config) return;
	
	Callable callback(p_config, "emit_changed");
	
	if (p_previous.is_valid() and p_previous != p_next and p_previous->is_connected("changed", callback)) {
		p_previous->disconnect("changed", callback);
	}
	if (p_next.is_valid() and not p_next->is_connected("changed", callback)) {
		p_next->connect("changed", callback);
	}
}
void ManualAeroSurfaceConfig::set_lift_aoa_curve(const Ref<Curve> &p_curve) {
	if (lift_aoa_curve == p_curve) return;
	
	watch_curve(this, lift_aoa_curve, p_curve);
	lift_aoa_curve = p_curve;
	emit_changed();
}
Ref<Curve> ManualAeroSurfaceConfig::get_lift_aoa_curve() const {return lift_aoa_curve;}

void ManualAeroSurfaceConfig::set_min_drag_coefficient(double value) {
	if (min_drag_coefficient == value) return;
	
	min_drag_coefficient = value;
	emit_changed();
}
double ManualAeroSurfaceConfig::get_min_drag_coefficient() const {return min_drag_coefficient;}
void ManualAeroSurfaceConfig::set_max_drag_coefficient(double value) {
	if (max_drag_coefficient == value) return;
	
	max_drag_coefficient = value;
	emit_changed();
}
double ManualAeroSurfaceConfig::get_max_drag_coefficient() const {return max_drag_coefficient;}

void ManualAeroSurfaceConfig::set_drag_aoa_curve(const Ref<Curve> &p_curve) {
	if (drag_aoa_curve == p_curve) return;
	
	watch_curve(this, drag_aoa_curve, p_curve);
	drag_aoa_curve = p_curve;
	emit_changed();
}
Ref<Curve> ManualAeroSurfaceConfig::get_drag_aoa_curve() const {return drag_aoa_curve;}

void ManualAeroSurfaceConfig::set_sweep_drag_multiplier_curve(const Ref<Curve> &p_curve) {
	if (sweep_drag_multiplier_curve == p_curve) return;
	
	watch_curve(this, sweep_drag_multiplier_curve, p_curve);
	sweep_drag_multiplier_curve = p_curve;
	emit_changed();
}
Ref<Curve> ManualAeroSurfaceConfig::get_sweep_drag_multiplier_curve() const {return sweep_drag_multiplier_curve;}
double ManualAeroSurfaceConfig::get_drag_at_sweep_angle(double sweep_angle) const {
    apply_default_curves();
    return sweep_drag_multiplier_curve->sample_baked(Math::abs(Math::remap((real_t) sweep_angle, (real_t) 0.0, (real_t) Math::PI, sweep_drag_multiplier_curve->get_min_domain(), sweep_drag_multiplier_curve->get_max_domain())));
}
void ManualAeroSurfaceConfig::set_drag_at_mach_multiplier_curve(const Ref<Curve> &p_curve) {
	if (drag_at_mach_multiplier_curve == p_curve) return;
	
	watch_curve(this, drag_at_mach_multiplier_curve, p_curve);
	drag_at_mach_multiplier_curve = p_curve;
	emit_changed();
}
Ref<Curve> ManualAeroSurfaceConfig::get_drag_at_mach_multiplier_curve() const {return drag_at_mach_multiplier_curve;}
double ManualAeroSurfaceConfig::get_drag_multiplier_at_mach(double mach) const {
    apply_default_curves();
    return drag_at_mach_multiplier_curve->sample_baked(mach);
}