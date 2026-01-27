# Control Theory
What are PIDs?

PID is an a acronym representing the control algorithm used, meaning:

- Proportional
- Integral
- Derivative

A PID controller takes in a value, representing the error of a system, and outputs a command that aims to reduce the error.

- Proportional gain gives an output that is directly proportional to the error, though the magnitude of the output is changed by the gain
- Integral tracks how much the error has accumulated over time, and gives an output proportional to that accumulated error.
- Derivative gain gives an output that is proportional to the velocity of the error. This can be thought of as a "damping" force, that opposes movement.

## What are Derivatives, really?

In simple terms, a derivative is the rate of change of some value. Let's look at Position, and it's derivatives.

- Position's first derivative: Velocity

The rate of change of position is velocity. Denoted as (distance/unit). 

Velocity can be calculated by measuring position twice, at a known time interval.
In Godot, you might achieve that using this code: `var velocity = (current_position - previous_position) / delta`

- Position's second derivative: Acceleration

If Velocity is the rate of change of position, an acceleration is the rate of change of velocity, that means acceleration is the rate of change, of the rate of change. That's two layers of derivative, thus being the second order derivative.

Similarly, in godot, you might calculate acceleration using this code: `var acceleration = (current_velocity - previous_velocity) / delta`

- Position's third, fourth, fifth, and sixth derivatives.

The third derivative, jerk, can be useful in many design tasks, as sudden changes in acceleration can be jarring. Think about an elevator starting or stopping or a car turning abruptly.

The further derivatives, in order: Snap, Crackle, and Pop. They aren't useful for most practical applications, but they have a funny naming scheme.

# Applying Control Theory

This plugin makes use of PIDs for much of the functionality of the Flight Assist.

The core functionality of the flight assist compares the angular rate (rotation speed) of the AeroBody (in radians per second) to a desired input angular rate. The difference of these values is the error which is then fed into the flight assist's Assist PIDs. The output of the pids is the control command, which is propagated through the rest of the control system to rotate AeroInfluencers and control the AeroBody.

Now, if you read the section on derivatives, you might have recognized that if we are controlling the aircraft through angular rate, that means we are already at the second derivative, velocity. This is important to recognize as it can change the framing of our PID controls. The derivative response is now no longer velocity, but acceleration. The integral is now keeping track of the angular rate we are supposed to be at, that we have been falling behind (or ahead of).

The basic form of the flight assist is as follows:
```gdscript
angular_rate_error = max_angular_rates * control_input - angular_velocity_in_local_space

# PID.update() returns the output value of the PID
control_command.x = pitch_assist_pid.update(delta, angular_rate_error.x)
control_command.y = yaw_assist_pid.update(delta, angular_rate_error.y)
control_command.z = roll_assist_pid.update(delta, angular_rate_error.z)
```

## G Limiting

While it would be possible to configure a PID that tracks and responds to G forces, it would show a few of the downsides to PIDs. Instead, there is a relationship between linear velocity and angular rate that makes a smarter G limiter. Linear and angular velocity determine the radius of the turn circle, and therefore G-force.

```gdscript
g_limited_angular_rate = g_limit * 9.81 / air_speed
```

## AOA Limiting

AOA limiting prevents the pilot from achieving attitudes that would cause loss of control. This is critical when designing aircraft with relaxed stability.

In the flight assist, this is achieved by defining the AOA at which controls should start to be faded out, and at which AOA the controls should be completely nullified. This behavior is done using the `remap()` function.
```gdscript
control_command *= clamp(remap(angle_of_attack, deg_to_rad(aoa_limit_start), deg_to_rad(aoa_limit_end), 1, 0), 0, 1)
```

There is still opportunity for improvement, as this approach can lead to oscillations in certain scenarios, and cannot fully protect against AOA-related control loss.

## Control Adjustments

### Adjusting for airspeed and density
A major issue when controlling an aircraft is that when air speed and air density increase, the result from an input grow larger. This makes it impossible to tune PIDs that respond optimally to a control input. The secret to how and why this math works lies in the lift and drag formulas:

`lift_magnitude = lift_coefficient * area * 0.5 * air_density * velocity_squared`

Lift forces scale proportionally with changes to air density, while lift forces scale at the square of changes to velocity.

Knowing this, the proper adjustments can be made.

```gdscript
# tuned_speed and tuned_density define the speed and density where the control adjustment will equal 0.0 (no effect)
# The exact value of these shouldn't matter.
#
# The minimum accounted speed and density are used to limit the control adjustment on the low end, as 
# low speeds or low densities might cause the controls to be magnified by a large factor, and contribute 
# to loss of control

static func get_control_adjustment_factor(speed : float, density : float, tuned_speed : float = 100.0, _tuned_density : float = 1.222, min_accounted_speed : float = 0.75, min_accounted_density : float = 0.2) -> float:
	var control_adjustment_factor : float = 1.0

	var accounted_speed : float = max(min_accounted_speed, speed)
	control_adjustment_factor /= (accounted_speed * accounted_speed) / (tuned_speed * tuned_speed)
	
	var accounted_density : float = max(min_accounted_density, density)
	control_adjustment_factor /= accounted_density / _tuned_density
	
	return control_adjustment_factor
```


<!-- ### Adjusting for crosswinds 
not yet implemented
-->

## Autopilot

### Vertical rate control

### Target direction

Autopilot which is able to naturally maneuver the aircraft to point in a desired direction can be used for a few important mechanics.

Better mouse controls:

Games such as War Thunder were revolutionary at their release in no small part due to how approachable they made aerial maneuvers. Players did not need to worry about coordinating their yaw and roll for efficient maneuvers, instead they could use their mouse to point in a direction, and the plane would figure out the hard part. This lead to casual, while still reasonably realistic flight that doesn't require expensive simulator hardware.

Easy path guidance:

Making an aircraft follow a pre-set route can be very important, especially when developing bots. The direction target can use the "mouse control" concept as an abstraction between the decision making bot brain and the inputs required to achieve the desired result, leading to easier and better bot controls.

```gdscript
func target_direction(delta : float) -> void:
	# By default, this function will make the aircraft's nose point at the desired direction
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
	control_input.x += direction_pitch_pid.output
	control_input.y += direction_yaw_pid.output
	control_input.z += direction_roll_pid.output
	
	control_input = control_input.clamp(Vector3(-1, -1, -1), Vector3(1, 1, 1))
    ```

