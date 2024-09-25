@tool
extends Resource
class_name FlightAssist

var air_speed : float = 0.0
var air_density : float = 1.0

var angle_of_attack : float = 0.0
var altitude : float = 0.0
var heading : float = 0.0
var bank_angle : float = 0.0

var linear_velocity : Vector3 = Vector3.ZERO
var local_angular_velocity : Vector3 = Vector3.ZERO
var global_transform : Transform3D = Transform3D()

var control_input := Vector3.ZERO
var control_command := Vector3.ZERO
var throttle_command : float = 0.0
##Maximum turn rate (in radians per second) the flight assist will command.
@export var max_angular_rates := Vector3(2, 1, 5.0)
var angular_rate_error := Vector3.ZERO

@export_group("Flight Assist")
@export_subgroup("Axes")
##If enabled, flight assist is enabled on the pitch (X) axis.
@export var enable_flight_assist_x : bool = true
##PID controller used to evaluate appropriate control response.
@export var pitch_assist_pid : aero_PID = aero_PID.new(0.5, 3, 0, true, -0.2, 0.2)
##If enabled, flight assist is enabled on the yaw (Y) axis.
@export var enable_flight_assist_y : bool = true
##PID controller used to evaluate appropriate control response.
@export var yaw_assist_pid : aero_PID = aero_PID.new(1, 0, 0)
##If enabled, flight assist is enabled on the roll (Z) axis.
@export var enable_flight_assist_z : bool = true
##PID controller used to evaluate appropriate control response.
@export var roll_assist_pid : aero_PID = aero_PID.new(0.2, 0, 0)
@export_subgroup("G Limiter")
##In enabled, the flight assist resource will attempt to keep felt G-forces below the g_limit.
@export var enable_g_limiter : bool = true
##Maximum allowable G-force.
@export var g_limit : float = 9.0
##Maximum allowable negative G-force.
@export var negative_g_limit : float = 3.0
@export_subgroup("AOA Limiter")
##If enabled, the flight assist resource will attempt to prevent angle of attack from exceeding this limit.
@export var enable_aoa_limiter : bool = true
##Angle of attack (degrees) that control authority begins to decrease.
@export var aoa_limit_start : float = 22.0
##Angle of attack (degrees) that control authority is reduced to 0.
@export var aoa_limit_end : float = 25.0
@export_subgroup("Tuning")
##If enabled, the flight assist resource will adjust the control authority in an attempt to maintain a consistent control respsonse, despite changing airspeed or air density.
@export var enable_control_adjustment : bool = false
##Airspeed that control adjustments are tuned at.
@export var tuned_airspeed : float = 100.0
##Minimum limit for airspeed adjustment. This prevents controls from losing authority at low speeds due to control surface stalls.
@export var min_accounted_airspeed : float = 75.0
##Air density that control adjustments are tuned at.
@export var tuned_density : float = 1.222
##Minimum limit for air density adjustment. This prevents controls from losing authority at low air density due to control surface stalls.
@export var min_accounted_air_density : float = 0.1

@export_group("Autopilot")
@export_subgroup("Bank Angle")
##If enabled, the flight assist resource will take control of the bank angle (roll), and attempt to drive it towards bank_angle_target.
@export var enable_bank_angle_assist : bool = false
##Target bank angle that bank_angle_pid will attempt to maintain.
@export var bank_angle_target : float = 0.0
##PID controller used to evaluate appropriate control response.
@export var bank_angle_pid : aero_PID = aero_PID.new(1, 0.05, 0.1)

@export_subgroup("Speed Hold")
##If enabled, the flight assist resource will control throttle, and attempt to maintain airspeed at speed_target.
@export var enable_speed_hold : bool = false:
	set(x):
		enable_speed_hold = x
		speed_target = air_speed
##Target speed that speed_pid will attempt to maintain.
@export var speed_target : float = 0.0
##PID controller used to evaluate appropriate control response.
@export var speed_pid : aero_PID = aero_PID.new(0, 0.4, 0)

@export_subgroup("Altitude Hold")
##If enabled, the flight assist resource will attempt to maintain altitude at altitude_target.
@export var enable_altitude_hold : bool = false:
	set(x):
		enable_altitude_hold = x
		altitude_target = altitude
##Target altitude that altitude_pid will attempt to maintain.
@export var altitude_target : float = 0.0
##PID controller used to evaluate appropriate control response.
@export var altitude_pid : aero_PID = aero_PID.new(0.001, 0, 0.01)

@export_subgroup("Heading Hold")
##If enabled, the flight assist resource will attempt to maintain heading at heading_target.
@export var enable_heading_hold : bool = false:
	set(x):
		enable_heading_hold = x
		heading_target = heading
##Target heading that heading_pid will attempt to maintain.
@export var heading_target : float = 0.0
##PID controller used to evaluate appropriate control response.
@export var heading_pid : aero_PID = aero_PID.new(10, 0, 0)

@export_subgroup("Target Direction")
##If enabled, the flight assist resource will attempt to maintain linear_velocity pointing in the direction of direction_target.
@export var enable_target_direction : bool = false
##Target direction that direction PIDs will attempt to maintain.
@export var direction_target : Vector3 = Vector3.ZERO##PID controller used to evaluate appropriate control response.
##PID controller used to evaluate appropriate control response.
@export var direction_pitch_pid : aero_PID = aero_PID.new(10, 0.3, 4)
##PID controller used to evaluate appropriate control response.
@export var direction_yaw_pid : aero_PID = aero_PID.new(25, 0, 0)
##PID controller used to evaluate appropriate control response.
@export var direction_roll_pid : aero_PID = aero_PID.new(0.8, 0, 0)

@export_subgroup("")
@export_category("")

