class_name Aerodynamics

@export var default_drag_curve : Curve
@export var atmosphere_density_curve : Curve
@export var mach_altitude_curve : Curve

func speed_to_mach(speed : float, altitude : float) -> float:
	return speed / mach_altitude_curve.sample(altitude)

func get_atmosphere_pressure(altitude : float) -> float:
	return atmosphere_density_curve.sample(altitude)

func get_atmosphere_density(altitude : float) -> float:
	return 0.021 * get_atmosphere_pressure(altitude)

func get_drag_multiplier(speed : float, altitude : float) -> float:
	return default_drag_curve.sample(speed_to_mach(speed, altitude))
