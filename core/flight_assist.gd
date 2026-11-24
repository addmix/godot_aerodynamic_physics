@tool
extends Resource
class_name FlightAssist

var air_speed : float = 0.0
var air_density : float = 1.0

var angle_of_attack : float = 0.0
var bank_angle : float = 0.0
var heading : float = 0.0
var inclination : float = 0.0

var altitude : float = 0.0

var linear_velocity : Vector3 = Vector3.ZERO
var local_angular_velocity : Vector3 = Vector3.ZERO
var global_transform : Transform3D = Transform3D()
##The load the airframe is carrying, in g, along its own up. Written by the control component each step.
var felt_load : float = 1.0

var control_input := Vector3.ZERO
var control_command := Vector3.ZERO
var throttle_command : float = 0.0
@export var enable_flight_assist : bool = true:
	set(value):
		enable_flight_assist = value
		emit_changed()
##Maximum turn rate (in radians per second) the flight assist will command.
@export var max_angular_rates := Vector3(2, 1, 5.0):
	set(value):
		max_angular_rates = value
		emit_changed()
var angular_rate_error := Vector3.ZERO

@export_group("Flight Assist")
@export_subgroup("Angular rate tracking")
@export var feed_forward : Vector3 = Vector3(1.0, 1.0, 1.0):
	set(value):
		feed_forward = value
		emit_changed()
##If enabled, flight assist is enabled on the pitch (X) axis.
@export var enable_flight_assist_x : bool = true:
	set(value):
		enable_flight_assist_x = value
		emit_changed()
##PID controller used to evaluate appropriate control response.
@export var pitch_assist_pid : aero_PID:
	set(value):
		watch_resource(pitch_assist_pid, value)
		pitch_assist_pid = value
		emit_changed()
##If enabled, flight assist is enabled on the yaw (Y) axis.
@export var enable_flight_assist_y : bool = true:
	set(value):
		enable_flight_assist_y = value
		emit_changed()
##PID controller used to evaluate appropriate control response.
@export var yaw_assist_pid : aero_PID:
	set(value):
		watch_resource(yaw_assist_pid, value)
		yaw_assist_pid = value
		emit_changed()
##If enabled, flight assist is enabled on the roll (Z) axis.
@export var enable_flight_assist_z : bool = true:
	set(value):
		enable_flight_assist_z = value
		emit_changed()
##PID controller used to evaluate appropriate control response.
@export var roll_assist_pid : aero_PID:
	set(value):
		watch_resource(roll_assist_pid, value)
		roll_assist_pid = value
		emit_changed()
@export_subgroup("G Limiter")
##If enabled, the flight assist resource will attempt to keep felt G-forces below the g_limit.
@export var enable_g_limiter : bool = true:
	set(value):
		enable_g_limiter = value
		emit_changed()
##Maximum allowable G-force.
@export var g_limit : float = 9.0:
	set(value):
		g_limit = value
		emit_changed()
@export var g_limit_curve : Curve:
	set(value):
		watch_resource(g_limit_curve, value)
		g_limit_curve = value
		emit_changed()
##Maximum allowable negative G-force.
@export var negative_g_limit : float = 3.0:
	set(value):
		negative_g_limit = value
		emit_changed()
##How hard the load the airframe carries corrects the rate the limiter asks for: above 0 it asks for a faster turn while the load
##is short of the stick's share of the ceiling and a slower one while it is past it. At 0 the limiter trusts the ceiling alone.
@export_range(0.0, 2.0, 0.05) var load_feedback : float = 0.0:
	set(value):
		load_feedback = value
		emit_changed()
@export_subgroup("AOA Limiter")
##If enabled, the flight assist resource will attempt to prevent angle of attack from exceeding this limit.
@export var enable_aoa_limiter : bool = true:
	set(value):
		enable_aoa_limiter = value
		emit_changed()
##Angle of attack (degrees) that control authority begins to decrease.
@export var aoa_limit_start : float = 22.0:
	set(value):
		aoa_limit_start = value
		emit_changed()
##Angle of attack (degrees) that control authority is reduced to 0.
@export var aoa_limit_end : float = 25.0:
	set(value):
		aoa_limit_end = value
		emit_changed()
@export_subgroup("Control Adjustments")
##If enabled, the flight assist will scale its command as the dynamic pressure of the air changes, in an attempt to maintain a consistent control response despite changing airspeed or air density.
@export var enable_control_adjustment : bool = true:
	set(value):
		enable_control_adjustment = value
		emit_changed()
