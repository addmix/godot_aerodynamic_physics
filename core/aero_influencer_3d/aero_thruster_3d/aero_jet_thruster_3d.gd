@tool
extends AeroThruster3D
class_name AeroJetThruster3D

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

func get_thrust_force() -> Vector3:
	return throttle.normalized() * calculate_mass_flow_acceleration_force() * get_physics_process_delta_time()

func calculate_mass_flow_acceleration_force() -> float:
	var intake_air_velocity : float = get_linear_velocity().length()
	#var intake_air_density : float = air_density
	#var intake_air_pressure : float = 101325.0
	var intake_mass_flow_rate : float = air_density * intake_air_velocity * intake_area
	
		#intake_air_pressure = aero_units.get_pressure_at_altitude(altitude)
	
	var fuel_burn_rate : float = max_fuel_flow * throttle.length()
	var exhaust_velocity : float = calculate_exhaust_velocity()
	#https://www.omnicalculator.com/physics/ideal-gas-law
	#var exhaust_pressure : float = 0.0 #will need to use fuel combustion expansion ratio
	var exhaust_mass_flow_rate : float = intake_mass_flow_rate + (air_density * intake_fan_max_velocity * throttle.length() * intake_area) + fuel_burn_rate
	
	#mass_flow_rate = mass/time
	#mass_flow_rate == density * velocity * area
	return (exhaust_mass_flow_rate * exhaust_velocity) - (intake_mass_flow_rate * intake_air_velocity)# + (exhaust_pressure - intake_air_pressure) * exit_area

func calculate_exhaust_velocity() -> float:
	return exhaust_velocity