func update(delta : float) -> void:
	control_command = control_input
	
	speed_hold(delta)
	bank_angle_assist(delta)
	altitude_hold(delta)
	heading_hold(delta)
	target_direction(delta)
	flight_assist(delta)

func bank_angle_assist(delta : float) -> void:
	if not enable_bank_angle_assist and not enable_altitude_hold and not enable_heading_hold:
		return
	bank_angle_pid.update(delta, bank_angle_target - bank_angle)
	control_input.z += bank_angle_pid.output

func speed_hold(delta : float) -> void:
	if not enable_speed_hold:
		return
	speed_pid.update(delta, speed_target - air_speed)
	throttle_command = speed_pid.output

func altitude_hold(delta : float) -> void:
	if not enable_altitude_hold:
		return
	#shit but works
	altitude_pid.update(delta, altitude_target - altitude)
	control_input.x += altitude_pid.output

func heading_hold(delta : float) -> void:
	if not enable_heading_hold:
		return
	#shit but works. Also has -180/+180 wrapping issues
	heading_pid.update(delta, heading_target - heading)
	control_input.y += heading_pid.output


func target_direction(delta : float) -> void:
	if not enable_target_direction:
		return
	if linear_velocity.is_equal_approx(Vector3.ZERO):
		return
	var velocity_direction : Vector3 = linear_velocity.normalized()
	var local_velocity_direction : Vector3 = velocity_direction * global_transform.basis
	var angles_to_local_velocity_direction := Vector3(
			atan2(local_velocity_direction.y, -local_velocity_direction.z),
			atan2(-local_velocity_direction.x, -local_velocity_direction.z),
			0.0
		)
	
	var local_direction_target : Vector3 = direction_target * global_transform.basis
	var angles_to_local_direction_target := Vector3(
			atan2(local_direction_target.y, -local_direction_target.z),
			atan2(-local_direction_target.x, -local_direction_target.z),
			0.0#atan2(-local_direction_target.x, local_direction_target.y)
		)
	
	var error := angles_to_local_direction_target - angles_to_local_velocity_direction
	
	var local_desired_acceleration : Vector3 = local_direction_target * linear_velocity.length() - local_velocity_direction * linear_velocity.length() + Vector3(0, 9.8, 0) * global_transform.basis
#	var local_current_force : Vector3 = current_force * global_transform.basis
	var roll_error : float = atan2(-local_desired_acceleration.x, local_desired_acceleration.y) #* Vector2(-local_desired_acceleration.x, local_desired_acceleration.y).length()
	
	error.z = roll_error
	
	direction_pitch_pid.update(delta, error.x)
	direction_yaw_pid.update(delta, error.y)
	direction_roll_pid.update(delta, error.z)
	
	control_input.x += direction_pitch_pid.output
	control_input.y += direction_yaw_pid.output
	control_input.z += direction_roll_pid.output
	
	control_input = control_input.clamp(Vector3(-1, -1, -1), Vector3(1, 1, 1))
	
	#var normal_acceleration = local_acceleration_vector.z

#this should be standardized.
func flight_assist(delta : float) -> void:
	#prevent crashing the aero_PID when airspeed is 0
	#if is_equal_approx(air_speed, 0.0):
		#return

	if air_speed < 5.0:
		pitch_assist_pid._integral_error = 0.0
		yaw_assist_pid._integral_error = 0.0
		roll_assist_pid._integral_error = 0.0

	var angular_rates := max_angular_rates
	
	if enable_g_limiter:
		#g limit
		var g_limited_angular_rate := max_angular_rates.x
		if !is_zero_approx(air_speed):
			var gravity_direction := Vector3(0, -1, 0)
			var zero_effort_g_force : float = global_transform.basis.y.dot(gravity_direction)

			g_limited_angular_rate = (g_limit + zero_effort_g_force) * 9.81 / air_speed
			#for negative g limit
			if control_input.x <= 0.0:
				g_limited_angular_rate = (negative_g_limit - zero_effort_g_force) * 9.81 / air_speed
		
		angular_rates.x = min(angular_rates.x, g_limited_angular_rate)
	#g limit
	
	angular_rate_error = angular_rates * control_input - local_angular_velocity
	
	#flight assist
	#these should be adjusted when the reference frame changes.
	if enable_flight_assist_x:
		control_command.x = pitch_assist_pid.update(delta, angular_rate_error.x)
	if enable_flight_assist_y:
		control_command.y = yaw_assist_pid.update(delta, angular_rate_error.y)
	if enable_flight_assist_z:
		control_command.z = roll_assist_pid.update(delta, angular_rate_error.z)
	
	if enable_aoa_limiter:
		control_command *= clamp(remap(angle_of_attack, deg_to_rad(aoa_limit_start), deg_to_rad(aoa_limit_end), 1, 0), 0, 1)
	
	#adjust for changing airspeed and density
	if enable_control_adjustment:
		control_command *= FlightAssist.get_control_adjustment_factor(air_speed, air_density, tuned_airspeed, tuned_density, min_accounted_airspeed, min_accounted_air_density)
	
	control_command = control_command.clamp(Vector3(-1, -1, -1), Vector3(1, 1, 1))

static func get_control_adjustment_factor(speed : float, density : float, tuned_speed : float = 100.0, _tuned_density : float = 1.222, min_accounted_speed : float = 0.75, min_accounted_density : float = 0.2) -> float:
	var control_adjustment : float = 1.0
	#adjust for airspeed
	var accounted_speed : float = max(min_accounted_speed, speed)
	control_adjustment /= (accounted_speed * accounted_speed) / (tuned_speed * tuned_speed)
	
	#adjust for air density
	var accounted_density : float = max(min_accounted_density, density)
	control_adjustment /= accounted_density / _tuned_density
	
	return control_adjustment
