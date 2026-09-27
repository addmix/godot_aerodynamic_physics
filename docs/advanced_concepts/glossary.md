# Aerodynamics & Hydrodynamics Glossary

Not all terms defined here are simulated or present in the plugin — this is a reference glossary. Aerodynamics terms are grouped first (with Aircraft Configuration at the top, since it's the most frequently referenced section), followed by Hydrodynamics/buoyancy terms.

---

# AERODYNAMICS

## 1. Aircraft Configuration

**Overall configuration**
- **Conventional aircraft** — An aircraft with a main wing, rear horizontal stabilizer, and vertical stabilizer.
- **Canard aircraft** — An aircraft using a forward canard surface instead of a conventional rear horizontal tail.
- **Tailless aircraft** — An aircraft without a conventional horizontal tail.
- **Flying wing** — A tailless aircraft in which the fuselage and wing are integrated into a primarily lifting body.
- **Blended wing-body** — An aircraft in which the fuselage and wings transition smoothly into one another.
- **V-tail aircraft** — An aircraft using a V-shaped tail in which the surfaces provide both pitch and yaw control.
- **Twin-boom aircraft** — An aircraft with two longitudinal fuselage structures extending aft from the wing.
- **Three-surface aircraft** — An aircraft using a main wing, forward canard, and rear horizontal stabilizer.

**Wing position**
- **High wing** — Mounted near the top of the fuselage (e.g. Cessna 172).
- **Mid wing** — Mounted approximately at the fuselage midline (e.g. Su-47).
- **Low wing** — Mounted near the bottom of the fuselage (e.g. P-51).
- **Parasol wing** — Mounted above the fuselage, supported by struts or other structure (e.g. PBY Catalina).

**Wing arrangement**
- **Monoplane** — A single main wing plane.
- **Biplane** — Two vertically stacked wing planes.
- **Triplane** — Three vertically stacked wing planes.
- **Tandem wing** — Two main wings arranged longitudinally, one behind the other.
- **Joined wing** — Forward and rear wings joined at or near their tips.
- **Box wing** — Forward and rear wings joined to form a closed or nearly closed structure.

**Wing planform**
- **Rectangular** — Approximately constant chord along the span.
- **Tapered** — Chord decreases toward the tip.
- **Elliptical** — Planform approximates an ellipse.
- **Delta** — Highly swept, triangular wing.
- **Cropped delta** — A delta wing with its tip truncated.
- **Ogive** — A curved, highly swept wing planform.
- **Swept wing** — Quarter-chord/reference line angled rearward relative to the lateral axis.
- **Forward-swept wing** — Reference line angled forward relative to the lateral axis.
- **Variable-sweep wing** — Sweep angle can be changed during flight.

**Wing geometry**
- **Aspect ratio** — The relationship between wing span and wing area.
- **Taper ratio** — Ratio of tip chord to root chord.
- **Wing loading** — Aircraft weight divided by wing area (see also Aerodynamic Performance).
- **Mean aerodynamic chord (MAC)** — The chord length representative of a wing's aerodynamic characteristics.
- **Root chord** / **Tip chord** — Chord length at the wing root / tip.
- **Span** — Distance from one wingtip to the other.
- **Wing area** — The planform area of the wing.
- **Sweep angle** — Angle at which a wing is swept relative to a reference lateral axis.
- **Dihedral angle** — Angle at which a wing inclines upward (**dihedral**) or downward (**anhedral**) relative to the lateral plane.
- **Twist** — Change in geometric angle of incidence along the span: **wash-in** (increasing toward the tip) or **washout** (decreasing toward the tip).
- **Wing incidence** (also called **angle of incidence**) — Angle between the wing's reference chord and the aircraft's longitudinal reference axis.
- **Decalage** — The difference in angle of incidence between two lifting surfaces (e.g. front and rear wing on a biplane or tandem-wing aircraft, or wing vs. tail on a conventional/three-surface/canard aircraft).

**Tail configuration**
- *Horizontal:* **Conventional tail** (mounted at/near the base of the vertical stabilizer), **T-tail** (near the top), **Cruciform tail** (partway up), **H-tail** (two vertical stabilizers connected by a horizontal stabilizer).
- **Stabilizer incidence (tail incidence)** — The fixed angle of the horizontal stabilizer relative to the fuselage reference line; distinct from wing incidence, and the difference between the two is the **decalage** (see Wing Geometry, above).
- *Vertical:* **Single vertical stabilizer**, **Twin-tail** (two, typically either side of fuselage or on the horizontal tail), **Triple-tail** (three), **Canted tail** (angled outward from vertical), **V-tail** (two angled surfaces combining pitch and yaw control).
- *Canard:* **Canard** (a small lifting/control surface forward of the main wing), **Close-coupled canard** (positioned close to the main wing for strong aerodynamic interaction), **Foreplane** (a forward surface used for lift, stability, or control).

**Airframe components**
- **Fuselage** — The main body of the aircraft, housing the crew, passengers, cargo, and (in most configurations) providing the structural link between wing, tail, and landing gear.
- **Empennage** — The tail assembly as a whole: the horizontal and vertical stabilizers together with their control surfaces.
- **Cockpit / Flight deck** — The compartment from which the aircraft is piloted.
- **Nacelle** — A streamlined housing, separate from the fuselage, that encloses an engine or other equipment (e.g. on a wing-mounted or pod-mounted engine).
- **Pylon** — A structural mount attaching an engine, nacelle, or store to the wing or fuselage.
- **Cowling** — A removable panel or set of panels enclosing an engine, typically shaped to manage cooling airflow and reduce drag.
- **Fairing** — A structure added to smooth a shape and reduce drag or interference drag, typically at a wing-fuselage junction, landing-gear well, or other discontinuity.
- **Landing gear** — The undercarriage assembly that supports the aircraft on the ground; a significant source of parasite drag when extended (see Drag).
- **Fixed gear** — Landing gear that remains extended in flight.
- **Retractable gear** — Landing gear that folds into the fuselage or wing in flight to reduce drag.
- **Tricycle gear** — Landing-gear arrangement with a nose wheel forward and two main wheels aft of the center of gravity.
- **Tailwheel (conventional) gear** — Landing-gear arrangement with two main wheels forward and a small wheel or skid at the tail.
- **Nose gear** / **Main gear** — The forward wheel assembly / the primary (typically paired) wheel assemblies supporting most of the aircraft's weight.
- **Skid** — A landing-gear runner, without wheels, used on some rotorcraft and specialized aircraft.
- **Float** — A buoyant landing-gear structure used in place of wheels for operation from water (bridges to Hydrodynamics — see Buoyancy).

## 2. Stability and Control

**Aircraft axes**
- **Longitudinal axis** — Nose-to-tail axis.
- **Lateral axis** — Side-to-side axis.
- **Vertical axis** — Vertical axis through the aircraft.

**Stability**
- **Static stability**, **Longitudinal stability** (stability in pitch), **Lateral stability** (stability in roll), **Directional stability** (stability in yaw).
- **Neutral stability** — A disturbance produces neither a restoring nor a diverging response.
- **Static instability** — A disturbance produces a response that moves the aircraft farther from its original state.
- **Dynamic stability** — The aircraft's behavior over time following a disturbance.

**Stability concepts**
- **Center of gravity** — Point at which the aircraft's mass can be considered concentrated.
- **Center of lift** — The effective point at which the net lift force acts.
- **Neutral point** — The aerodynamic center of the complete aircraft, for longitudinal stability.
- **Static margin** — Distance between center of gravity and neutral point, normally expressed relative to MAC.
- **Sideslip (sideslip angle)** — The angle between the aircraft's longitudinal axis and its direction of travel through the air (the relative wind); a nonzero sideslip angle is what the roll and yaw stability derivatives respond to.

**Stability derivatives**
- **Pitch stability derivative** — Change in pitching moment resulting from a change in angle of attack.
- **Roll stability derivative** — Change in rolling moment resulting from a change in sideslip (often called the *dihedral effect* when driven by wing dihedral).
- **Yaw stability derivative** — Change in yawing moment resulting from a change in sideslip.
- **Control derivatives** — Derivatives describing changes in aerodynamic forces or moments resulting from control-surface inputs.

## 3. Control Surfaces

**Primary**
- **Elevator** — Primarily controls pitch.
- **Rudder** — Primarily controls yaw.
- **Aileron** — Primarily controls roll.

**Aileron types**
- **Differential aileron** — Upward and downward deflections are unequal.
- **Frise aileron** — The nose projects into the airflow when deflected upward, increasing drag on that side to help reduce **adverse yaw**.
- **Adverse yaw** — A yawing tendency away from the direction of a roll input, caused by the differing induced drag of the up-going and down-going ailerons.

**Combined control surfaces**
- **Elevon** — Combines elevator and aileron functions.
- **Flaperon** — Combines flap and aileron functions.
- **Ruddervator** — Combines rudder and elevator functions; commonly used with V-tails.
- **Spoileron** — A spoiler used asymmetrically to provide roll control.
- **Stabilator** — An all-moving horizontal stabilizer used for pitch control.

**Secondary control surfaces**
- **Trim tab** — Reduces the control force required to maintain a desired attitude.
- **Servo tab** — Uses aerodynamic forces to assist movement of the primary control surface.
- **Balance tab** — Reduces the aerodynamic force required to move a control surface.
- **Anti-servo tab** — Moves with the primary control surface, increasing control force/feel.

**Spoilers**
- **Spoiler** — A movable surface that disrupts airflow over a wing, reducing lift and generally increasing drag.

## 4. High-Lift Devices

**Trailing-edge flaps**
- **Flap** — A movable trailing-edge surface used primarily to increase lift at low speeds.
- **Plain flap** — A hinged flap that rotates down from the trailing edge with no slot or extension.
- **Split flap** — Deflects from the lower surface only, while the upper surface stays fixed; adds more drag than lift.
- **Slotted flap** — Deflects downward while opening a slot that channels high-energy air over its upper surface, delaying separation.
- **Fowler flap** — Extends aft and downward, increasing both wing area and camber.
- **Double-slotted flap** / **Triple-slotted flap** — Add one or two further slots beyond a slotted flap for additional lift augmentation.
- **Zap flap** — Extends rearward along a track before deflecting downward, increasing area similarly to a Fowler flap.

**Leading-edge devices**
- **Slat** — Delays flow separation and increases maximum lift.
- **Automatic slat** — Extends automatically from aerodynamic pressure differences rather than actuation.
- **Krueger flap** — Hinges forward/down from the lower surface to increase camber and delay leading-edge separation.
- **Leading-edge flap** — A hinged leading-edge surface that deflects down to increase camber and stall angle of attack.
- **Drooped leading edge** — A fixed or deflected downward-curved leading-edge shape for improved high-AoA performance.

**Other high-lift concepts**
- **Blown flaps** — Use engine bleed air or exhaust blown over the flap to delay separation and increase lift.
- **Boundary-layer control** — Techniques (suction, blowing) used to manage the boundary layer and delay separation.

## 5. Lift

- **Lift coefficient** — Dimensionless coefficient describing lift relative to dynamic pressure, reference area, and flow conditions.
- **Dynamic pressure** — Represents the kinetic energy density of a moving fluid.
- **Circulation** — A measure of the integrated tangential velocity around a closed path.
- **Pressure distribution** — Variation of pressure across an aerodynamic surface.
- **Center of pressure** — Point at which net aerodynamic force can be considered to act.
- **Aerodynamic center** — Point about which pitching moment stays approximately constant as AoA changes.
- **Elliptical lift distribution** — Idealized spanwise lift distribution associated with minimum induced drag for a given lift and span.
- **Spanwise lift distribution** — Distribution of lift along a wing's span.
- **Induced angle of attack** — Change in effective AoA caused by the wing's own induced airflow.

## 6. Drag

- **Form drag** — Drag from pressure differences associated with a body's shape.
- **Skin-friction drag** — Drag from viscous shear between airflow and the surface.
- **Interference drag** — Additional drag from aerodynamic interaction between components.
- **Profile drag** — Drag associated with a surface's aerodynamic profile, generally pressure + skin-friction effects.
- **Induced drag** — Drag generated as a consequence of producing lift.
- **Wave drag** — Drag from shock waves and compressibility effects, especially transonic/supersonic.
- **Drag polar** — The relationship between lift coefficient and drag coefficient.
- **Lift-to-drag ratio** — Ratio of aerodynamic lift to aerodynamic drag.
- **Oswald efficiency factor** — Describes how closely a wing's induced drag approaches that of an ideal elliptical lift distribution.

## 7. Airfoils

- **Airfoil** — A 2-D cross-sectional profile of an aerodynamic surface.
- **Symmetrical airfoil** — Identical upper/lower surface geometry about the chord line (no camber).
- **Cambered airfoil** — Mean camber line is curved relative to the chord line.
- **Reflexed airfoil** — A cambered airfoil whose trailing edge curves upward.
- **Supercritical airfoil** — Designed to delay/reduce shock formation at transonic speeds.
- **Laminar-flow airfoil** — Designed to maintain laminar flow over a relatively large portion of its surface.
- **Chord** / **Chord line** — Straight-line distance / line between leading and trailing edge.
- **Mean camber line** — Curve midway between upper and lower surfaces.
- **Camber** — Curvature of the mean camber line relative to the chord line.
- **Thickness** / **Thickness ratio** — Distance between upper and lower surfaces at a chordwise position / max thickness divided by chord.
- **Leading edge** / **Leading-edge radius** / **Trailing edge** — Forward-most portion / its curvature radius / where upper and lower surfaces meet aft.
- **Maximum lift coefficient** — The greatest lift coefficient an airfoil can produce before stall.
- **Drag coefficient** — Dimensionless representation of drag (see also Drag).
- *(Lift coefficient, moment coefficient, lift-to-drag ratio — see Lift, Aerodynamic Moments, and Drag above.)*

## 8. Aerodynamic Moments

- **Pitching moment** — Acts about the lateral axis.
- **Rolling moment** — Acts about the longitudinal axis.
- **Yawing moment** — Acts about the vertical axis.
- **Moment coefficient** — Dimensionless representation of aerodynamic moment.

## 9. Angle of Attack & Stall

- **Angle of attack** — Angle between an aerodynamic body's reference chord/axis and the relative airflow.
- **Geometric angle of attack** — AoA determined from the body's geometric orientation.
- **Local angle of attack** — AoA experienced by a local section of a surface.
- **Zero-lift angle** — AoA at which an airfoil/wing produces zero lift.
- **Critical angle of attack** — AoA beyond which stall begins.
- **Stall** — Significant loss of lift from flow separation past the critical AoA.
- **Leading-edge stall** — Separation begins near the leading edge.
- **Trailing-edge stall** — Separation begins near the trailing edge and progresses forward.
- **Deep stall** — A stall condition in which the aircraft's configuration prevents or severely limits normal recovery.
- **Spin** — An autorotating flight condition involving stalled wings and sustained rotation.
- **Stall recovery** — Reducing AoA and restoring attached airflow.

## 10. Flow Phenomena, Ground Effect & Compressibility

- **Boundary layer** — Region of airflow near a surface where viscosity causes significant velocity gradients.
- **Laminar flow** — Smooth, orderly airflow with relatively little mixing.
- **Turbulent flow** — Irregular airflow with significant mixing and fluctuation.
- **Transition** — Process by which boundary-layer flow changes from laminar to turbulent.
- **Boundary-layer separation** — Detachment of the boundary layer from a surface.
- **Reattachment** — Separated flow reconnecting with a surface.
- **Flow separation** — Separation of airflow from an aerodynamic surface.
- **Vortex** — A rotating region of airflow.
- **Wingtip vortex** — Generated near a wingtip as high-pressure air moves around the tip toward the low-pressure region above the wing.
- **Vortex shedding** — Periodic release of vortices from a body or surface.
- **Downwash** / **Upwash** — Downward / upward component of airflow produced by (or around) a lifting wing.
- **Wake** — Disturbed airflow downstream of an aircraft or aerodynamic body.
- **Turbulence** — Irregular, fluctuating airflow.
- **Ground effect** — Aerodynamic changes when an aircraft operates close to a surface, causing **induced drag reduction** and **increased effective lift**.
- **Compressibility** — Change in air density caused by pressure variations in the airflow.
- **Mach number** — Ratio of an object's speed to the local speed of sound.
- **Critical Mach number** — Lowest freestream Mach number at which some point on the aircraft first reaches Mach 1.
- **Transonic flow** — Flow containing both subsonic and supersonic regions.
- **Shock wave** — A narrow region of abrupt pressure/temperature/density change in compressible flow.
- **Supersonic flow** — Local Mach number greater than 1.
- **Sonic boom** — Pressure disturbance generated by an object traveling at supersonic speed.
- **Area rule** — Design principle reducing transonic wave drag by controlling changes in cross-sectional area.

## 11. Aerodynamic Performance

- **Wing loading** — Aircraft weight divided by wing area.
- **Power loading** — Aircraft weight divided by available power.
- **Lift-to-drag ratio** — See Drag.
- **Stall speed** — Minimum steady flight speed maintaining a given flight condition without exceeding critical AoA.
- **Rate of climb** — Vertical velocity during a climb.
- **Sustained climb rate** — Maximum climb rate sustainable without losing airspeed.
- **Glide ratio** — Horizontal distance traveled for a given loss of altitude.

## 12. Wingtip Devices

- **Winglet** — A near-vertical or angled tip surface that reduces wingtip-vortex strength and induced drag.
- **Blended winglet** — Transitions smoothly from wing to winglet rather than at a sharp angle.
- **Wingtip fence** — A small device limiting spanwise flow/vortex formation without much added height.
- **Raked wingtip** — Increased sweep at the tip extending span and reducing induced drag, without a distinct upward angle.
- **Sharklet** — A specific blended-winglet design (associated with Airbus aircraft).
- **Split winglet** — Incorporates both upper and lower surfaces from the tip.
- **Hoerner tip** — Sharply curved upper surface, flatter lower surface, to reduce tip-vortex strength.
- **Drooped wingtip** — Curves downward rather than upward.
- **Tip extension** — Extends span at the tip without a distinct winglet shape.

## 13. Drag Devices

- **Spoiler** — A movable surface reducing lift and/or increasing drag.
- **Speed brake / Air brake** — Primarily intended to increase drag and reduce speed.
- **Dive brake** — A drag device for steep or high-speed descent.
- **Drag chute** — A parachute-like device generating substantial aerodynamic drag.

## 14. Propulsion Devices & Propeller Effects

**Propeller configuration**
- **Tractor propeller** — Positioned forward of the structure it propels.
- **Pusher propeller** — Positioned behind the structure it propels.
- **Contra-rotating propellers** — Two propellers on the same axis, rotating opposite directions.
- **Coaxial propellers** — Two propellers mounted concentrically on the same axis.

**Propeller geometry**
- **Propeller disc** — The circular area swept by a propeller.
- **Blade pitch** — Geometric angle of a propeller blade.
- **Fixed-pitch propeller** — Blade pitch cannot be changed in operation.
- **Variable-pitch propeller** — Blade pitch can be changed in operation; **collective pitch** changes multiple blades simultaneously.

**Propeller aerodynamics**
- **Propeller slipstream** / **Propeller wash** — Accelerated airflow produced downstream of / by a propeller.
- **Propeller-induced velocity** — Velocity imparted to surrounding airflow by the propeller.
- **Propeller thrust** — Forward force generated by a propeller.
- **Propeller torque** — Aerodynamic resistance torque acting against propeller rotation.
- **Propeller efficiency** — Ratio of useful propulsive power to power supplied to the propeller.
- **Propeller advance ratio** — Dimensionless quantity relating forward velocity, rotational speed, and diameter.
- **P-factor** — Asymmetric thrust produced by a propeller operating at an angle of attack.
- **Asymmetric blade effect** — Unequal aerodynamic loading between advancing and retreating propeller blades.

**Engine types**
- **Turbojet** — Produces thrust entirely from exhaust gas through a compressor-combustor-turbine cycle.
- **Turbofan** — Combines a ducted fan with a turbojet core; thrust from bypass air and core exhaust.
- **Turboprop** — A gas-turbine engine driving an external propeller via a reduction gearbox.
- **Ramjet** — Compresses incoming air using only forward speed, no rotating compressor.
- **Scramjet** — A ramjet variant where combustor airflow stays supersonic.

**Engine effects**
- **Jet thrust** — Thrust from accelerating a mass of gas rearward.
- **Torque reaction** — Reaction torque applied to the aircraft by an engine driving a rotating component.
- **Gyroscopic precession** — Change in a rotating body's angular-momentum vector orientation in response to an applied torque.

---

# HYDRODYNAMICS

## 15. Fluid Properties

- **Fluid density** — Mass of fluid per unit volume; **water density** is this property for the simulated water.
- **Viscosity** — A fluid's resistance to deformation and flow; **dynamic viscosity** describes resistance to shear, **kinematic viscosity** is dynamic viscosity divided by density.
- **Surface tension** — Tendency of a liquid surface to resist deformation.
- **Hydrostatic pressure** — Pressure caused by the weight of fluid above a point; the **hydrostatic pressure gradient** is its rate of change with depth.

## 16. Buoyancy

- **Buoyancy** / **Buoyant force** — The (net) upward force exerted by a fluid on a submerged or partially submerged body, from pressure differences around it.
- **Archimedes' principle** — The buoyant force on a body equals the weight of fluid it displaces.
- **Displacement** / **Displacement volume** — The volume of fluid displaced by a body; for a floating vessel, the submerged hull volume, which by Archimedes' principle equals its buoyant force.
- **Center of buoyancy** — The geometric center of the displaced fluid volume (see also Metacenter, below).
- **Neutral buoyancy** / **Positive buoyancy** / **Negative buoyancy** — Buoyant force equals / exceeds / is less than the object's weight.

## 17. Vessel Configuration & Geometry

**Hull form**
- **Hull** / **Hull form** — A vessel's underwater body / its overall three-dimensional shape.
- **Displacement hull** — Supports the vessel primarily through buoyancy.
- **Planing hull** — Generates significant hydrodynamic lift at high speed.
- **Semi-displacement hull** — Operates between displacement and planing regimes.
- **Flat-bottom hull** / **V-bottom hull** / **Round-bottom hull** — Hull bottom shapes.
- **Multi-hull** — Uses multiple separate hulls; **catamaran** (two hulls), **trimaran** (three: one main + two **outriggers**).

**Geometry**
- **Waterline** — Where the hull intersects the water surface.
- **Draft** — Vertical distance from waterline to the hull's lowest point.
- **Freeboard** — Vertical distance from waterline to the upper deck/gunwale.
- **Beam** — Maximum width of a vessel.
- **Length overall (LOA)** — Maximum length of a vessel.
- **Waterline length** — Length measured along the waterline.
- **Wetted surface area** — Hull area in contact with water.
- **Block coefficient** — How closely a hull's underwater volume approaches a rectangular block.
- **Prismatic coefficient** — How underwater volume is distributed along the hull's length.
- **Waterplane area** / **Waterplane coefficient** — Area enclosed by the hull's waterline intersection / its ratio to the enclosing rectangle's area.

**Vessel anatomy**
- **Bow** — The forward part of a hull.
- **Stern** — The aft part of a hull.
- **Transom** — The flat (or curved) surface forming the stern at the aft end of the hull.
- **Deck** — The horizontal surface(s) covering the hull.
- **Superstructure** — Structure built above the main deck (cabins, bridge, etc.).
- **Gunwale** — The upper edge of a hull's side (see also Freeboard, above).
- **Bilge** — The lowest interior part of the hull, where the bottom curves up into the sides.
- **Amidships** — The middle portion of a vessel, between bow and stern.
- **Port** / **Starboard** — The left / right side of a vessel when facing forward.
- **Forward** / **Aft** — Toward the bow / toward the stern.
- **Rudder stock (rudder post)** — The shaft connecting a rudder to its steering mechanism, about which the rudder pivots.
- **Propeller shaft** — The shaft transmitting engine torque to the propeller.
- **Strut (shaft strut)** — A supporting bracket holding a propeller shaft, or other underwater appendage, away from the hull.

## 18. Hydrostatic Stability

- **Longitudinal stability** — A vessel's stability against rotation about its lateral axis (pitch).
- **Transverse stability** — A vessel's stability against rotation about its longitudinal axis (roll).
- **Center of gravity** — Point at which the vessel's mass can be considered concentrated.
- **Metacenter** — The point about which a floating vessel initially rotates when displaced from equilibrium.
- **Metacentric height** — Distance between center of gravity and metacenter.
- **Righting arm** — Horizontal distance between the lines of action of gravity and buoyancy.
- **Righting moment** — The restoring moment produced by buoyancy and gravity.
- **Heel** — Rotation about the longitudinal axis; **List** — a persistent inclination to one side.
- **Trim** / **Trim angle** — The longitudinal inclination of a vessel / its angle relative to the water surface (including while underway — see also **Running trim** under Planing).
- **Heel angle** — The angle of a vessel's transverse inclination.
- **Drift angle** (also called **sideslip**, for a vessel) — The angle between a vessel's longitudinal axis and its actual direction of travel through the water.
- **Leeway** — Sideways movement of a vessel caused by external forces such as wind, waves, or current.

## 19. Hydrodynamic Forces, Resistance & Cavitation

**Forces and drag components**
- **Hydrodynamic drag** — Resistance from water flowing around a moving body.
- **Form drag** (also **form resistance**) — Drag from pressure differences around the hull's shape.
- **Skin-friction drag** (also **frictional resistance**) — Drag from viscous shear between water and the hull.
- **Pressure drag** — Drag from pressure differences around the hull.
- **Viscous resistance** — Resistance caused by fluid viscosity.
- **Wave-making resistance** (also **wave resistance**) — Resistance caused by waves the vessel itself generates.
- **Residual resistance** — Resistance remaining after frictional resistance is accounted for.
- **Total resistance** — The combined resistance opposing a vessel's forward motion.
- **Air resistance** — Aerodynamic resistance on the portion of the vessel above the water.
- **Appendage drag** — Resistance from underwater components such as rudders, shafts, struts, and keels.
- **Hydrodynamic lift** — Force generated perpendicular to local water flow; **planing lift** is hydrodynamic lift generated at sufficiently high speed.
- **Added mass** — The apparent increase in an object's inertia from the need to accelerate surrounding water; **added moment of inertia** is the rotational equivalent.
- **Slamming** — Large transient hydrodynamic forces from a hull or surface striking water.
- **Longitudinal / Lateral / Vertical force** — Forces acting along the vessel's longitudinal axis / perpendicular to it in the horizontal plane / perpendicular to the water surface.
- **Yawing / Rolling / Pitching moment** (vessel) — Moments about the vertical / longitudinal / lateral axis.

**Hull speed & similarity**
- **Hull speed** (also **displacement hull speed**) — Approximation of the speed at which wave-making resistance becomes increasingly significant for a displacement hull.
- **Froude number** — Dimensionless quantity relating vessel speed to gravitational effects and characteristic length.
- **Reynolds number** — Dimensionless quantity relating inertial to viscous effects.

**Cavitation & ventilation**
- **Cavitation** — Formation of vapor-filled regions in a liquid when local pressure falls below vapor pressure; a **cavitation bubble** is such a region.
- **Cavitation inception** — The point at which cavitation begins.
- **Cavitation erosion** — Damage from repeated formation and collapse of cavitation bubbles.
- **Propeller cavitation** — Cavitation around a propeller from low local pressure.
- **Cavitation number** / **Cavitation coefficient** — Dimensionless measures characterizing cavitation conditions (pressure, vapor pressure, and dynamic pressure).
- **Supercavitation** — A large vapor cavity surrounds much of a moving underwater body.
- **Cavitation noise** — Noise from the formation and collapse of cavitation bubbles.
- **Ventilation** — The ingestion of air into a propeller or underwater flow region from the free surface (also called **propeller ventilation** when specific to a propeller).

## 20. Waves & Vessel Motion

**Waves**
- **Free surface** — The boundary between water and air.
- **Wave** — A propagating disturbance on the water surface.
- **Wave height** — Vertical distance from trough to crest.
- **Wavelength** — Horizontal distance between successive crests.
- **Wave period** — Time between successive crests passing a fixed point; **wave frequency** is cycles per unit time.
- **Wave steepness** — Ratio of wave height to wavelength.
- **Crest** / **Trough** — Highest / lowest point of a wave.
- **Wake** (water) — The wave and flow disturbance generated behind a moving vessel.
- **Bow wave** / **Stern wave** — The wave generated near the front / rear of a moving vessel.
- **Free-surface flow**, **wave formation**, **wave breaking**, **spray** — Water-surface phenomena generated as waves form, steepen, and break, or as water is thrown up by a hull or breaking wave.

**Vessel motion (6 degrees of freedom)**
- **Heave** — Vertical translation.
- **Surge** — Longitudinal translation.
- **Sway** — Lateral translation.
- **Roll** — Rotation about the longitudinal axis.
- **Pitch** — Rotation about the lateral axis.
- **Yaw** — Rotation about the vertical axis.
- **Wave encounter** — Interaction between a vessel and incoming waves.
- **Encounter frequency** — Frequency at which a moving vessel encounters wave crests.
- **Resonance** — A large response when excitation frequency approaches a vessel's natural frequency.
- **Natural frequency** — The frequency at which a vessel tends to oscillate when disturbed.
- **Damping** — Reduction of oscillatory motion from dissipative forces; **radiation damping** dissipates energy via waves generated by the oscillating vessel, **viscous damping** via viscous fluid forces.

## 21. Planing

- **Planing** — A high-speed regime where hydrodynamic pressure forces support a significant portion of the vessel's weight; a **planing surface** is a hull surface generating this lift.
- **Deadrise** — Angle between the hull bottom and the horizontal plane.
- **Chine** — A longitudinal edge where two hull surfaces meet; **hard chine** (pronounced, sharp) vs. **soft chine** (rounded transition).
- **Spray rail** — A longitudinal hull projection redirecting water and influencing spray/hydrodynamic forces.
- **Wetted length** — Longitudinal length of hull in contact with water.
- **Running trim** — The trim angle of a vessel while moving at speed.
- **Porpoising** — An unstable oscillation of repeated pitching and vertical-motion changes during planing.
- **Hump speed** — Speed range where a displacement/semi-planing vessel sees a significant resistance increase before transitioning toward planing.
- **Squatting** — An increase in draft and change in trim caused by reduced pressure beneath the hull at speed, especially in shallow or confined water.

## 22. Marine Propulsion

- **Marine propeller** — A rotating bladed device converting engine torque into thrust by accelerating water rearward.
- **Fixed-pitch propeller** (marine) — Blade angle fixed, cannot be adjusted in operation.
- **Controllable-pitch propeller** — Blade angle adjustable while rotating, allowing thrust/direction changes without reversing shaft rotation.
- **Propeller thrust** / **Propeller torque** / **Propeller efficiency** (marine) — Same concepts as the aerodynamic propeller terms above, applied underwater.
- **Propeller slip** — Difference between a propeller's theoretical advance (from pitch and rotational speed) and its actual advance through water.
- **Waterjet** — Draws in water and expels it as a high-velocity jet to generate thrust.
- **Paddle wheel** — Uses external paddles on a rotating wheel to push against the water.

## 23. Marine Control Surfaces (Rudder)

- **Rudder** — A movable underwater control surface primarily used to generate a yawing moment.
- **Rudder angle** — Angle between the rudder's reference plane and the vessel's centerline.
- **Rudder force** — Hydrodynamic force generated by a rudder.
- **Rudder stall** — Loss of effective rudder force from excessive rudder angle or flow separation.
- **Rudder effectiveness** — A rudder's ability to generate lateral force and yawing moment.
- **Rudder inflow** — Local water velocity and direction experienced by a rudder.
- **Balanced rudder** — Part of its area is positioned ahead of the hinge axis.
- **Unbalanced rudder** — Entire effective area is behind the hinge axis.
- **Spade rudder** — Supported primarily by its stock, without a separate lower support.
- **Skeg-mounted rudder** — Supported by a fixed structure extending below the hull.
- **Propeller race** — Accelerated flow from a propeller passing over downstream components.
- **Propeller-rudder interaction** — Effect of propeller-induced flow on rudder forces.
- **Propeller walk** — Sideways force/yawing tendency from asymmetric propeller blade loading.
- **Transverse thrust** — Lateral thrust component from a propeller, particularly at low speed.

## 24. Maneuvering

- **Turning radius** — Radius of the vessel's path during a turn.
- **Rate of turn** — Rate at which heading changes.
- **Advance** — Forward distance traveled between initiating a turn and reaching a specified heading change.
- **Transfer** — Lateral distance traveled during a turn.
- **Tactical diameter** — Transverse distance traveled during a 180° heading change.
- **Pivot point** — The point around which a vessel approximately rotates during a maneuver.
- **Turning circle** — The path followed during a steady turn.
- **Yaw stability** — Tendency of a vessel to resist or return from heading changes.
- **Weather helm** — Tendency for a vessel to turn toward the wind.
- **Lee helm** — Tendency for a vessel to turn away from the wind.

## 25. Underwater Appendages

- **Keel** — A longitudinal structural or hydrodynamic component extending below a vessel.
- **Fin keel** — A relatively narrow vertical keel.
- **Full keel** — Extends along a substantial portion of the hull's length.
- **Bilge keel** — A longitudinal appendage near the bilge, used mainly to reduce rolling.
- **Centerboard** — A retractable surface used to increase lateral resistance.
- **Daggerboard** — A vertically retractable underwater lateral surface.
- **Hydrofoil** — An underwater lifting surface generating hydrodynamic lift.
- **Foiling** — Operation where hydrofoils lift part or all of the hull out of the water.

## 26. Water Flow / Current

- **Current** — Bulk movement of water relative to the environment.
- **Current velocity** — Velocity of the water relative to the world.
- **Relative water velocity** — Velocity of water relative to a moving vessel or surface.
- **Still water** — Water with no bulk environmental current.
- **Following current** / **Head current** / **Cross current** — Current traveling with / against / roughly perpendicular to the vessel.

## 27. Sailing

- **Apparent wind** — Wind velocity experienced by a moving vessel; **apparent wind angle** is its direction relative to the vessel.
- **True wind** — Wind velocity relative to the surrounding environment.
- **Sail lift** / **Sail drag** — Aerodynamic lift / drag generated by a sail.
- **Center of effort** — Effective point at which aerodynamic force from the sails acts.
- **Center of lateral resistance** — Effective point at which underwater lateral resistance acts.
- **Point of sail** — The vessel's sailing direction relative to the wind: **close-hauled** (as close to the wind as practical), **beam reach** (~perpendicular to the wind), **broad reach** (wind from behind and to the side), **running** (wind from directly or nearly directly behind).
- *(Weather helm / Lee helm — see Maneuvering, above.)*