##Airspeed that control adjustments are tuned at.
@export var tuned_airspeed : float = 100.0:
	set(value):
		tuned_airspeed = value
		emit_changed()
##Minimum limit for airspeed adjustment. This prevents controls from losing authority at low speeds due to control surface stalls.
@export var min_accounted_airspeed : float = 75.0:
	set(value):
		min_accounted_airspeed = value
		emit_changed()
##Air density that control adjustments are tuned at.
@export var tuned_density : float = 1.225:
	set(value):
		tuned_density = value
		emit_changed()
##Minimum limit for air density adjustment. This prevents controls from losing authority at low air density due to control surface stalls.
@export var min_accounted_air_density : float = 0.1:
	set(value):
		min_accounted_air_density = value
		emit_changed()
@export var control_rotation : float = 0.0:
	set(value):
		control_rotation = value
		emit_changed()

#a PID or a curve is a resource of its own, and an edit inside one has to reach whoever is listening to the assist
func watch_resource(previous : Resource, next : Resource) -> void:
	if previous and previous.changed.is_connected(emit_changed): previous.changed.disconnect(emit_changed)
	if next and not next.changed.is_connected(emit_changed): next.changed.connect(emit_changed)

@export_group("Autopilot")
@export_subgroup("Bank Angle Target")
##If enabled, the flight assist resource will take control of the bank angle (roll), and attempt to drive it towards [code]bank_angle_target[/code].
@export var enable_bank_angle_assist : bool = false
##Target bank angle that [code]bank_angle_pid[/code] will attempt to maintain.
@export var bank_angle_target : float = 0.0
##PID controller used to evaluate appropriate control response.
@export var bank_angle_pid : aero_PID = aero_PID.new(1, 0.05, 0.1)

@export_subgroup("Heading Target")
##If enabled, the flight assist resource will attempt to maintain heading (yaw) at [code]heading_target[/code].
@export var enable_heading_hold : bool = false:
	set(x):
		enable_heading_hold = x
		heading_target = heading
##Target heading that [code]heading_pid[/code] will attempt to maintain.
@export var heading_target : float = 0.0
##PID controller used to evaluate appropriate control response.
@export var heading_pid : aero_PID = aero_PID.new(10, 0, 0)

@export_subgroup("Inclination Target")
##If enabled, the flight assist resource will attempt to maintain inclination (pitch) at [code]inclination_target[/code].
@export var enable_inclination_hold : bool = false:
	set(x):
		enable_inclination_hold = x
		inclination_target = inclination
##Target heading that [code]heading_pid[/code] will attempt to maintain.
@export var inclination_target : float = 0.0
##PID controller used to evaluate appropriate control response.
@export var inclination_pid : aero_PID = aero_PID.new(10, 0, 0)

@export_subgroup("Speed Target")
##If enabled, the flight assist resource will control throttle, and attempt to maintain airspeed at [code]speed_target[/code].
@export var enable_speed_hold : bool = false:
	set(x):
		enable_speed_hold = x
		speed_target = air_speed
##Target speed that [code]speed_pid[/code] will attempt to maintain.
@export var speed_target : float = 0.0
##PID controller used to evaluate appropriate control response.
@export var speed_pid : aero_PID = aero_PID.new(0, 0.4, 0)

@export_subgroup("Altitude Target")
##If enabled, the flight assist resource will attempt to maintain altitude at [code]altitude_target[/code].
@export var enable_altitude_hold : bool = false:
	set(x):
		enable_altitude_hold = x
		altitude_target = altitude
##Target altitude that [code]altitude_pid[/code] will attempt to maintain.
@export var altitude_target : float = 0.0
##PID controller used to evaluate appropriate control response.
@export var altitude_pid : aero_PID = aero_PID.new(0.001, 0, 0.01)

@export_subgroup("Target Direction")
##If enabled, the flight assist resource will attempt to point the -Z axis of the aircraft towards the given direction target.
@export var enable_target_direction : bool = false
##If enabled, the direction target will try to steer the velocity vector to match the given direction target.
@export var use_velocity_vector_for_targetting : bool = false
##If enabled, yaw will be selectively disabled when the direction target is more than 90 degrees from the current direction.
@export var disable_yaw_on_immelmann : bool = true
##Target direction that direction PIDs will attempt to maintain.
@export var direction_target : Vector3 = Vector3.ZERO
##PID controller used to evaluate appropriate control response.
@export var direction_pitch_pid : aero_PID = aero_PID.new(10, 0.3, 4)
##PID controller used to evaluate appropriate control response.
@export var direction_yaw_pid : aero_PID = aero_PID.new(25, 0, 0)
##PID controller used to evaluate appropriate control response.
@export var direction_roll_pid : aero_PID = aero_PID.new(0.8, 0, 0)

