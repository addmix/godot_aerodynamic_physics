#ifndef AERO_UNITS
#define AERO_UNITS

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/node3d.hpp>

using namespace godot;

class AeroUnits : public Object
{
	GDCLASS(AeroUnits, Object);

	static AeroUnits *singleton;

    double ratio_of_specific_heat = 1.402;



protected:
	static void _bind_methods();

public:
	static AeroUnits *get_singleton();

	AeroUnits();
	~AeroUnits();

    double get_speed_of_sound_at_pressure_and_density(double pressure, double density);
    double speed_to_mach_at_altitude(double speed, double altitude);
    double get_altitude(Node3D* node);

    double get_temp_at_altitude(double altitude);
    double get_pressure_at_altitude(double altitude);
    double get_density_at_altitude(double altitude);
    double get_mach_at_altitude(double altitude);
};

#endif