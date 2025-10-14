#include "aero_surface_3d.h"

using namespace godot;

void AeroSurface3D::_bind_methods() {
    AeroInfluencer3D::_bind_methods();
    
    ClassDB::bind_method(D_METHOD("set_disabled", "p_disabled"), &AeroInfluencer3D::set_disabled);
	ClassDB::bind_method(D_METHOD("is_disabled"), &AeroInfluencer3D::is_disabled);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "disabled"), "set_disabled", "is_disabled");

}