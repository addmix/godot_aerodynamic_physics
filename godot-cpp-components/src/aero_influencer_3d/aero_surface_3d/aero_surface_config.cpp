#include "aero_influencer_3d/aero_surface_3d/aero_surface_config.h"

using namespace godot;

void AeroSurfaceConfig::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_chord", "value"), &AeroSurfaceConfig::set_chord);
	ClassDB::bind_method(D_METHOD("get_chord"), &AeroSurfaceConfig::get_chord);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "chord", PROPERTY_HINT_RANGE, "0,100,0.001,or_greater,exp,suffix:m"), "set_chord", "get_chord");
    ClassDB::bind_method(D_METHOD("set_span", "value"), &AeroSurfaceConfig::set_span);
	ClassDB::bind_method(D_METHOD("get_span"), &AeroSurfaceConfig::get_span);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "span", PROPERTY_HINT_RANGE, "0,100,0.001,or_greater,exp,suffix:m"), "set_span", "get_span");
    ClassDB::bind_method(D_METHOD("set_area", "value"), &AeroSurfaceConfig::set_area);
	ClassDB::bind_method(D_METHOD("get_area"), &AeroSurfaceConfig::get_area);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "area", PROPERTY_HINT_NONE, "0,1000,0.01,or_greater,exp,suffix:m^2", PROPERTY_USAGE_EDITOR), "set_area", "get_area");
    ClassDB::bind_method(D_METHOD("set_aspect_ratio", "value"), &AeroSurfaceConfig::set_aspect_ratio);
	ClassDB::bind_method(D_METHOD("get_aspect_ratio"), &AeroSurfaceConfig::get_aspect_ratio);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "aspect_ratio", PROPERTY_HINT_NONE, "0,100,0.001,or_greater,exp,suffix:%", PROPERTY_USAGE_EDITOR), "set_aspect_ratio", "get_aspect_ratio");
}

AeroSurfaceConfig::AeroSurfaceConfig() {}
AeroSurfaceConfig::~AeroSurfaceConfig() {}

void AeroSurfaceConfig::set_chord(double value) {
    chord = Math::abs(value);
    emit_changed();
}
double AeroSurfaceConfig::get_chord() {
    return chord;
}
void AeroSurfaceConfig::set_span(double value) {
    span = Math::abs(value);
    emit_changed();
}
double AeroSurfaceConfig::get_span() {
    return span;
}
void AeroSurfaceConfig::set_area(double _area) {
	double _aspect_ratio = get_aspect_ratio();
	double area = get_area();

	double _span = _aspect_ratio * chord / sqrt(area) * sqrt(_area);
	double _chord = span / _aspect_ratio / sqrt(area) * sqrt(_area);

	if (UtilityFunctions::is_equal_approx(_span, 0.0) || UtilityFunctions::is_equal_approx(_chord, 0.0)) {
		return;
	}

	span = _span;
	chord = _chord;

    emit_changed();
}
double AeroSurfaceConfig::get_area() {
    return span * chord;
}
void AeroSurfaceConfig::set_aspect_ratio(double _aspect_ratio) {
	if (UtilityFunctions::is_equal_approx(_aspect_ratio, 0.0) || !(UtilityFunctions::is_finite(_aspect_ratio))) return;
	double _area = get_area();

	double _span = sqrt(_aspect_ratio * _area);
	double _chord = sqrt(_area) / sqrt(_aspect_ratio);

	if (UtilityFunctions::is_equal_approx(_span, 0.0) || UtilityFunctions::is_equal_approx(_chord, 0.0)) return;

	span = _span;
	chord = _chord;

    emit_changed();
}
double AeroSurfaceConfig::get_aspect_ratio() {
    return span / chord;
}