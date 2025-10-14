#ifndef AERO_SURFACE_3D
#define AERO_SURFACE_3D

#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/core/class_db.hpp>
#include "aero_influencer_3d.h"

namespace godot {

class AeroSurface3D : public AeroInfluencer3D {
	GDCLASS(AeroSurface3D, AeroInfluencer3D);
private:
    Ref<Resource> wing_config = nullptr;
    double angle_of_attack = 0.0;
    double sweep_angle = 0.0;
    double area = 0.0;
    double projected_wing_area = 0.0;
    double aero_reference = 0.0;
protected:
	static void _bind_methods();

    Vector3 lift_direction = Vector3(0, 0, 0);

    double lift_force = 0.0;
    double drag_force = 0.0;
public:
	//init/deinit, and godot virtual overrides.
	AeroSurface3D();
	~AeroSurface3D();

    void _enter_tree() override;
    PackedVector3Array calculate_forces(double substep_delta);

    void set_wing_config(const Ref<Resource> &p_config);
	Ref<Resource> get_wing_config() const;
    
    double get_angle_of_attack();
    double get_sweep_angle();
    double get_area();
    double get_projected_wing_area();
    double get_aero_reference();
    Vector3 get_lift_direction();
    double get_lift_force();
    double get_drag_force();
};

}

#endif