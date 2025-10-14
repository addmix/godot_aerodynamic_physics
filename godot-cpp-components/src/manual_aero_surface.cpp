#include "manual_aero_surface.h"

using namespace godot;

void ManualAeroSurface3D::_bind_methods() {
    //AeroSurface3D::_bind_methods();

    ClassDB::bind_method(D_METHOD("set_manual_config", "p_config"), &ManualAeroSurface3D::set_manual_config);
	ClassDB::bind_method(D_METHOD("get_manual_config"), &ManualAeroSurface3D::get_manual_config);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "manual_config", PROPERTY_HINT_RESOURCE_TYPE, "ManualAeroSurfaceConfig"), "set_manual_config", "get_manual_config");
}

ManualAeroSurface3D::ManualAeroSurface3D() {
    Ref<GDScript> manual_config_script = ResourceLoader::get_singleton()->load("res://addons/godot_aerodynamic_physics/core/aero_influencer_3d/aero_surface_3d/manual_aero_surface_3d/manual_aero_surface_config.gd");

    Ref<Resource> config = memnew(Resource);
    config->set_script(manual_config_script);

    manual_config = config;
}
ManualAeroSurface3D::~ManualAeroSurface3D() {}

PackedVector3Array ManualAeroSurface3D::calculate_forces(double substep_delta) {
    PackedVector3Array force_and_torque = AeroSurface3D::calculate_forces(substep_delta);

    Vector3 force = Vector3(0, 0, 0);
    Vector3 torque = Vector3(0, 0, 0);

    if (manual_config == nullptr) {
        UtilityFunctions::print("couldn't access manual config");
        return force_and_torque;
    }

    lift_force = get_aero_reference() * (double) manual_config->call("get_lift_coefficient", get_angle_of_attack());
    double drag_coefficient = (double) manual_config->call("get_drag_coefficient", get_angle_of_attack()) * (double) manual_config->call("get_drag_at_sweep_angle", get_sweep_angle()) * (double) manual_config->call("get_drag_multiplier_at_mach", get_mach());
    double form_drag = get_aero_reference() * drag_coefficient;
    double induced_drag = (lift_force * lift_force) / (get_dynamic_pressure() * Math_PI * (double) get_wing_config()->get("span") * (double) get_wing_config()->get("span"));

    if (UtilityFunctions::is_equal_approx(get_air_speed(), 0.0)) {
        induced_drag = 0.0;
    }

    drag_force = form_drag + induced_drag;

    Vector3 lift_vector = lift_direction * lift_force;
    Vector3 drag_vector = get_drag_direction() * drag_force;

    force = lift_vector + drag_vector;
    torque = get_relative_position().cross(force);

    force_and_torque[0] = force_and_torque[0] + force;
    force_and_torque[1] = force_and_torque[1] + torque;

    return force_and_torque;
}

void ManualAeroSurface3D::set_manual_config(const Ref<Resource> &p_config) {manual_config = p_config;};
Ref<Resource> ManualAeroSurface3D::get_manual_config() const {return manual_config;};
