@tool
extends Node

func _init() -> void:
	recalculate_curves()

#air is 1.402
@export var ratio_of_specific_heat : float = 1.402

#http://www.braeunig.us/space/atmos.htm

var valid_keys : Array = ["temperature", "pressure", "density", "mach"]

@export var altitude_values : Dictionary[float, Dictionary] = {
	0.0: {"temperature": 288.0, "pressure": 101325.0, "density": 1.225},
	2000.0: {"temperature": 275.0, "pressure": 79495.2, "density": 1.0065},
	5000.0: {"temperature": 255.0, "pressure": 54019.9, "density": 0.7361},
	10000.0: {"temperature": 223.0, "pressure": 26436.3, "density": 0.4127},
	15000.0: {"temperature": 216.0, "pressure": 12044.6, "density": 0.1937},
	20000.0: {"temperature": 216.0, "pressure": 5474.8, "density": 0.08803},
	30000.0: {"temperature": 226.0, "pressure": 1171.8, "density": 0.01803},
	40000.0: {"temperature": 251.0, "pressure": 277.5, "density": 0.003851},
	50000.0: {"temperature": 270.0, "pressure": 75.9, "density": .0009775},
	60000.0: {"temperature": 245.0, "pressure": 20.3, "density": .0002883},
	70000.0: {"temperature": 217.0, "pressure": 4.6, "density": .00007424},
	80000.0: {"temperature": 196.0, "pressure": 0.89, "density": .0000157},
}:
	set(x):
		altitude_values = x
		recalculate_curves()


#get the min/max value for the given key
func get_bounds(key : String) -> Array:
	var min : float
	var max : float
	
	if key == "altitude":
		min = altitude_values.keys()[0]
		max = altitude_values.keys()[0]
		for altitude : float in altitude_values.keys():
			if altitude < min:
				min = altitude
			if altitude > max:
				max = altitude
		
		return [min, max]
	
	min = altitude_values[altitude_values.keys()[0]][key]
	max = altitude_values[altitude_values.keys()[0]][key]
	for altitude : float in altitude_values.keys():
		var value : float = altitude_values[altitude][key]
		
		if value < min:
			min = value
		if value > max:
			max = value
	
	return [min, max]

#points are added dynamically during _init()
var temperature_at_altitude_curve := Curve.new()
func get_temp_at_altitude(altitude : float) -> float:
	return temperature_at_altitude_curve.sample_baked(altitude)

#points are added dynamically during _init()
var pressure_at_altitude_curve := Curve.new()
func get_pressure_at_altitude(altitude : float) -> float:
	return pressure_at_altitude_curve.sample_baked(altitude)

#points are added dynamically during _init()
var density_at_altitude_curve := Curve.new()
func get_density_at_altitude(altitude : float) -> float:
	return density_at_altitude_curve.sample_baked(altitude)

#points are added dynamically during _init()
var mach_at_altitude_curve := Curve.new()
func get_mach_at_altitude(altitude : float) -> float:
	return mach_at_altitude_curve.sample_baked(altitude)



func recalculate_curves() -> void:
	var altitude_bounds : Array = get_bounds("altitude")
	
	#mach is dynamically calculated based on pressure and density and added to the dataset
	for altitude : float in altitude_values.keys():
		altitude_values[altitude]["mach"] = get_speed_of_sound_at_pressure_and_density(altitude_values[altitude]["pressure"], altitude_values[altitude]["density"])
	
	#dynamically configure the min/max domain for curves
	for key : String in valid_keys:
		var bounds : Array = get_bounds(key)
		var curve_name : String = key + "_at_altitude_curve"
		var curve : Curve = get(curve_name)
		if not curve:
			continue
		
		curve.min_domain = altitude_bounds[0]
		curve.max_domain = altitude_bounds[1]
		curve.min_value = bounds[0]
		curve.max_value = bounds[1]
		
		for altitude : float in altitude_values.keys():
			
			curve.add_point(Vector2(altitude, altitude_values[altitude][key]), 0.0, 0.0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
			#save curve to disk for debugging
			#ResourceSaver.save(curve, "res://" + curve_name + ".tres")
		
		#bake curve for performance
		curve.bake()



#http://www.sengpielaudio.com/calculator-speedsound.htm
#kelvin
func get_speed_of_sound_at_pressure_and_density(pressure : float, density : float) -> float:
	return sqrt(ratio_of_specific_heat * (pressure / density))

func speed_to_mach_at_altitude(speed : float, altitude : float) -> float:
	return speed / get_mach_at_altitude(altitude)

func get_altitude(node : Node3D) -> float:
	if has_node("/root/FloatingOriginHelper"):
		return $"/root/FloatingOriginHelper".get_altitude(node)
	else:
		return node.global_position.y
