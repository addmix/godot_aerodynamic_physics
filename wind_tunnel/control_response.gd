@tool
extends RefCounted
##Measures how an aircraft answers its controls, so a graph can draw it and a tuner can read it.
##
##The step is stepped by hand from the state the body is handed in, so it needs no physics server and no frames: at each step the
##airframe is asked for its forces and the state is integrated from them. it places nothing and trims nothing, it drives the stick and
##records the answer. the airframe's own answer, the moment a command produces and how far the surfaces have come toward it, needs no
##flight at all.

#one run's samples, every array the same length and one entry per step
class Trace:
	var axis := "pitch"
	var speed := 0.0
	var altitude := 0.0
	var g_limit := 0.0
	var commanded_rate := PackedFloat32Array()
	var achieved_rate := PackedFloat32Array()
	var command := PackedFloat32Array()
	var feed_forward := PackedFloat32Array()
	var proportional := PackedFloat32Array()
	var integral := PackedFloat32Array()
	var derivative := PackedFloat32Array()
	var load := PackedFloat32Array()
	var seconds := 0.0
	
	#the times the samples were taken at, evenly spaced over the run
	func times() -> PackedFloat32Array:
		var stamps := PackedFloat32Array()
		var step := seconds / maxf(commanded_rate.size(), 1.0)
		for index : int in commanded_rate.size():
			stamps.append(step * index)
		return stamps
	
	#the command the assist asked for before the g and AoA limiters had their say: the parts added up
	func requested() -> PackedFloat32Array:
		var total := PackedFloat32Array()
		for index : int in command.size():
			total.append(feed_forward[index] + proportional[index] + integral[index] + derivative[index])
		return total

#the axes every aircraft names its control axes by, in the order a moment or a rate names its components
const AXES : Array[String] = ["pitch", "yaw", "roll"]

#how many commands each axis is swept through, from one end of its travel to the other
const EFFECTIVENESS_STEPS := 21

#a step long enough that a surface whose movement is speed limited reaches the deflection it is asked for
const SETTLE_STEP := 10.0

#how far a surface has to be deflected by a step before its response is worth drawing
const MIN_MOVED_DEFLECTION := 0.5

#which component of a vector each axis name means
static func axis_index(axis : String) -> int:
	return maxi(AXES.find(axis.to_lower()), 0)

#the surfaces a control command moves, which are the parts carrying a control config that is enabled
static func actuated_surfaces(body : AeroBody3D) -> Array[AeroInfluencer3D]:
	var surfaces : Array[AeroInfluencer3D] = []
	for node : Node in body.find_children("*", "AeroInfluencer3D", true, false):
		var influencer := node as AeroInfluencer3D
		if influencer.actuation_config and influencer.actuation_config.enable_control: surfaces.append(influencer)
	
	return surfaces

#every control axis held at nothing, so the command of one is never read on top of another
static func neutral_commands(component : AeroControlComponent) -> void:
	for config : AeroControlConfigAxis in component.control_config.axis_configs:
		config.command = 0.0

#the angular acceleration a command of this axis asks of the airframe, held level in this air. the command is set straight on
#the surfaces, so the flight assist is not in the way of what the airframe itself answers with
static func effectiveness(body : AeroBody3D, component : AeroControlComponent, axis : String, speed : float, altitude : float) -> PackedVector2Array:
	var curve := PackedVector2Array()
	if component == null: return curve
	
	axis = axis.to_lower()
	var index := axis_index(axis)
	var attitude := Transform3D(Basis.IDENTITY, Vector3(0, altitude, 0))
	var velocity := Vector3(0, 0, -speed)
	var inertia : float = body.get_moment_of_inertia()[index]
	var surfaces := actuated_surfaces(body)
	
	#a surface reads where it sits on the aircraft, which is worked out as the forces are: without one evaluation first, the very
	#first command would find every surface at the middle of the aircraft and move none of them
	body.calculate_forces_manual(attitude, velocity, Vector3.ZERO, altitude)
	
	for step : int in EFFECTIVENESS_STEPS:
		var command : float = lerpf(-1.0, 1.0, step / float(EFFECTIVENESS_STEPS - 1))
		neutral_commands(component)
		component.set_control_command(axis, command)
		
		#the surfaces are driven to the deflection the command holds them at before the forces are read, so a surface whose
		#movement is speed limited does not read as a weak one
		for influencer : AeroInfluencer3D in surfaces: influencer.actuation_config.update(influencer, SETTLE_STEP)
		
		var reading := body.calculate_forces_manual(attitude, velocity, Vector3.ZERO, altitude)
		curve.append(Vector2(command, reading[1][index] / inertia))
	
	neutral_commands(component)
	return curve

#one tick of the control component, in its own order: the axes smooth their inputs, then the assist asks for the surfaces. the
#frame's forces are worked out after this, so the command is the one the aircraft flies the step with
static func step_controls(component : AeroControlComponent, delta : float) -> void:
	component.control_config.update(delta)
	component.update_flight_assist(delta)

#the PID the assist steers one axis with
static func axis_pid(assist : FlightAssist, index : int) -> aero_PID:
	match index:
		1: return assist.yaw_assist_pid
		2: return assist.roll_assist_pid
	return assist.pitch_assist_pid

