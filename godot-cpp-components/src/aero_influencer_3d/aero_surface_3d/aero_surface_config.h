#ifndef AERO_SURFACE_CONFIG
#define AERO_SURFACE_CONFIG

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
    double get_chord() const;
    void set_span(double value);
    double get_span() const;
    void set_area(double area);
    double get_area() const;
    void set_aspect_ratio(double aspect_ratio);
    double get_aspect_ratio() const;
    
};

}

#endif