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

var input := Vector3.ZERO
@export var max_angular_rates := Vector3(0.35, 0.04, 5.0)
var angular_rate_error := Vector3.ZERO
var control_value := Vector3.ZERO
var throttle : float = 0.0

@export_group("Flight Assist")
@export_subgroup("Axes")
@export var enable_flight_assist_x : bool = true
@export var pitch_assist_pid : aero_PID = aero_PID.new()
@export var enable_flight_assist_y : bool = true
@export var yaw_assist_pid : aero_PID = aero_PID.new()
@export var enable_flight_assist_z : bool = true
@export var roll_assist_pid : aero_PID = aero_PID.new()
@export_subgroup("G Limiter")
@export var enable_g_limiter : bool = true
@export var g_limit : float = 9.0
@export var negative_g_limit : float = 3.0
@export_subgroup("AOA Limiter")
@export var enable_aoa_limiter : bool = true
@export var aoa_limit_start : float = 22.0
@export var aoa_limit_end : float = 25.0
@export_subgroup("Tuning")
@export var enable_control_adjustment : bool = false
@export var tuned_airspeed : float = 100.0
@export var min_accounted_airspeed : float = 75.0
@export var tuned_density : float = 1.222
@export var min_accounted_air_density : float = 0.1

@export_group("Autopilot")
@export_subgroup("Bank Angle")
@export var enable_bank_angle_assist : bool = false
@export var bank_angle_target : float = 0.0
@export var bank_angle_pid : aero_PID = aero_PID.new()

@export_subgroup("Speed Hold")
@export var enable_speed_hold : bool = false:
	set(x):
		enable_speed_hold = x
		speed_target = air_speed
@export var speed_target : float = 0.0
@export var speed_pid : aero_PID = aero_PID.new()

@export_subgroup("Altitude Hold")
@export var enable_altitude_hold : bool = false:
	set(x):
		enable_altitude_hold = x
		altitude_target = altitude
@export var altitude_target : float = 0.0
@export var altitude_pid : aero_PID = aero_PID.new()

@export_subgroup("Heading Hold")
@export var enable_heading_hold : bool = false:
	set(x):
		enable_heading_hold = x
		heading_target = heading
@export var heading_target : float = 0.0
@export var heading_pid : aero_PID = aero_PID.new()

@export_subgroup("Target Direction")
@export var enable_target_direction : bool = false
@export var direction_target : Vector3 = Vector3.ZERO
@export var direction_pitch_pid : aero_PID = aero_PID.new()
@export var direction_yaw_pid : aero_PID = aero_PID.new()
@export var direction_roll_pid : aero_PID = aero_PID.new()

@export_subgroup("")
@export_category("")

func update(delta : float) -> void:
	control_value = Vector3.ZERO
	
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
	input.z += bank_angle_pid.output

func speed_hold(delta : float) -> void:
	if not enable_speed_hold:
		return
	speed_pid.update(delta, speed_target - air_speed)
	throttle = speed_pid.output

func altitude_hold(delta : float) -> void:
	if not enable_altitude_hold:
		return
	#shit but works
	altitude_pid.update(delta, altitude_target - altitude)
	input.x += altitude_pid.output

func heading_hold(delta : float) -> void:
	if not enable_heading_hold:
		return
	#shit but works. Also has -180/+180 wrapping issues
	heading_pid.update(delta, heading_target - heading)
	input.y += heading_pid.output


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
	
	input.x += direction_pitch_pid.output
	input.y += direction_yaw_pid.output
	input.z += direction_roll_pid.output
	
	input = input.clamp(Vector3(-1, -1, -1), Vector3(1, 1, 1))
	
	#var normal_acceleration = local_acceleration_vector.z

#this should be standardized.
func flight_assist(delta : float) -> void:
	#prevent crashing the aero_PID when airspeed is 0
	if is_equal_approx(air_speed, 0.0):
		return

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
			if input.x <= 0.0:
				g_limited_angular_rate = (negative_g_limit - zero_effort_g_force) * 9.81 / air_speed
		
		angular_rates.x = min(angular_rates.x, g_limited_angular_rate)
	#g limit
	
	angular_rate_error = angular_rates * input - local_angular_velocity
	
	#flight assist
	#these should be adjusted when the reference frame changes.
	if enable_flight_assist_x:
		control_value.x += pitch_assist_pid.update(delta, angular_rate_error.x)
	if enable_flight_assist_y:
		control_value.y += yaw_assist_pid.update(delta, angular_rate_error.y)
	if enable_flight_assist_z:
		control_value.z += roll_assist_pid.update(delta, angular_rate_error.z)
	
	if enable_aoa_limiter:
		control_value *= clamp(remap(angle_of_attack, deg_to_rad(aoa_limit_start), deg_to_rad(aoa_limit_end), 1, 0), 0, 1)
	
	#adjust for changing airspeed and density
	if enable_control_adjustment:
		control_value *= FlightAssist.get_control_adjustment_factor(air_speed, air_density, tuned_airspeed, tuned_density, min_accounted_airspeed, min_accounted_air_density)
	
	control_value = control_value.clamp(Vector3(-1, -1, -1), Vector3(1, 1, 1))

static func get_control_adjustment_factor(speed : float, density : float, tuned_speed : float = 100.0, _tuned_density : float = 1.222, min_accounted_speed : float = 0.75, min_accounted_density : float = 0.2) -> float:
	var control_adjustment : float = 1.0
	#adjust for airspeed
	var accounted_speed : float = max(min_accounted_speed, speed)
	control_adjustment /= (accounted_speed * accounted_speed) / (tuned_speed * tuned_speed)
	
	#adjust for air density
	var accounted_density : float = max(min_accounted_density, density)
	control_adjustment /= accounted_density / _tuned_density
	
	return control_adjustment