#steps one axis from where the aircraft is and records the answer for `seconds`. the state is stepped by hand from the one the
#body is handed in: no physics server and no frames, so the run costs its calculation time rather than its flight time. the body is
#held at the transform it arrived with, and the rotation a step would take is turned into the airflow instead, so the wings meet the
#air at the angle they would have while the g limiter sees one attitude
static func fly(body : AeroBody3D, component : AeroControlComponent, axis : String, seconds : float) -> Trace:
	#the axes are named in lower case on every aircraft, while a menu is free to capitalize what it shows
	axis = axis.to_lower()
	
	var transform := body.global_transform
	var basis := transform.basis
	var inverse_basis := basis.inverse()
	var up := basis.y
	var altitude := transform.origin.y
	var velocity := body.linear_velocity
	var rate := Vector3.ZERO
	var speed := velocity.length()
	var mass := body.mass
	var inertia : Vector3 = body.get_moment_of_inertia()
	
	var gravity : Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity_vector", Vector3(0, -1, 0))
	gravity *= float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)) * body.gravity_scale
	
	var delta : float = 1.0 / float(Engine.physics_ticks_per_second)
	var steps : int = maxi(roundi(seconds / delta), 1)
	
	var trace := Trace.new()
	trace.axis = axis
	trace.seconds = seconds
	trace.speed = speed
	trace.altitude = altitude
	trace.g_limit = component.flight_assist.g_limit
	
	#only the step drives the aircraft: a held key must not join in, and an axis whose actions are not in the project would report
	#a missing action every step
	for config : AeroControlConfigAxis in component.control_config.axis_configs:
		config.use_bindings = false
		config.input = 1.0 if config.axis_name == axis else 0.0
	var assist : FlightAssist = component.flight_assist
	var index := axis_index(axis)
	var pid := axis_pid(assist, index)
	
	#one evaluation at the condition says what the air is before the first control tick reads it
	body.calculate_forces_manual(transform, velocity, Vector3.ZERO, altitude)
	
	for step : int in steps:
		#the component's own tick: the axes smooth their inputs, then the assist asks for the surfaces
		component.control_config.update(delta)
		component.update_flight_assist(delta)
		
		#the airframe's answer to those surfaces
		var reading := body.calculate_forces_manual(transform, velocity, basis * rate, altitude, NAN, NAN, gravity, delta)
		
		#the assist keeps the error between the rate it asked for and the rate the aircraft had, so the setpoint is the two added
		#back together, which is the demand after the g and AoA limiters had their say
		trace.commanded_rate.append(assist.angular_rate_error[index] + assist.local_angular_velocity[index])
		trace.achieved_rate.append(rate[index])
		trace.command.append(assist.control_command[index])
		#the felt load is the airframe's force along its own up over the weight
		trace.load.append(reading[0].dot(up) / (mass * 9.81))
		
		#the parts the command was built from, each scaled the way the assist scales the whole of it, so a graph can say which of
		#them asked for what. the g and AoA limiters come after this, so a command they clip sits below the sum of the parts
		var scale := 1.0
		if assist.enable_control_adjustment:
			scale = FlightAssist.get_control_adjustment_factor(assist.air_speed, assist.air_density, assist.tuned_airspeed,
				assist.tuned_density, assist.min_accounted_airspeed, assist.min_accounted_air_density)
		trace.feed_forward.append(assist.control_input[index] * assist.feed_forward[index] * scale)
		trace.proportional.append((pid.proportional_output if pid else 0.0) * scale)
		trace.integral.append((pid.integral_output if pid else 0.0) * scale)
		trace.derivative.append((pid.derivative_output if pid else 0.0) * scale)
		
		#step the state: the turn the body would take is not taken, it is turned into the airflow instead, so the attitude stays where
		#it was placed and the wings still meet the air at the angle they would have. the speed is put back as well, so the condition
		#does not drift away from the one being measured
		var turn := Basis(rate.normalized(), rate.length() * delta) if rate.length() > 0.0001 else Basis()
		var turned := basis * turn * inverse_basis
		velocity = turned.inverse() * (velocity + (reading[0] / mass + gravity) * delta)
		if velocity.length() > 0.001: velocity = velocity.normalized() * speed
		rate += (inverse_basis * reading[1] / inertia) * delta
	
	return trace

#one surface's deflection through a step, so the time it takes over it can be drawn
class Deflection:
	var surface := ""
	var points := PackedVector2Array()

#how far every surface that answers this axis is deflected through a step of it. a surface whose movement is speed limited takes
#longer to reach the deflection the command asks for, which is what this shows. only the surfaces that move come back
static func deflection_step(body : AeroBody3D, component : AeroControlComponent, axis : String, seconds : float) -> Array[Deflection]:
	axis = axis.to_lower()
	var responses : Array[Deflection] = []
	if component == null: return responses
	
	#a surface reads where it sits on the aircraft, which is worked out as the forces are
	body.calculate_forces_manual(body.global_transform, Vector3.ZERO, Vector3.ZERO, body.global_transform.origin.y)
	
	var surfaces := actuated_surfaces(body)
	var delta := 1.0 / float(Engine.physics_ticks_per_second)
	
	#every surface starts at neutral, wherever a run before this one left it
	neutral_commands(component)
	for influencer : AeroInfluencer3D in surfaces: influencer.actuation_config.update(influencer, SETTLE_STEP)
	
	for influencer : AeroInfluencer3D in surfaces:
		var response := Deflection.new()
		response.surface = influencer.name
		responses.append(response)
	
	component.set_control_command(axis, 1.0)
	
	var elapsed := 0.0
	while elapsed < seconds:
		for influencer : AeroInfluencer3D in surfaces: influencer.actuation_config.update(influencer, delta)
		for index : int in surfaces.size():
			responses[index].points.append(Vector2(elapsed, rad_to_deg(surfaces[index].actuation_config.current_value.length())))
		elapsed += delta
	
	#a surface that ends the step deflected is one the axis answers, whether it took its time getting there or went at once
	var moving : Array[Deflection] = []
	for response : Deflection in responses:
		if absf(response.points[response.points.size() - 1].y) >= MIN_MOVED_DEFLECTION:
			moving.append(response)
	
	return moving