@export_subgroup("")
@export_category("")

func update(delta : float) -> void:
	if not enable_flight_assist:
		control_command = control_input
		return
	
	bank_angle_hold(delta)
	heading_hold(delta)
	inclination_hold(delta)
	altitude_hold(delta)
	speed_hold(delta)
	target_direction(delta)
	flight_assist(delta)

func bank_angle_hold(delta : float) -> void:
	if not enable_bank_angle_assist and not enable_altitude_hold and not enable_heading_hold:
		return
	bank_angle_pid.update(delta, bank_angle_target - bank_angle)
	control_input.z += bank_angle_pid.output

func heading_hold(delta : float) -> void:
	if not enable_heading_hold:
		return
	#shit but works. Also has -180/+180 wrapping issues
	heading_pid.update(delta, heading_target - heading)
	control_input.y += heading_pid.output

func inclination_hold(delta : float) -> void:
	if not enable_inclination_hold:
		return
	#shit but works. Also has -180/+180 wrapping issues
	inclination_pid.update(delta, inclination_target - inclination)
	control_input.x += inclination_pid.output

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


func target_direction(delta : float) -> void:
	if not enable_target_direction:
		return
	
	
	
	var local_direction_target : Vector3 = direction_target * global_transform.basis
	var angles_to_local_direction_target := Vector3(
		atan2(local_direction_target.y, -local_direction_target.z),
		atan2(-local_direction_target.x, -local_direction_target.z),
		atan2(-local_direction_target.x, local_direction_target.y)
	)
	var error := angles_to_local_direction_target # <-- Calculating error? That's for a PID!
	
	# For more precise flying, it may be desirable to point the velocity vector at the target direction instead
	var local_velocity_direction : Vector3 = linear_velocity.normalized() * global_transform.basis
	if use_velocity_vector_for_targetting:
		if linear_velocity.is_equal_approx(Vector3.ZERO):
			return
		var angles_to_local_velocity_direction := Vector3(
				atan2(local_velocity_direction.y, -local_velocity_direction.z),
				atan2(-local_velocity_direction.x, -local_velocity_direction.z),
				atan2(-local_velocity_direction.x, local_velocity_direction.y)
			)
		
		error = angles_to_local_direction_target - angles_to_local_velocity_direction
	
	var horizontal_component : float = Vector2(local_direction_target.x, local_direction_target.z).length() / maxf(local_direction_target.length(), 0.0001)
	error.y *= smoothstep(0.0, 0.3, horizontal_component)
	
	# When the desired direction is more than 90 degrees away from the current direction,
	# yaw is usually undesirable. because the >90 degree target passes the polar origin of the yaw
	# 
	# Using yaw may still be desirable on radially symmetric craft, such as missiles and rockets.
	if disable_yaw_on_immelmann and abs(error.x) >= deg_to_rad(90.0):
		error.y = 0.0 #disable yaw when pointing backwards, stops an annoying oscillation
	
	# The controls would be unnatural without roll
	# This calculates how much roll is needed to align the felt G-forces with the aerobody's
	# local Y axis (up). This results in the aerobody rolling into maneuvers in a realistic way.
	var local_desired_acceleration : Vector3 = local_direction_target * linear_velocity.length() - local_velocity_direction * linear_velocity.length() + Vector3(0, 9.8, 0) * global_transform.basis
	var roll_error : float = -local_desired_acceleration.x
	
	error.z = roll_error
	
	
	# Feed the error we calculated into PIDs
	# In most cases, these PIDs are (P:1, I:0, D:0), because that's all that is needed.
	direction_pitch_pid.update(delta, error.x)
	direction_yaw_pid.update(delta, error.y)
	direction_roll_pid.update(delta, error.z)
	
	# The result of those PIDs is applied to the control input.
	#TODO: add option so that previous inputs can override these inputs
	control_input.x += direction_pitch_pid.output
	control_input.y += direction_yaw_pid.output
	control_input.z += direction_roll_pid.output
	
	control_input = control_input.clamp(Vector3(-1, -1, -1), Vector3(1, 1, 1))
	
	#var normal_acceleration = local_acceleration_vector.z

