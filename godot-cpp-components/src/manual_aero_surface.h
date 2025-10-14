#ifndef MANUAL_AERO_SURFACE_3D
#define MANUAL_AERO_SURFACE_3D

#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/core/class_db.hpp>
#include "aero_surface_3d.h"

namespace godot {

class ManualAeroSurface3D : public AeroSurface3D {
	GDCLASS(ManualAeroSurface3D, AeroSurface3D);
private:
    Ref<Resource> manual_config = nullptr;
protected:
	static void _bind_methods();
public:
	//init/deinit, and godot virtual overrides.
	ManualAeroSurface3D();
	~ManualAeroSurface3D();

    PackedVector3Array calculate_forces(double substep_delta);

    void set_manual_config(const Ref<Resource> &p_config);
	Ref<Resource> get_manual_config() const;
};

}

#endif