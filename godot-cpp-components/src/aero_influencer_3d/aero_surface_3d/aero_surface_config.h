#ifndef AERO_SURFACE_CONFIG
#define AERO_SURFACE_CONFIG

#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/resource.hpp>

namespace godot {

class AeroSurfaceConfig : public Resource {
	GDCLASS(AeroSurfaceConfig, Resource);
private:
    double chord = 1.0;
    double span = 2.0;
protected:
	static void _bind_methods();
public:
	//init/deinit, and godot virtual overrides.
	AeroSurfaceConfig();
	~AeroSurfaceConfig();

    void set_chord(double value);
    double get_chord();
    void set_span(double value);
    double get_span();
    void set_area(double area);
    double get_area();
    void set_aspect_ratio(double aspect_ratio);
    double get_aspect_ratio();
    
};

}

#endif