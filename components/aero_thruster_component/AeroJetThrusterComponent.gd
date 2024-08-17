@icon("../../icons/JetThrusterComponent.svg")
extends AeroThrusterComponent
class_name AeroJetThrusterComponent

@export_group("Simulation Parameters")
##Area (in meters squared) of the JetThrusterComponent's intake.
@export var intake_area : float = 0.5
##Area (in meters squared) of the JetThrusterComponent's exhaust. (Unused)
#@export var exit_area : float = 1.0
##Maxmimum air velocity the intake fan can create in static thrust, at max throttle.
@export var intake_fan_max_velocity : float = 300.0
##Velocity of exhaust gasses at max throttle.
@export var exhaust_velocity : float = 1000
##Maximum amount of fuel (in kilograms) the engine can burn per second.
@export var max_fuel_flow : float = 0.1 #flow rate in kilograms per second
##Ratio of fuel volume before, and after combustion. (Unused)
#@export var fuel_expansion_ratio : float = 10.0

func get_thrust_magnitude() -> float:
	return calculate_mass_flow_acceleration_force()

func calculate_mass_flow_acceleration_force() -> float:
	var altitude : float = 0.0
	var air_velocity : Vector3 = rigid_body.linear_velocity
	if rigid_body is AeroBody3D:
		altitude = rigid_body.altitude
		air_velocity = -rigid_body.air_velocity
	else:
		altitude = AeroUnits.get_altitude(self)
	
	var intake_air_velocity : float = air_velocity.dot(-global_basis.z)
	var intake_air_density : float = AeroUnits.get_density_at_altitude(altitude)
	var intake_air_pressure : float = AeroUnits.get_pressure_at_altitude(altitude)
	var intake_mass_flow_rate : float = intake_air_density * intake_air_velocity * intake_area
	
	var fuel_burn_rate : float = max_fuel_flow * throttle
	var exhaust_velocity : float = calculate_exhaust_velocity()
	#https://www.omnicalculator.com/physics/ideal-gas-law
	#var exhaust_pressure : float = 0.0 #will need to use fuel combustion expansion ratio
	var exhaust_mass_flow_rate : float = intake_mass_flow_rate + (intake_air_density * intake_fan_max_velocity * throttle * intake_area) + fuel_burn_rate
	
	#mass_flow_rate = mass/time
	#mass_flow_rate == density * velocity * area
	return (exhaust_mass_flow_rate * exhaust_velocity) - (intake_mass_flow_rate * intake_air_velocity)# + (exhaust_pressure - intake_air_pressure) * exit_area

func calculate_exhaust_velocity() -> float:
	return exhaust_velocity
