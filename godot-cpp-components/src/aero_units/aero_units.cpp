#include "aero_units.h"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/window.hpp>

#include <algorithm>
#include <cmath>

using namespace godot;

AeroUnits *AeroUnits::singleton = nullptr;

void AeroUnits::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("get_speed_of_sound_at_pressure_and_density", "pressure", "density"), &AeroUnits::get_speed_of_sound_at_pressure_and_density);
    ClassDB::bind_method(D_METHOD("speed_to_mach_at_altitude", "speed", "altitude"), &AeroUnits::speed_to_mach_at_altitude);
    ClassDB::bind_method(D_METHOD("get_altitude", "node"), &AeroUnits::get_altitude);

    ClassDB::bind_method(D_METHOD("get_temp_at_altitude", "altitude"), &AeroUnits::get_temp_at_altitude);
    ClassDB::bind_method(D_METHOD("get_pressure_at_altitude", "altitude"), &AeroUnits::get_pressure_at_altitude);
    ClassDB::bind_method(D_METHOD("get_density_at_altitude", "altitude"), &AeroUnits::get_density_at_altitude);
    ClassDB::bind_method(D_METHOD("get_mach_at_altitude", "altitude"), &AeroUnits::get_mach_at_altitude);
    ClassDB::bind_method(D_METHOD("get_bounds", "key"), &AeroUnits::get_bounds);

    ClassDB::bind_method(D_METHOD("get_ratio_of_specific_heat"), &AeroUnits::get_ratio_of_specific_heat);
	ClassDB::bind_method(D_METHOD("set_ratio_of_specific_heat", "value"), &AeroUnits::set_ratio_of_specific_heat);
	ClassDB::bind_method(D_METHOD("get_altitude_values"), &AeroUnits::get_altitude_values);
	ClassDB::bind_method(D_METHOD("set_altitude_values", "value"), &AeroUnits::set_altitude_values);

    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "ratio_of_specific_heat"), "set_ratio_of_specific_heat", "get_ratio_of_specific_heat");
    ADD_PROPERTY(PropertyInfo(Variant::DICTIONARY, "altitude_values"), "set_altitude_values", "get_altitude_values");
}

AeroUnits *AeroUnits::get_singleton()
{
	return singleton;
}

static Dictionary make_atmosphere_entry(double temperature, double pressure, double density) {
	Dictionary entry;
	entry["temperature"] = temperature;
	entry["pressure"] = pressure;
	entry["density"] = density;
	return entry;
}

AeroUnits::AeroUnits()
{
	//ERR_FAIL_COND(singleton != nullptr);
	singleton = this;

	//Default standard atmosphere table, mirrors main's @export var altitude_values defaults.
	altitude_values[0.0] = make_atmosphere_entry(288.0, 101325.0, 1.225);
	altitude_values[2000.0] = make_atmosphere_entry(275.0, 79495.2, 1.0065);
	altitude_values[5000.0] = make_atmosphere_entry(255.0, 54019.9, 0.7361);
	altitude_values[10000.0] = make_atmosphere_entry(223.0, 26436.3, 0.4127);
	altitude_values[15000.0] = make_atmosphere_entry(216.0, 12044.6, 0.1937);
	altitude_values[20000.0] = make_atmosphere_entry(216.0, 5474.8, 0.08803);
	altitude_values[30000.0] = make_atmosphere_entry(226.0, 1171.8, 0.01803);
	altitude_values[40000.0] = make_atmosphere_entry(251.0, 277.5, 0.003851);
	altitude_values[50000.0] = make_atmosphere_entry(270.0, 75.9, 0.0009775);
	altitude_values[60000.0] = make_atmosphere_entry(245.0, 20.3, 0.0002883);
	altitude_values[70000.0] = make_atmosphere_entry(217.0, 4.6, 0.00007424);
	altitude_values[80000.0] = make_atmosphere_entry(196.0, 0.89, 0.0000157);

	recalculate_curves();
}

AeroUnits::~AeroUnits()
{
	//ERR_FAIL_COND(singleton != this);
	singleton = nullptr;
}


double AeroUnits::get_speed_of_sound_at_pressure_and_density(double pressure, double density) {
	return std::sqrt(ratio_of_specific_heat * (pressure / density));
}

double AeroUnits::speed_to_mach_at_altitude(double speed, double altitude) {
	return speed / get_mach_at_altitude(altitude);
}

double AeroUnits::get_altitude(Node3D* node) {
	//Mirrors main: delegate to /root/FloatingOriginHelper if it exists, else use global Y.
	SceneTree *scene_tree = Object::cast_to<SceneTree>(Engine::get_singleton()->get_main_loop());
	if (scene_tree == nullptr) {
		return node->get_global_position().y;
	}
	Window *root = scene_tree->get_root();
	Object *helper = root->get_node_or_null(NodePath("/root/FloatingOriginHelper"));
	if (helper != nullptr && helper->has_method("get_altitude")) {
		return helper->call("get_altitude", node);
	}
	return node->get_global_position().y;
}

