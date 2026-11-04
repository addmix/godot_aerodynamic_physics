# Aerodynamic Design and Troubleshooting

This is a practical guide to help you create an airplane that actually flies, or to improve an existing design.

# Direction
The forward direction of the aircraft should always face the -Z direction. This doesn't only apply to aircraft, but should apply to all objects in your 3D Godot project (characters, cameras, props, vehicles, items, etc)

# Mirroring
AeroInfluncers all have a built-in mirroring option, available in the inspector as `mirror_axis`. For most aircraft, setting `mirror_axis` to `X` is desired, as it will mirror the aircraft from right to left. This avoids the need of manually duplicating AeroInfluencers and trying to keep the aircraft symmetrical.

Mirroring may produce unwanted results with Propellers, as the propeller and it's blades will be mirrored, while the propeller direction may not be properly mirrored (check/change the control config's `axis_flip_*` setting, if desired)

# Center of mass and lift
The center of lift should always be slightly behind the center of mass. Otherwise, the aircraft is unstable, and likely be impossible to control effectively. 

If the center of lift is too far behind the center of mass, the aircraft will have a tendency to nose-dive, requiring a lot of pitch input to counteract, and it will resist any change in direction. For darts and bombs, this can be desirable to prevent course deviations.

If you are only measuring the lift of the main wings/body, it is acceptable to place that center of lift very slightly in front of the center of mass. However you should make sure that the addition of the elevator/tail or other control surfaces causes the total center of lift to be behind the center of mass. This will produce a very responsive aircraft. The property: `AeroInfluencer3D.omit_from_debug` is useful for this type of tuning. 

# Control deflection angle
Make sure your control deflection angle isn't too small or too large. A good place to start is ~25 degrees. Too much larger of a deflection, and the aerosurface might stall, and any lower, the surface won't use it's full control capability.

# Landing gear placement
Avoid placing landing gear too near the rear of the aircraft. It is best to place the rear landing gear slightly behind the center of mass. The elevator on the aircraft may "lever" the aircraft to increase angle of attack to take off.

# Angle of Incidence
See: [Glossary](glossary.md#aerodynamics) > Incidence
For non-supersonic aircraft, the main wing is rarely parallel to the nose of the aircraft. The main wing is given a few degrees of angle to provide lift without having to pitch the entire aircraft. This helps to create an aircraft that takes off and lands more easily.

# Dihedral Angles
Adding a slight dihedral (upwards tilt) to the wings will improve roll stability. The aircraft will naturally return to level flight. Too much dihedral can cause yaw-coupled oscillations (dutch-roll).

# Simulation Stability/Vibration
If the aircraft vibrates violently at speed or "blows up" and causes the aircraft to disappear, it's usually one of: 
- mass configured too low (still using the default mass (40kg)?)
- an AeroSurface sized too large for the aircraft's mass (if you're copying a real airplane, also copy it's real-world mass)
- Collision shapes are too small, or don't encompass the entire aircraft. (Godot calculates rotational inertia based on the size and position of collision shapes. Make sure the wings have collision)
- Flight assist is improperly tuned (disable flight assist, test again. If oscillation disappears, troubleshoot your [flight assist settings](../getting_started/getting_started.md#configuring-flight-assist))

If none of the above work, it may just be that the simulation timestep is too large for the simulation to converge on a stable result. In this case, you can try:

- too few physics substeps, increase the `substeps_override` on your AeroBody3D (if you don't see an improvement by ~8 substeps, it's likely that substeps will not fix the problem)

# Propeller Torque
Large propellers cause torque on the aircraft (see: equal and opposite reaction). Meaning that propeller-driven aircraft can develop unwanted roll and yaw tendencies. Some airspeed is required for the wings and other control surfaces to be able to counteract the torque of the propeller.

This can also be avoided with a variable-pitch propeller, which has a lower blade pitch at slower speeds.

See: P-factor

# Moment Arms and Control Surface Sizing
Control surfaces use leverage to act on the aircraft. A small surface placed far away from the center of mass (like an elevator at the end of a long tail) can provide more control than a larger surface placed close to the center of mass. If your aircraft has issues with control response, and you're certain that the center of lift/mass relationship is correct, as well as control deflections being configured properly, try moving control surfaces further out or away from the center of mass.