func g_limit_at(speed : float) -> float:
	if g_limit_curve == null or g_limit_curve.point_count == 0 or speed <= 0.0:
		return g_limit
	return minf(g_limit, g_limit_curve.sample(speed))

#this should be standardized.
func flight_assist(delta : float) -> void:
	#prevent crashing the aero_PID when airspeed is 0
	#if is_equal_approx(air_speed, 0.0):
		#return

	#if air_speed < 0.1:
		#pitch_assist_pid._integral_error = 0.0
		#yaw_assist_pid._integral_error = 0.0
		#roll_assist_pid._integral_error = 0.0
		#return #prevents unnecessary input commands
	
	#control_input = control_input.rotated(Vector3(0, 1, 0), control_rotation)

	var angular_rates := max_angular_rates
	
	#the pitch demand is a load, not a share of a rate: neutral asks for level flight and the stick moves away from it in either
	#direction, so letting go of a pull asks the airframe to hold a g rather than to stop turning
	var pitch_rate : float = angular_rates.x * control_input.x
	
	if enable_g_limiter and !is_zero_approx(air_speed):
		var limit := g_limit_at(air_speed)
		var gravity_direction := Vector3(0, -1, 0)
		var zero_effort_g_force : float = global_transform.basis.y.dot(gravity_direction)
		
		var load_per_control_unit : float = limit - 1.0 if control_input.x >= 0.0 else negative_g_limit + 1.0
		var requested_load : float = 1.0 + control_input.x * load_per_control_unit
		#only under the request: a term that pulls down as well leaves the airframe under the load it was asked to keep, which at low
		#speed is a pushover into negative g
		var load_error : float = maxf(0.0, requested_load - felt_load)
		var commanded_load : float = requested_load + load_feedback * load_error
		
		pitch_rate = clampf((commanded_load + zero_effort_g_force) * 9.81 / air_speed, -angular_rates.x, angular_rates.x)
	#g limit
	
	angular_rate_error = Vector3(pitch_rate, angular_rates.y * control_input.y, angular_rates.z * control_input.z) - local_angular_velocity
	
	#this is added to update/apply input changes from previous steps, such as target_direction
	#without this line, controls can break when flight assist axes are disabled.
	control_command = control_input * feed_forward
	if enable_flight_assist_x and pitch_assist_pid:
		control_command.x += pitch_assist_pid.update(delta, angular_rate_error.x)
	if enable_flight_assist_y and yaw_assist_pid:
		control_command.y += yaw_assist_pid.update(delta, angular_rate_error.y)
	if enable_flight_assist_z and roll_assist_pid:
		control_command.z += roll_assist_pid.update(delta, angular_rate_error.z)
	
	#adjust for changing airspeed and density
	if enable_control_adjustment:
		control_command *= FlightAssist.get_control_adjustment_factor(air_speed, air_density, tuned_airspeed, tuned_density,
			min_accounted_airspeed, min_accounted_air_density)
	
	control_command = control_command.clamp(Vector3(-1, -1, -1), Vector3(1, 1, 1))
	
	if enable_aoa_limiter:
		control_command *= clamp(remap(abs(angle_of_attack), deg_to_rad(aoa_limit_end), deg_to_rad(aoa_limit_start), 0, 1), 0, 1)

	if enable_aoa_limiter:
		control_command *= clamp(remap(abs(angle_of_attack), deg_to_rad(aoa_limit_end), deg_to_rad(aoa_limit_start), 0, 1), 0, 1)

static func get_control_adjustment_factor(speed : float, density : float, tuned_speed : float = 100.0, tuned_density : float = 1.222, min_accounted_speed : float = 0.75, min_accounted_density : float = 0.02) -> float:
	#control authority follows dynamic pressure, ½ρV², so the factor takes the air back to the pressure the assist was
	#tuned at. the floors stop slow or thin air from magnifying the controls without bound
	var accounted_speed : float = max(min_accounted_speed, speed)
	var accounted_density : float = max(min_accounted_density, density)
	var tuned_pressure : float = 0.5 * tuned_density * tuned_speed * tuned_speed
	var dynamic_pressure : float = 0.5 * accounted_density * accounted_speed * accounted_speed
	return tuned_pressure / dynamic_pressure
