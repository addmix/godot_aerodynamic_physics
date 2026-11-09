#ifndef AERO_UNITS
#define AERO_UNITS

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <vector>

using namespace godot;

class AeroUnits : public Object
{
	GDCLASS(AeroUnits, Object);
	
	static AeroUnits *singleton;
	
	//air is 1.402 (mirrors main's @export var ratio_of_specific_heat)
	double ratio_of_specific_heat = 1.402;
	
	//http://www.braeunig.us/space/atmos.htm
	//Mirrors main's @export var altitude_values : Dictionary[float, Dictionary]
	Dictionary altitude_values;
	
	//Interpolation data rebuilt from altitude_values (replaces main's baked linear curves)
	struct AltitudePoint {
		double altitude;
		double temperature;
		double pressure;
		double density;
		double mach;
	};
	std::vector<AltitudePoint> points_; //sorted by ascending altitude
	
	enum Column { COLUMN_TEMPERATURE, COLUMN_PRESSURE, COLUMN_DENSITY, COLUMN_MACH };

protected:
	static void _bind_methods();
	
	void recalculate_curves();
	double sample_column(int column, double altitude) const;
	double column_value(const AltitudePoint &point, int column) const;

public:
	static AeroUnits *get_singleton();
	
	AeroUnits();
	~AeroUnits();
    
    double get_speed_of_sound_at_pressure_and_density(double pressure, double density) const;
    double speed_to_mach_at_altitude(double speed, double altitude) const;
    double get_altitude(Node3D* node) const;
    
    double get_temp_at_altitude(double altitude) const;
    double get_pressure_at_altitude(double altitude) const;
    double get_density_at_altitude(double altitude) const;
    double get_mach_at_altitude(double altitude) const;
	Array get_bounds(const String &key) const;
	
	double get_ratio_of_specific_heat() const;
	void set_ratio_of_specific_heat(double value);
	Dictionary get_altitude_values() const;
	void set_altitude_values(Dictionary value);
};

#endif
