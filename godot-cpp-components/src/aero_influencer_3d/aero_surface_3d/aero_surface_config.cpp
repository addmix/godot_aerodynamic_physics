#include "aero_influencer_3d/aero_surface_3d/aero_surface_config.h"

using namespace godot;

void AeroSurfaceConfig::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_chord", "value"), &AeroSurfaceConfig::set_chord);
	ClassDB::bind_method(D_METHOD("get_chord"), &AeroSurfaceConfig::get_chord);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "chord"), "set_chord", "get_chord");
    ClassDB::bind_method(D_METHOD("set_span", "value"), &AeroSurfaceConfig::set_span);
	ClassDB::bind_method(D_METHOD("get_span"), &AeroSurfaceConfig::get_span);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "span"), "set_span", "get_span");
    ClassDB::bind_method(D_METHOD("set_area", "value"), &AeroSurfaceConfig::set_area);
	ClassDB::bind_method(D_METHOD("get_area"), &AeroSurfaceConfig::get_area);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "area"), "set_area", "get_area");
    ClassDB::bind_method(D_METHOD("set_aspect_ratio", "value"), &AeroSurfaceConfig::set_aspect_ratio);
	ClassDB::bind_method(D_METHOD("get_aspect_ratio"), &AeroSurfaceConfig::get_aspect_ratio);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "aspect_ratio"), "set_aspect_ratio", "get_aspect_ratio");
}

AeroSurfaceConfig::AeroSurfaceConfig() {}
AeroSurfaceConfig::~AeroSurfaceConfig() {}

void AeroSurfaceConfig::set_chord(double value) {
    chord = abs(value);
    emit_changed();
}
double AeroSurfaceConfig::get_chord() {
    return chord;
}
void AeroSurfaceConfig::set_span(double value) {
    span = abs(value);
    emit_changed();
}
double AeroSurfaceConfig::get_span() {
    return span;
}
void AeroSurfaceConfig::set_area(double _area) {
    double area = get_area();
	if (UtilityFunctions::is_equal_approx(area, 0.0)) {
		span = 2.0;
		chord = 1.0;
		set_aspect_ratio(2.0);
    }
	
	double _span = get_aspect_ratio() * chord / sqrt(area) * sqrt(_area);
	double _chord = span / get_aspect_ratio() / sqrt(area) * sqrt(_area);
	
	span = _span;
	chord = _chord;

    emit_changed();
}
double AeroSurfaceConfig::get_area() {
    return span * chord;
}
void AeroSurfaceConfig::set_aspect_ratio(double _aspect_ratio) {
    double _area = get_area();
	
	double _span = sqrt(_aspect_ratio * _area);
	double _chord = sqrt(_area) / sqrt(_aspect_ratio);
	
	span = _span;
	chord = _chord;

    emit_changed();
}
double AeroSurfaceConfig::get_aspect_ratio() {
    return span / chord;
}