double AeroUnits::get_temp_at_altitude(double altitude) {
	return sample_column(COLUMN_TEMPERATURE, altitude);
}

double AeroUnits::get_pressure_at_altitude(double altitude) {
	return sample_column(COLUMN_PRESSURE, altitude);
}

double AeroUnits::get_density_at_altitude(double altitude) {
	return sample_column(COLUMN_DENSITY, altitude);
}

double AeroUnits::get_mach_at_altitude(double altitude) {
	return sample_column(COLUMN_MACH, altitude);
}

Array AeroUnits::get_bounds(const String &key) {
	//Mirrors main's get_bounds: returns [min, max] for the given key ("altitude" or a data column).
	Array result;
	if (points_.empty()) {
		result.append(0.0);
		result.append(0.0);
		return result;
	}

	double min_value = 0.0;
	double max_value = 0.0;
	if (key == "altitude") {
		min_value = points_.front().altitude;
		max_value = min_value;
		for (const AltitudePoint &point : points_) {
			if (point.altitude < min_value) {
				min_value = point.altitude;
			}
			if (point.altitude > max_value) {
				max_value = point.altitude;
			}
		}
	} else {
		int column = COLUMN_TEMPERATURE;
		if (key == "pressure") {
			column = COLUMN_PRESSURE;
		} else if (key == "density") {
			column = COLUMN_DENSITY;
		} else if (key == "mach") {
			column = COLUMN_MACH;
		}

		min_value = column_value(points_.front(), column);
		max_value = min_value;
		for (const AltitudePoint &point : points_) {
			double value = column_value(point, column);
			if (value < min_value) {
				min_value = value;
			}
			if (value > max_value) {
				max_value = value;
			}
		}
	}

	result.append(min_value);
	result.append(max_value);
	return result;
}

void AeroUnits::recalculate_curves() {
	points_.clear();

	Array keys = altitude_values.keys();
	for (int64_t i = 0; i < keys.size(); ++i) {
		double altitude = keys.get(i);

		Dictionary entry = altitude_values[Variant(altitude)];
		double temperature = entry["temperature"];
		double pressure = entry["pressure"];
		double density = entry["density"];

		//mach is dynamically calculated based on pressure and density and added to the dataset (mirrors main)
		double mach = get_speed_of_sound_at_pressure_and_density(pressure, density);
		entry["mach"] = mach;
		altitude_values[Variant(altitude)] = entry;

		points_.push_back({altitude, temperature, pressure, density, mach});
	}

	std::sort(points_.begin(), points_.end(), [](const AltitudePoint &a, const AltitudePoint &b) {
		return a.altitude < b.altitude;
	});
}

double AeroUnits::column_value(const AltitudePoint &point, int column) const {
	switch (column) {
		case COLUMN_PRESSURE:
			return point.pressure;
		case COLUMN_DENSITY:
			return point.density;
		case COLUMN_MACH:
			return point.mach;
		default:
			return point.temperature;
	}
}

double AeroUnits::sample_column(int column, double altitude) const {
	if (points_.empty()) {
		return 0.0;
	}

	const AltitudePoint &first = points_.front();
	const AltitudePoint &last = points_.back();

	//Clamp outside the table bounds, matching Godot's baked curve sampling.
	if (altitude <= first.altitude) {
		return column_value(first, column);
	}
	if (altitude >= last.altitude) {
		return column_value(last, column);
	}

	for (size_t i = 0; i + 1 < points_.size(); ++i) {
		const AltitudePoint &a = points_[i];
		const AltitudePoint &b = points_[i + 1];
		if (altitude >= a.altitude && altitude <= b.altitude) {
			double t = (altitude - a.altitude) / (b.altitude - a.altitude);
			return column_value(a, column) + t * (column_value(b, column) - column_value(a, column));
		}
	}

	return column_value(last, column); //shouldn't reach here
}

double AeroUnits::get_ratio_of_specific_heat() {
	return ratio_of_specific_heat;
}

void AeroUnits::set_ratio_of_specific_heat(double value) {
	ratio_of_specific_heat = value;
	recalculate_curves(); //keep the mach column in sync (main only recalculates on altitude_values change, but gamma feeds into mach)
}

Dictionary AeroUnits::get_altitude_values() const {
	return altitude_values;
}

void AeroUnits::set_altitude_values(Dictionary value) {
	altitude_values = value;
	recalculate_curves();
}
