#include "aero_units.h"

using namespace godot;

AeroUnits *AeroUnits::singleton = nullptr;

void AeroUnits::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("get_speed_of_sound_at_pressure_and_density", "pressure", "density"), &AeroUnits::get_speed_of_sound_at_pressure_and_density);
    ClassDB::bind_method(D_METHOD("speed_to_mach_at_altitude", "pressure", "density"), &AeroUnits::speed_to_mach_at_altitude);
    ClassDB::bind_method(D_METHOD("get_altitude", "p_density"), &AeroUnits::get_altitude);

    ClassDB::bind_method(D_METHOD("get_temp_at_altitude", "altitude"), &AeroUnits::get_temp_at_altitude);
    ClassDB::bind_method(D_METHOD("get_pressure_at_altitude", "altitude"), &AeroUnits::get_pressure_at_altitude);
    ClassDB::bind_method(D_METHOD("get_density_at_altitude", "altitude"), &AeroUnits::get_density_at_altitude);
    ClassDB::bind_method(D_METHOD("get_mach_at_altitude", "altitude"), &AeroUnits::get_mach_at_altitude);
}

AeroUnits *AeroUnits::get_singleton()
{
	return singleton;
}

AeroUnits::AeroUnits()
{
	//ERR_FAIL_COND(singleton != nullptr);
	singleton = this;
}

AeroUnits::~AeroUnits()
{
	//ERR_FAIL_COND(singleton != this);
	singleton = nullptr;
}


double AeroUnits::get_speed_of_sound_at_pressure_and_density(double pressure, double density) {
    return ratio_of_specific_heat * (pressure / density);
}
double AeroUnits::speed_to_mach_at_altitude(double speed, double altitude) {
    return speed / get_mach_at_altitude(altitude);
}
double AeroUnits::get_altitude(Node3D* node) {
    if (node->has_method("get_altitude")) {
        return node->call("get_altitude");
    }
    return node->get_global_position().y;
}

double AeroUnits::get_temp_at_altitude(double altitude) {
    return 288.0;
}
double AeroUnits::get_pressure_at_altitude(double altitude) {
    return 101325.0;
}
double AeroUnits::get_density_at_altitude(double altitude) {
    return 1.225;
}
double AeroUnits::get_mach_at_altitude(double altitude) {
    return 343.0;
}