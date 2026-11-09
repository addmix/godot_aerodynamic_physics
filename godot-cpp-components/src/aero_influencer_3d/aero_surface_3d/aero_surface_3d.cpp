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
    ClassDB::bind_method(D_METHOD("get_aero_reference"), &AeroSurface3D::get_aero_reference);
    ClassDB::bind_method(D_METHOD("get_lift_direction"), &AeroSurface3D::get_lift_direction);
    ClassDB::bind_method(D_METHOD("get_lift_force"), &AeroSurface3D::get_lift_force);
    ClassDB::bind_method(D_METHOD("get_drag_force"), &AeroSurface3D::get_drag_force);
}

AeroSurface3D::AeroSurface3D() {}
AeroSurface3D::~AeroSurface3D() {}

void AeroSurface3D::_enter_tree() {
    AeroInfluencer3D::_enter_tree();
    
    //matches main's `var wing_config : AeroSurfaceConfig = AeroSurfaceConfig.new()`
    if (wing_config.is_null()) wing_config = memnew(AeroSurfaceConfig);
    
    //initialize signal connections from resources (matches main's `wing_config = wing_config` re-trigger)
    set_wing_config(wing_config);
}

ForceAndTorque AeroSurface3D::calculate_forces(double substep_delta) {
    ForceAndTorque force_and_torque = AeroInfluencer3D::calculate_forces(substep_delta);
    if (wing_config.is_null()) {
        area = 0.0;
        projected_wing_area = 0.0;
        aero_reference = 0.0;
        return force_and_torque;
    }
    const Basis global_basis = get_cached_global_basis();
    
    angle_of_attack = global_basis.get_column(1).angle_to(-get_world_air_velocity()) - (Math::PI / 2.0);
    sweep_angle = global_basis.get_column(0).angle_to(-get_world_air_velocity()) - (Math::PI / 2.0);
    
    area = wing_config->get_area();
    projected_wing_area = Math::abs(area * sin(angle_of_attack));
    
    Vector3 right_facing_air_vector = get_world_air_velocity().cross(-global_basis.get_column(1)).normalized();
    lift_direction = get_drag_direction().cross(right_facing_air_vector).normalized();
    
    aero_reference = get_dynamic_pressure() * area;
    
    return force_and_torque;
}


void AeroSurface3D::set_wing_config(const Ref<AeroSurfaceConfig> &p_config) {
    if (wing_config == p_config) return;
    
    wing_config = p_config;
    
    if (wing_config.is_valid() and not wing_config->is_connected("changed", Callable(this, "update_gizmos"))) {
        wing_config->connect("changed", Callable(this, "update_gizmos"));
    }
    
    //redraw for every assignment, including a swap to an already-connected config or a cleared config
    update_gizmos();
    
    AeroSurface3D *other = Object::cast_to<AeroSurface3D>(get_mirror_duplicate());
    if (other) other->set_wing_config(p_config);
}
Ref<AeroSurfaceConfig> AeroSurface3D::get_wing_config() const {return wing_config;};

double AeroSurface3D::get_angle_of_attack() const {
    return angle_of_attack;
}
double AeroSurface3D::get_sweep_angle() const {
    return sweep_angle;
}
double AeroSurface3D::get_area() const {
    return area;
}
double AeroSurface3D::get_projected_wing_area() const {
    return projected_wing_area;
}
double AeroSurface3D::get_aero_reference() const {
    return aero_reference;
}
Vector3 AeroSurface3D::get_lift_direction() const {
    return lift_direction;
}
double AeroSurface3D::get_lift_force() const {
    return lift_force;
}
double AeroSurface3D::get_drag_force() const {
    return drag_force;
}