#include "aero_influencer_3d/aero_surface_3d/aero_surface_3d.h"
#include "aero_influencer_3d/aero_surface_3d/aero_surface_config.h"

using namespace godot;

void AeroSurface3D::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_wing_config", "p_config"), &AeroSurface3D::set_wing_config);
	ClassDB::bind_method(D_METHOD("get_wing_config"), &AeroSurface3D::get_wing_config);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "wing_config", PROPERTY_HINT_RESOURCE_TYPE, "AeroSurfaceConfig"), "set_wing_config", "get_wing_config");
    
    ClassDB::bind_method(D_METHOD("get_angle_of_attack"), &AeroSurface3D::get_angle_of_attack);
    ClassDB::bind_method(D_METHOD("get_sweep_angle"), &AeroSurface3D::get_sweep_angle);
    ClassDB::bind_method(D_METHOD("get_area"), &AeroSurface3D::get_area);
    ClassDB::bind_method(D_METHOD("get_projected_wing_area"), &AeroSurface3D::get_projected_wing_area);
    ClassDB::bind_method(D_METHOD("get_lift_direction"), &AeroSurface3D::get_lift_direction);
    ClassDB::bind_method(D_METHOD("get_lift_force"), &AeroSurface3D::get_lift_force);
    ClassDB::bind_method(D_METHOD("get_drag_force"), &AeroSurface3D::get_drag_force);
}

AeroSurface3D::AeroSurface3D() {}
AeroSurface3D::~AeroSurface3D() {}

void AeroSurface3D::_enter_tree() {
    AeroInfluencer3D::_enter_tree();
}

ForceAndTorque AeroSurface3D::calculate_forces(double substep_delta) {
    ForceAndTorque force_and_torque = AeroInfluencer3D::calculate_forces(substep_delta);
    
    angle_of_attack = get_global_basis().get_column(1).angle_to(-get_world_air_velocity()) - (Math_PI / 2.0);
    sweep_angle = get_global_basis().get_column(0).angle_to(-get_world_air_velocity()) - (Math_PI / 2.0);

    area = (double) wing_config->get("chord") * (double) wing_config->get("span");
    projected_wing_area = area * sin(angle_of_attack);

    Vector3 right_facing_air_vector = get_world_air_velocity().cross(-get_global_basis().get_column(1)).normalized();
    lift_direction = get_drag_direction().cross(right_facing_air_vector).normalized();

    aero_reference = get_dynamic_pressure() * area;

    return force_and_torque;
}


void AeroSurface3D::set_wing_config(const Ref<AeroSurfaceConfig> &p_config) {
    wing_config = p_config;

    if (wing_config == nullptr) return;

    if (not wing_config->is_connected("changed", Callable(this, "update_gizmos"))) {
        wing_config->connect("changed", Callable(this, "update_gizmos"));
        update_gizmos();
    }
};
Ref<AeroSurfaceConfig> AeroSurface3D::get_wing_config() const {return wing_config;};

double AeroSurface3D::get_angle_of_attack() {
    return angle_of_attack;
}
double AeroSurface3D::get_sweep_angle() {
    return sweep_angle;
}
double AeroSurface3D::get_area() {
    return area;
}
double AeroSurface3D::get_projected_wing_area() {
    return projected_wing_area;
}
double AeroSurface3D::get_aero_reference() {
    return aero_reference;
}
Vector3 AeroSurface3D::get_lift_direction() {
    return lift_direction;
}
double AeroSurface3D::get_lift_force() {
    return lift_force;
}
double AeroSurface3D::get_drag_force() {
    return drag_force;
}