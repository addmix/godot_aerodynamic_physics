extends RefCounted

#the sweeps: the aircraft flown through every attitude and speed the dock graphs are drawn from. nothing here knows of graphs,
#labels or the editor, and nothing here reads the scene it is handed: it is given a body and the conditions to fly it in, so
#it can be flown beside the editor rather than on top of it.

var body : AeroBody3D
var test_speed := 250.0
var sweep_datapoints := 96
var reference_area := 0.0
var reference_span := 0.0
var reference_chord := 0.0
var altitude := 5000.0
var density := 1.225
var pressure := 101325.0
var sound_speed := 340.0
var load_limit := 9.0
var turn_datapoints := 64
#the ladder of altitudes the speed envelope is flown at, with the air at each of them, handed over by the dock
var altitudes := PackedFloat64Array()
#the speeds each altitude is swept through, which is also how finely its angles of attack are sampled
var altitude_datapoints := 12
var altitude_densities := PackedFloat64Array()
var altitude_pressures := PackedFloat64Array()
var altitude_sound_speeds := PackedFloat64Array()
#the nodes of the body the sweeps reach into, gathered by the caller on the main thread: a thread may not search the scene
var influencers : Array[AeroInfluencer3D] = []
var thrusters : Array[AeroThruster3D] = []
var control : AeroControlComponent
#the parts of the aircraft that move, and where they sit when the sweep starts: a propeller blade is at a different place in its
#turn every time an attitude is flown, so it is put back to the same two places and the readings taken there are averaged. both are
#kept untyped, because typing either by the mover's class makes the sweep ask a node for its script, which a worker thread may not do
var movers := []
var mover_rests := {}
var movers_gathered := false

#the sweeps: flown from the settings above, and knowing nothing of graphs, labels or the editor. everything above this
#line is the dock, and everything below it is what the dock asks the aircraft for

#how the static sweeps are flown
const ALPHA_SWEEP_LIMIT := 180.0
const BETA_SWEEP_LIMIT := 45.0
const ROLL_SWEEP_LIMIT := 180.0
const GRAVITY := 9.81
#the air the sweeps fall back to while the atmosphere tables have nothing to say, and the direction they measure it in
const SEA_LEVEL_DENSITY := 1.225
const SEA_LEVEL_PRESSURE := 101325.0
const AIR_DIRECTION := Vector3(0, 0, 1)

#how the turn performance is flown: the angle of attack is swept up to this to find the lift limit, and Mach is stepped from
#the first of these to the last
const TURN_ALPHA_LIMIT := 30.0
#the angle the sweeps start at: the wing carries the aircraft's weight at a negative angle at speed, so a grid that starts at
#zero cannot bracket that crossing and reports the power at a load above one in its place
const TURN_ALPHA_FLOOR := -10.0
#how many times the angle that carries the weight is walked in, and how close to one g it has to land before it is taken
const TRIM_STEPS := 4
const TRIM_LOAD_TOLERANCE := 0.002
const TURN_ALPHA_SAMPLES := 25
const TURN_MACH_START := 0.2
const TURN_MACH_LIMIT := 1.6
#the friction of a runway under the wheels while the aircraft is still on it, which a take-off run is spent fighting, and how many
#speeds that run is read at between a crawl and the speed the aircraft lifts off at
const TAKEOFF_ROLLING_FRICTION := 0.02
const TAKEOFF_RUN_STEPS := 10
#a turning part is read at rest and at this share of a whole turn from rest, which is the 90 degrees that stands in for every
#other angle it could have been caught at. the two readings are averaged, and the rest pose is the authored one, so a sweep
#reads the same however long the aircraft has been running
const PROPELLER_PHASE := 0.25
#how long a control is given to reach the state its command holds it in before anything is measured, in seconds. it is longer
#than any ramp a control config carries, so the sweep starts with the engine spooled and the surfaces where they belong
const CONTROL_SETTLE_TIME := 1000.0
#the ladder of altitudes the speed envelope is flown through, and the samples each speed there is tried at
const ENVELOPE_ALTITUDE_FLOOR := 0.0
const ENVELOPE_ALTITUDE_CEILING := 15000.0
const ENVELOPE_ALTITUDE_STEPS := 13
#the envelope is searched by speed, from below anything that flies up to well past the speed of sound: a slow airframe runs out
#of speed below the chart's first mach step, and a fast one keeps going above its last
const ENVELOPE_SPEED_FLOOR := 20.0
const ENVELOPE_SPEED_STEPS := 24
#how close the slowest flying speed has to be walked in before it is good enough, in meters a second: the speed a chart starts
#at is read off it, and half a meter a second is far below what a column a hundred meters apart can show, so walking it in
#further only spends flights
const CARRYING_SPEED_TOLERANCE := 0.5
#how many times the speed a level flight runs out of power at is walked in, and how close to nothing its power has to come
const POWER_STEPS := 4
const POWER_TOLERANCE := 0.02
#how many speeds are flown to find the best sustained turn around the best sampled one: the top of that curve is flat, so the
#samples either side of it decide the answer more than the aircraft does
const SUSTAINED_SEARCH_STEPS := 4
#how far either side of the best sustained turn the top of its curve is read, in Mach: a fixed width, so the fit does not slide with
#the sampled grid
const SUSTAINED_PEAK_REACH := 0.02
#how many times the top of the lift curve is walked in between the samples either side of it
const LIFT_PEAK_STEPS := 2
#how far above that speed the first column of a sweep is laid. the walk answers with a speed the wing carries the aircraft at
#on the boundary itself, where a rounding either way decides whether the column flies, and a column that comes out unflyable
#hands the chart its second one instead, a whole step up the mach range
const CARRYING_SPEED_MARGIN := 1.002
const ENVELOPE_MACH_LIMIT := 3.0
#the load factor a turn pulling 1 g sideways comes to, which is the flattest turn the chart reads a radius off and the line every
#turn radius line starts on
const ONE_G_TURN_LOAD := sqrt(2.0)
#the control axis the thrusters read their throttle from, which the turn sweep holds wide open
const THROTTLE_AXIS := "throttle"
#the turn radii a chart draws lines for, graduated every step of this many meters from the tightest circle worth drawing out
#to the widest, rather than whatever the sweep works out to, so the family reads the same however finely it is flown
const TURN_RADIUS_STEP := 300.0
const TURN_RADIUS_TIGHTEST := 300.0
const TURN_RADIUS_WIDEST := 10000.0
#the excess power a sample has to stay inside to be a reading rather than a broken force, in meters a second: nothing that
#flies changes its energy that fast, and one such sample would flatten every contour the chart draws
const POWER_SANITY_LIMIT := 10000.0
#how close together two of those lines may come, in degrees a second where they are nearest the widest end of the chart, before
#the one after is left out. a graduation of 200 meters is worth drawing while the lines still read apart, and past that the
#family thins out instead of piling up in the corner
const TURN_RADIUS_MINIMUM_GAP := 0.8
#how far a column flown between two others may come from where those two would have put it before the sweep is split again along
#it, in degrees a second of turn rate and in meters a second of excess power. past these the column is one the chart would have
#drawn a kink without, so it is kept
const TURN_BEND_RATE := 0.06
const TURN_BEND_POWER := 0.6
#how many times the sweep is split again: enough for the parts of the chart that bend hardest to fill in without every part of
#the chart paying for it
const TURN_SPLITS := 2


#the static analysis, as every curve its graphs draw and the numbers the metrics are read from
func static_analysis() -> Dictionary:
	measure_reference_dimensions()
	
	#the static sweeps leave the throttle closed, so the aircraft is put in the state that command holds it in before it is flown
	reset_control_axes()
	settle_controls()
	
	var alpha := alpha_sweep()
	return {
		"alpha": alpha,
		"beta": beta_sweep(),
		"roll": roll_sweep(trim_alpha(alpha)),
		"metrics": measure_metrics(alpha),
	}

#the lift, drag and moments across the angle of attack sweep, with the samples the metrics are read from
func alpha_sweep() -> Dictionary:
	var lift := PackedVector2Array()
	var drag := PackedVector2Array()
	var polar := PackedVector2Array()
	var polar_alphas := PackedFloat32Array()
	var pitch := PackedVector2Array()
	var yaw := PackedVector2Array()
	var roll := PackedVector2Array()
	
	var alpha_samples := PackedFloat64Array()
	var lift_samples := PackedFloat64Array()
	var drag_samples := PackedFloat64Array()
	var pitch_samples := PackedFloat64Array()
	
	for sample : int in sweep_datapoints:
		var alpha : float = remap(sample, 0, sweep_datapoints - 1, -ALPHA_SWEEP_LIMIT, ALPHA_SWEEP_LIMIT)
		var coefficients := calculate_coefficients(Transform3D(Basis.from_euler(Vector3(deg_to_rad(alpha), 0, 0)), Vector3.ZERO))
		if coefficients.is_empty(): break
		
		alpha_samples.append(alpha)
		lift_samples.append(coefficients.lift)
		drag_samples.append(coefficients.drag)
		pitch_samples.append(coefficients.pitch)
		
		lift.append(Vector2(alpha, coefficients.lift))
		drag.append(Vector2(alpha, coefficients.drag))
		polar.append(Vector2(coefficients.drag, coefficients.lift))
		polar_alphas.append(alpha)
		pitch.append(Vector2(alpha, coefficients.moment_x))
		yaw.append(Vector2(alpha, coefficients.moment_y))
		roll.append(Vector2(alpha, coefficients.moment_z))
	
	return {
		"lift": lift,
		"drag": drag,
		"pitch": pitch,
		"yaw": yaw,
		"roll": roll,
		"ratio": ratio_curve(alpha_samples, lift_samples, drag_samples),
		"polar": polar,
		"polar_alphas": polar_alphas,
		"alpha_samples": alpha_samples,
		"lift_samples": lift_samples,
		"drag_samples": drag_samples,
		"pitch_samples": pitch_samples,
	}

#the moments across the sideslip sweep
func beta_sweep() -> Dictionary:
	var pitch := PackedVector2Array()
	var yaw := PackedVector2Array()
	var roll := PackedVector2Array()
	
	for sample : int in sweep_datapoints:
		var beta : float = remap(sample, 0, sweep_datapoints - 1, -BETA_SWEEP_LIMIT, BETA_SWEEP_LIMIT)
		var coefficients := calculate_coefficients(Transform3D(Basis.from_euler(Vector3(0, deg_to_rad(beta), 0)), Vector3.ZERO))
		if coefficients.is_empty(): break
		
		pitch.append(Vector2(beta, coefficients.moment_x))
		yaw.append(Vector2(beta, coefficients.moment_y))
		roll.append(Vector2(beta, coefficients.moment_z))
	
	return {"pitch": pitch, "yaw": yaw, "roll": roll}

#rolling an aircraft that holds a fixed flight path turns the airflow toward its wing tips, so the wings stop seeing the
#same angle of attack and a rolling moment appears. none of that shows up if the air runs straight down the fuselage,
#which is why this sweep is flown at the angle of attack that carries the aircraft's weight. only the roll moment comes
#back: the pitch and yaw moments run several times larger through the same sweep and are what the other sweeps are for
func roll_sweep(trim_alpha : float) -> Dictionary:
	var moment := PackedVector2Array()
	
	for sample : int in sweep_datapoints:
		var roll : float = remap(sample, 0, sweep_datapoints - 1, -ROLL_SWEEP_LIMIT, ROLL_SWEEP_LIMIT)
		var placement := Basis(Vector3.RIGHT, deg_to_rad(trim_alpha)) * Basis(Vector3.BACK, deg_to_rad(roll))
		var coefficients := calculate_coefficients(Transform3D(placement, Vector3.ZERO))
		if coefficients.is_empty(): break
		
		moment.append(Vector2(roll, coefficients.moment_z))
	
	return {"moment": moment}

#the angle of attack that holds the aircraft up at the test speed, read back off the lift curve the alpha sweep built
func trim_alpha(alpha : Dictionary) -> float:
	if not body: return 0.0
	
	var dynamic_pressure : float = 0.5 * density * test_speed * test_speed
	if dynamic_pressure <= 0.0 or reference_area <= 0.0: return 0.0
	
	var required_lift : float = body.mass * GRAVITY / (dynamic_pressure * reference_area)
	var alphas : PackedFloat64Array = alpha.alpha_samples
	var lifts : PackedFloat64Array = alpha.lift_samples
	
	var highest_lift := -INF
	var alpha_at_highest_lift := 0.0
	for sample : int in alphas.size() - 1:
		#the reverse flow half of the sweep is not a trim condition
		if alphas[sample] < -15.0 or alphas[sample] > 30.0: continue
		
		if lifts[sample] > highest_lift:
			highest_lift = lifts[sample]
			alpha_at_highest_lift = alphas[sample]
		
		#the lift curve climbs through the weight it has to carry somewhere before the stall
		if lifts[sample + 1] <= lifts[sample]: continue
		if lifts[sample] <= required_lift and lifts[sample + 1] > required_lift:
			var along : float = (required_lift - lifts[sample]) / (lifts[sample + 1] - lifts[sample])
			return lerpf(alphas[sample], alphas[sample + 1], along)
	
	#nothing holds the aircraft up at this speed, so the sweep gets the angle that holds the most it can
	return alpha_at_highest_lift

#the lift/drag ratio across the sweep, remapped to 0..1 so it can use the whole height of a coefficient graph instead of the
#coefficient scale
func ratio_curve(alpha_samples : PackedFloat64Array, lift_samples : PackedFloat64Array, drag_samples : PackedFloat64Array) -> PackedVector2Array:
	var ratios := PackedFloat64Array()
	var highest_ratio := -INF
	var lowest_ratio := INF
	for sample : int in lift_samples.size():
		var ratio : float = 0.0
		if not is_zero_approx(drag_samples[sample]):
			ratio = lift_samples[sample] / drag_samples[sample]
		
		ratios.append(ratio)
		highest_ratio = maxf(highest_ratio, ratio)
		lowest_ratio = minf(lowest_ratio, ratio)
	
	var ratio_span : float = highest_ratio - lowest_ratio
	if is_zero_approx(ratio_span): return PackedVector2Array()
	
	var curve := PackedVector2Array()
	for sample : int in ratios.size():
		curve.append(Vector2(alpha_samples[sample], (ratios[sample] - lowest_ratio) / ratio_span))
	return curve


#the metrics

#the numbers the metrics panel is read off, with NAN wherever the sweep did not reach far enough to give one
func measure_metrics(alpha : Dictionary) -> Dictionary:
	var metrics := {
		"dynamic_pressure": 0.5 * density * test_speed * test_speed,
		"lift_max": NAN,
		"lift_max_alpha": NAN,
		"ratio": NAN,
		"ratio_alpha": NAN,
		"glide_speed": NAN,
		"sink_rate": NAN,
		"stiffness": NAN,
		"margin": NAN,
	}
	
	var alpha_samples : PackedFloat64Array = alpha.alpha_samples
	if alpha_samples.is_empty(): return metrics
	var lift_samples : PackedFloat64Array = alpha.lift_samples
	var drag_samples : PackedFloat64Array = alpha.drag_samples
	var pitch_samples : PackedFloat64Array = alpha.pitch_samples
	
	var highest_lift := -INF
	var alpha_at_highest_lift := 0.0
	var highest_ratio := -INF
	var alpha_at_highest_ratio := 0.0
	var lift_at_highest_ratio := 0.0
	for sample : int in alpha_samples.size():
		#stall only makes sense in forward flight, the reverse flow part of the sweep would win otherwise
		if alpha_samples[sample] > -30.0 and alpha_samples[sample] < 45.0 and lift_samples[sample] > highest_lift:
			highest_lift = lift_samples[sample]
			alpha_at_highest_lift = alpha_samples[sample]
		
		if drag_samples[sample] > 0.0:
			var ratio : float = lift_samples[sample] / drag_samples[sample]
			if ratio > highest_ratio:
				highest_ratio = ratio
				alpha_at_highest_ratio = alpha_samples[sample]
				lift_at_highest_ratio = lift_samples[sample]
	
	#a coarse sweep can miss both windows entirely, which leaves the fields they would have filled without a number
	if not is_inf(highest_lift):
		metrics.lift_max = highest_lift
		metrics.lift_max_alpha = alpha_at_highest_lift
	if not is_inf(highest_ratio):
		metrics.ratio = highest_ratio
		metrics.ratio_alpha = alpha_at_highest_ratio
	
	if highest_ratio > 0.0 and lift_at_highest_ratio > 0.0:
		var aircraft_weight : float = body.mass * GRAVITY
		metrics.glide_speed = sqrt(2.0 * aircraft_weight / (density * reference_area * lift_at_highest_ratio))
		metrics.sink_rate = metrics.glide_speed / highest_ratio
	
	#static margin from the slope of Cm against CL over the linear part of the lift curve
	var sum_lift := 0.0
	var sum_pitch := 0.0
	var sum_lift_pitch := 0.0
	var sum_lift_squared := 0.0
	var sample_count := 0
	for sample : int in alpha_samples.size():
		if alpha_samples[sample] < -4.0 or alpha_samples[sample] > 12.0: continue
		if lift_samples[sample] < 0.0 or lift_samples[sample] > 0.8: continue
		
		sum_lift += lift_samples[sample]
		sum_pitch += pitch_samples[sample]
		sum_lift_pitch += lift_samples[sample] * pitch_samples[sample]
		sum_lift_squared += lift_samples[sample] * lift_samples[sample]
		sample_count += 1
	
	if sample_count > 2:
		var denominator : float = sample_count * sum_lift_squared - sum_lift * sum_lift
		if not is_zero_approx(denominator):
			metrics.stiffness = (sample_count * sum_lift_pitch - sum_lift * sum_pitch) / denominator
			metrics.margin = -metrics.stiffness * 100.0
	
	return metrics


#turn performance

#what the aircraft can turn at across the Mach range: the limit the wing and the declared load limit put on the turn, the 1 g
#line the turns are read from, the constant load factor lines, the constant excess power contours and the constant turn radius
#lines
func turn_performance() -> Dictionary:
	var chart := {
		"limit": PackedVector2Array(), "one_g": PackedVector2Array(), "loads": [], "powers": [], "radii": [],
		"acceleration": PackedVector2Array(), "takeoff": PackedVector2Array(), "takeoff_distance": 0.0, "metrics": {},
	}
	if not body: return chart
	
	var weight : float = body.mass * GRAVITY
	if weight <= 0.0 or sound_speed <= 0.0: return chart
	
	#the chart is about the thrust the aircraft has to hold a turn with, so the throttle is wound open for the columns and let
	#back down after them
	var held := hold_open_throttle()
	
	#the top speed is read with the throttle still open, like every other power the chart is read for, and the columns are ranged
	#on that same answer so the chart and its own top line cannot disagree
	var top : float = level_speed(density, pressure, sound_speed, weight)
	var columns := turn_columns(density, pressure, sound_speed, weight, top)
	
	chart.acceleration = acceleration_curve(columns, top)
	chart.takeoff = takeoff_curve(chart.acceleration, weight)
	chart.takeoff_distance = takeoff_distance(chart.takeoff)
	
	#the thrust the aircraft has against its own weight, taken at a standstill with the throttle still open, which is the way the
	#figure is quoted: at that speed nothing is being dragged through the air, so the forward force is the thrust alone
	var static_thrust : float = force_on_level_attitude(0.0, 0.0, density, pressure).y
	
	restore_throttle(held)
	
	chart.limit = lift_limit_curve(columns)
	chart.one_g = load_curve(columns, ONE_G_TURN_LOAD)
	
	#the load factor lines, every whole g up to the declared limit, and the limit itself where it falls between two of them. the
	#last of them is what closes the top of the chart
	var loads := PackedFloat64Array()
	for load : int in range(2, int(load_limit) + 1): loads.append(float(load))
	if loads.is_empty() or not is_equal_approx(loads[loads.size() - 1], load_limit): loads.append(load_limit)
	
	for load : float in loads:
		var curve := load_curve(columns, load)
		if curve.size() > 1: chart.loads.append({"load": load, "points": curve})
	
	for level : float in power_contours(columns):
		var runs := power_curves(columns, level)
		if not runs.is_empty(): chart.powers.append({"level": level, "runs": runs})
	
	for radius : float in turn_radii(columns):
		chart.radii.append({"radius": radius, "points": radius_curve(columns, radius)})
	
	chart.metrics = turn_metrics(columns, density, pressure, sound_speed, weight)
	chart.metrics["thrust_to_weight"] = static_thrust / weight
	
	#the fastest level flight at this altitude, worked out the way the speed envelope works it out so the two never disagree
	chart.metrics["top"] = {"mach": NAN if is_nan(top) else top / sound_speed, "speed": top}
	
	return chart

#the speed the aircraft gains in level flight at each speed of the sweep: a rate of change of speed of a is a specific excess
#power of a times the speed over gravity, so the excess power each column carries is what this chart is read from. the line
#starts at the slowest speed the aircraft flies at, which is where the take-off run ends, so the two lines meet at one speed
func acceleration_curve(columns : Array[Dictionary], top : float) -> PackedVector2Array:
	var curve := PackedVector2Array()
	var gaining := false
	
	for column : Dictionary in columns:
		if is_nan(column.level_power) or column.speed <= 0.0: continue
		var acceleration : float = column.level_power * GRAVITY / column.speed
		
		#an aircraft that cannot gain speed at the speed it first flies at is read on rather than cut off there: only a line that
		#has been gaining ends where it stops, at the speed the aircraft tops out at
		if acceleration > 0.0:
			gaining = true
		elif gaining:
			var last : Vector2 = curve[curve.size() - 1]
			var span : float = column.speed - last.x
			if span > 0.0: curve.append(Vector2(last.x + span * last.y / (last.y - acceleration), 0.0))
			break
		
		curve.append(Vector2(column.speed, acceleration))
	
	#the columns stop where the whole turn chart stops, which is under the speed a fast airframe reaches in a straight line, so the
	#line is carried on to the top speed the sweep worked out
	if not is_nan(top) and not curve.is_empty() and top > curve[curve.size() - 1].x:
		curve.append(Vector2(top, 0.0))
	
	return curve

#the speed the aircraft gains on the runway, which is the stretch of speed the level flight line has nothing to say about: on the
#ground the wing is not yet carrying the weight, so what pushes the aircraft is the thrust left after drag and after the friction
#under the wheels
func takeoff_curve(acceleration : PackedVector2Array, weight : float) -> PackedVector2Array:
	var curve := PackedVector2Array()
	if acceleration.is_empty(): return curve
	
	var liftoff : float = acceleration[0].x
	for index : int in TAKEOFF_RUN_STEPS:
		var speed : float = lerpf(maxf(liftoff * 0.06, 1.0), liftoff, index / float(TAKEOFF_RUN_STEPS - 1))
		var force := force_on_level_attitude(0.0, speed, density, pressure)
		var rolling : float = TAKEOFF_ROLLING_FRICTION * maxf(weight - force.x, 0.0)
		curve.append(Vector2(speed, (force.y - rolling) * GRAVITY / weight))
	
	return curve

#the ground the run covers, in meters: a stretch of speed costs it v/a seconds per unit of speed, so the distance is the sum of
#that along the curve. the curve starts just above a standstill rather than at it, so the stretch from nothing is added on by
#the same measure, and a run the aircraft cannot start at all comes back as NAN rather than as a number
func takeoff_distance(takeoff : PackedVector2Array) -> float:
	if takeoff.is_empty(): return NAN
	
	var distance := 0.0
	for index : int in takeoff.size() - 1:
		var from : Vector2 = takeoff[index]
		var to : Vector2 = takeoff[index + 1]
		if from.y <= 0.0 or to.y <= 0.0: return NAN
		distance += (to.x - from.x) * (from.x / from.y + to.x / to.y) * 0.5
	
	return distance + takeoff[0].x * takeoff[0].x / (2.0 * takeoff[0].y)


#altitude

#what the aircraft does at every altitude the dock handed over, so the numbers that change with height are read at once rather
#than one altitude at a time
func altitude_sweep() -> Dictionary:
	var sweep := {
		"speed": PackedVector2Array(), "load": PackedVector2Array(), "turn_rate": PackedVector2Array(),
		"radius": PackedVector2Array(), "sustained": PackedVector2Array(), "climb": PackedVector2Array(),
		"ceiling": NAN,
	}
	if not body: return sweep
	
	var weight : float = body.mass * GRAVITY
	if weight <= 0.0: return sweep
	
	var held := hold_open_throttle()
	
	for index : int in altitudes.size():
		var height : float = altitudes[index]
		var height_density : float = altitude_densities[index]
		var height_pressure : float = altitude_pressures[index]
		var height_sound : float = altitude_sound_speeds[index]
		
		#the fastest level flight there, which is also the bound the turn numbers are read inside
		var fastest : float = level_speed(height_density, height_pressure, height_sound, weight)
		var columns := altitude_columns(height_density, height_pressure, height_sound, weight, fastest)
		
		#the best climb there, which is the most power level flight has left over at any speed, read off a curve through the three
		#columns around the best of them rather than off whichever column happened to fall nearest it
		var powers := PackedFloat64Array()
		var best := -1
		for column_index : int in columns.size():
			powers.append(columns[column_index].level_power)
			if is_nan(powers[column_index]): continue
			if best < 0 or powers[column_index] > powers[best]: best = column_index
		var climb := NAN
		if best >= 0: climb = refined_extreme(columns, powers, best, false).y
		
		#a height with no climb left is the last one the sweep flies: the aircraft cannot hold level flight above it, so the
		#numbers up there would describe a flight it cannot make. the ceiling is the crossing this height makes with the one below
		if not is_finite(climb) or climb <= 0.0:
			sweep.climb.append(Vector2(0.0 if not is_finite(climb) else climb, height))
			break
		
		#what the aircraft does there, now that it is known it can fly there at all
		if not is_nan(fastest): sweep.speed.append(Vector2(fastest / height_sound, height))
		
		var metrics := turn_metrics(columns, height_density, height_pressure, height_sound, weight)
		var corner : Dictionary = metrics.corner
		if not is_nan(corner.rate): sweep.turn_rate.append(Vector2(corner.rate, height))
		
		var load : float = peak_load(columns)
		if load > 0.0: sweep.load.append(Vector2(load, height))
		
		var tightest : Dictionary = metrics.tightest
		if not is_nan(tightest.meters): sweep.radius.append(Vector2(tightest.meters, height))
		
		var sustained : Dictionary = metrics.sustained
		if not is_nan(sustained.rate): sweep.sustained.append(Vector2(sustained.rate, height))
		
		sweep.climb.append(Vector2(climb, height))
	
	restore_throttle(held)
	sweep.ceiling = climb_ceiling(sweep.climb)
	return sweep

#the height the aircraft can no longer climb at, read where the best climb rate crosses nothing between the two altitudes either
#side of it. an aircraft still climbing at the top of the ladder reaches higher than the ladder goes, which is reported as NAN
#rather than as the ladder's own top
func climb_ceiling(climb : PackedVector2Array) -> float:
	if climb.is_empty(): return NAN
	
	#nothing is left to climb with at the lowest altitude either, so the ceiling it is reported at is the ground it was read at
	if climb[0].x <= 0.0: return climb[0].y
	
	for index : int in climb.size() - 1:
		var here : Vector2 = climb[index]
		var next : Vector2 = climb[index + 1]
		if next.x > 0.0: continue
		return lerpf(here.y, next.y, here.x / (here.x - next.x))
	
	return NAN

#the coarse turn sweep one altitude is read at, which is what the numbers that change with height are taken from
func altitude_columns(density : float, pressure : float, sound_speed : float, weight : float, fastest : float) -> Array[Dictionary]:
	var columns : Array[Dictionary] = []
	var span := turn_mach_range(density, pressure, sound_speed, weight, fastest)
	
	#the height curves are read off twelve columns, so their angles of attack are what decides how steady the zero power crossing
	#they report is: sixteen samples cost a third of a column each and take the step out of them
	var samples : int = maxi(altitude_datapoints, 16)
	for index : int in altitude_datapoints:
		var mach : float = lerpf(span.x, span.y, index / float(altitude_datapoints - 1))
		columns.append(turn_performance_column(mach, density, pressure, sound_speed, weight, samples))
	
	#the corner is solved between the two columns either side of it rather than flown in on, so the steps above are all this
	#sweep needs. they are handed over in mach order, which is what lets that crossing be read off them
	columns.sort_custom(sort_by_mach)
	return columns

#one column ahead of another in mach
func sort_by_mach(first : Dictionary, second : Dictionary) -> bool:
	return first.mach < second.mach

#the most load factor the wing and the limit allow anywhere in this sweep: the limit itself wherever it binds, and otherwise the
#peak of a curve through the three columns the wing holds the most at
func peak_load(columns : Array[Dictionary]) -> float:
	var peak := 0.0
	for column : Dictionary in columns:
		peak = maxf(peak, column.limit_load)
		if column.held_load >= load_limit: return load_limit
	
	return stall_corner(columns).load if not columns.is_empty() else peak

#the fastest level flight one altitude allows: the speed where the power left over in level flight runs out. it is walked in
#on from both sides of the crossing, so the answer is the speed rather than the step it happened to fall on
func level_speed(density : float, pressure : float, sound_speed : float, weight : float) -> float:
	#an aircraft still gaining energy at the top of the sweep is faster than the sweep can tell, so no number is reported rather
	#than one the sweep chose. it is asked first, because those altitudes would otherwise pay for the whole scan to find nothing
	if level_power(ENVELOPE_MACH_LIMIT * sound_speed, density, pressure, weight) >= 0.0: return NAN
	
	var holding := NAN
	var holding_power := NAN
	var spent := NAN
	var spent_power := NAN
	var fastest : float = ENVELOPE_MACH_LIMIT * sound_speed
	
	for index : int in ENVELOPE_SPEED_STEPS:
		var speed : float = remap(index, 0, ENVELOPE_SPEED_STEPS - 1, ENVELOPE_SPEED_FLOOR, fastest)
		var power : float = level_power(speed, density, pressure, weight)
		if is_nan(power): continue
		
		if power >= 0.0:
			holding = speed
			holding_power = power
			continue
		
		#too slow to hold level flight yet, so this is not the crossing the envelope is read at: the one higher up is
		if is_nan(holding): continue
		spent = speed
		spent_power = power
		break
	
	if is_nan(holding): return NAN
	#still gaining energy at the top of the sweep: the aircraft is faster than the sweep can tell, so no number is reported
	#rather than one the sweep chose
	if is_nan(spent): return NAN
	
	return power_crossing_speed(holding, holding_power, spent, spent_power, density, pressure, weight)

#where the power left over runs out, between a speed that still has some and one that has none. the guess is interpolated from
#the two powers and the next one from the result, so the crossing is walked in rather than halved: a few flights instead of
#eight, and the answer is the crossing rather than somewhere inside the last bracket
func power_crossing_speed(holding : float, holding_power : float, spent : float, spent_power : float, density : float, pressure : float, weight : float) -> float:
	for step : int in POWER_STEPS:
		if is_equal_approx(holding_power, spent_power): break
		
		var speed : float = lerpf(holding, spent, clampf(holding_power / (holding_power - spent_power), 0.0, 1.0))
		var power : float = level_power(speed, density, pressure, weight)
		if is_nan(power): return speed
		if absf(power) <= POWER_TOLERANCE: return speed
		
		if power > 0.0:
			holding = speed
			holding_power = power
		else:
			spent = speed
			spent_power = power
	
	return (holding + spent) * 0.5

#the power a level flight at one speed has left over: the angle of attack is the one carrying the weight, and what the engine
#gives above the drag of flying there is what is left
func level_power(speed : float, density : float, pressure : float, weight : float) -> float:
	var lowest := level_reading(TURN_ALPHA_FLOOR, speed, density, pressure, weight)
	var highest := level_reading(TURN_ALPHA_LIMIT, speed, density, pressure, weight)
	if is_nan(lowest.x) or is_nan(highest.x): return NAN
	
	#an aircraft that cannot carry its weight at the limit cannot fly here at all, and one that carries it even at the floor is
	#already past the crossing, so neither has one to walk in
	if highest.x < 1.0: return NAN
	if lowest.x >= 1.0: return lowest.y
	
	return level_power_between(speed, density, pressure, weight, TURN_ALPHA_FLOOR, lowest.x, TURN_ALPHA_LIMIT, highest.x)

#the numbers the chart is read for, worked out from the same columns it is drawn from
func turn_metrics(columns : Array[Dictionary], density : float, pressure : float, sound_speed : float, weight : float) -> Dictionary:
	return {
		"corner": corner_point(columns),
		"sustained": sustained_point(columns, density, pressure, sound_speed, weight),
		"tightest": tightest_point(columns),
	}

#the corner: the turn rate the aircraft peaks at, which is where the wing's lift limit meets the load limit. on an airframe the
#load limit never binds it is the speed the wing holds the most at instead. the crossing is solved between the two columns either
#side of it rather than read off whichever column fell nearest, which is what made this number wander by a percent or two with the
#sample count
func corner_point(columns : Array[Dictionary]) -> Dictionary:
	if columns.is_empty(): return no_turn()
	
	for index : int in columns.size():
		var column : Dictionary = columns[index]
		if column.held_load < load_limit: continue
		
		if index == 0:
			return {"mach": column.mach, "speed": column.speed, "load": load_limit, "rate": turn_rate(load_limit, column.speed)}
		
		var previous : Dictionary = columns[index - 1]
		var holding : float = column.held_load - previous.held_load
		var along : float = 0.0 if is_zero_approx(holding) else clampf((load_limit - previous.held_load) / holding, 0.0, 1.0)
		var speed : float = lerpf(previous.speed, column.speed, along)
		
		return {
			"mach": lerpf(previous.mach, column.mach, along), "speed": speed,
			"load": load_limit, "rate": turn_rate(load_limit, speed),
		}
	
	return stall_corner(columns)

#the corner of an airframe the load limit never binds: the speed its wing holds the most at, read off a curve through the three
#columns around the best of them
func stall_corner(columns : Array[Dictionary]) -> Dictionary:
	var held_loads := PackedFloat64Array()
	var best := 0
	for index : int in columns.size():
		held_loads.append(columns[index].held_load)
		if held_loads[index] > held_loads[best]: best = index
	
	var peak := refined_extreme(columns, held_loads, best, false)
	var speed : float = speed_at_mach(columns[best], peak.x)
	
	return {"mach": peak.x, "speed": speed, "load": peak.y, "rate": turn_rate(peak.y, speed)}

#the sustained turn is the best of what the aircraft can hold without losing energy, which is the highest point of the zero excess
#power line, read off a curve through the three columns around the best of them
func sustained_point(columns : Array[Dictionary], density : float, pressure : float, sound_speed : float, weight : float) -> Dictionary:
	if columns.is_empty(): return no_turn()
	
	var rates := PackedFloat64Array()
	var best := -1
	for index : int in columns.size():
		var rate : float = turn_rate(sustained_load(columns[index]), columns[index].speed)
		rates.append(rate)
		if is_nan(rate): continue
		if best < 0 or rate > rates[best]: best = index
	
	if best < 0: return no_turn()
	
	#the corner is the tightest turn the wing can hold the limit at, and it is solved rather than sampled, so it is the sustained
	#turn whenever the aircraft can power the limit there. that is answered by flying the corner itself: the columns either side of
	#it cannot say, because a column that holds the limit reports the limit however thin its power margin is, so interpolating them
	#made the answer hop between the corner and the sampled peak as the ladder moved
	var corner := corner_point(columns)
	if not is_nan(corner.mach):
		var at_corner := turn_performance_column(corner.mach, density, pressure, sound_speed, weight)
		if sustained_load(at_corner) >= load_limit - 0.0001: return corner
	
	#nothing holds the limit without spending energy here, so the best of what the aircraft can hold is walked in around the best
	#column rather than read off a curve through three samples: the top of this curve is flat enough that which sample the fit lands
	#on decides the answer, and with altitude that reads as a wave
	var low : float = columns[maxi(best - 1, 0)].mach
	var high : float = columns[mini(best + 1, columns.size() - 1)].mach
	var left : float = lerpf(low, high, 0.382)
	var right : float = lerpf(low, high, 0.618)
	var left_reading := sustained_reading_at(left, density, pressure, sound_speed, weight)
	var right_reading := sustained_reading_at(right, density, pressure, sound_speed, weight)
	
	for step : int in SUSTAINED_SEARCH_STEPS:
		if left_reading.x >= right_reading.x:
			high = right
			right = left
			right_reading = left_reading
			left = lerpf(low, high, 0.382)
			left_reading = sustained_reading_at(left, density, pressure, sound_speed, weight)
		else:
			low = left
			left = right
			left_reading = right_reading
			right = lerpf(low, high, 0.618)
			right_reading = sustained_reading_at(right, density, pressure, sound_speed, weight)
	
	var mach : float = (low + high) * 0.5
	var reading := sustained_reading_at(mach, density, pressure, sound_speed, weight)
	
	#the top of the curve is read off a parabola through three speeds a fixed distance apart rather than through the samples: a
	#stencil anchored to the samples changes shape as the sampled grid slides with the altitude, and that is what showed as a wave
	var nearer := sustained_reading_at(mach - SUSTAINED_PEAK_REACH, density, pressure, sound_speed, weight)
	var further := sustained_reading_at(mach + SUSTAINED_PEAK_REACH, density, pressure, sound_speed, weight)
	var rate : float = refined_peak_load(nearer.x, reading.x, further.x)
	
	return {"mach": mach, "speed": mach * sound_speed, "load": reading.y, "rate": rate}

#the sustained turn rate and the load factor it holds at one Mach, flown where it is asked rather than read off the nearest column
func sustained_reading_at(mach : float, density : float, pressure : float, sound_speed : float, weight : float) -> Vector2:
	var column := turn_performance_column(mach, density, pressure, sound_speed, weight)
	var load := sustained_load(column)
	
	return Vector2(turn_rate(load, column.speed), load)

#the tightest circle the aircraft can fly, and the speed it can fly it at, read off a curve through the three columns around the
#tightest of them
func tightest_point(columns : Array[Dictionary]) -> Dictionary:
	if columns.is_empty(): return {"meters": NAN, "mach": NAN, "speed": NAN, "rate": NAN}
	
	var radii := PackedFloat64Array()
	var best := -1
	for index : int in columns.size():
		var meters : float = turn_radius(columns[index].limit_load, columns[index].speed)
		radii.append(meters)
		if is_nan(meters): continue
		if best < 0 or meters < radii[best]: best = index
	
	if best < 0: return {"meters": NAN, "mach": NAN, "speed": NAN, "rate": NAN}
	
	var column : Dictionary = columns[best]
	var valley := refined_extreme(columns, radii, best, true)
	var speed : float = speed_at_mach(column, valley.x)
	
	return {"meters": valley.y, "mach": valley.x, "speed": speed, "rate": limit_rate_at(columns, valley.x)}

#the turn rate the aircraft can hold its most at, at a Mach between two columns, interpolated along the segment the chart draws
#between them. a mark placed at a solved speed then sits on the line it belongs to: reading it off the nearest sampled column put
#it a shade below the lift limit it was meant to sit on, more so the faster the wing's limit changes with speed
func limit_rate_at(columns : Array[Dictionary], mach : float) -> float:
	var previous : Dictionary = {}
	for column : Dictionary in columns:
		if column.mach >= mach:
			if previous.is_empty(): return turn_rate(column.limit_load, column.speed)
			
			var along : float = straddle_fraction(previous.mach - mach, column.mach - mach)
			return lerpf(turn_rate(previous.limit_load, previous.speed), turn_rate(column.limit_load, column.speed), along)
		previous = column
	
	return turn_rate(previous.limit_load, previous.speed) if not previous.is_empty() else NAN

#what a turn reads as when nothing in the sweep reaches one
func no_turn() -> Dictionary:
	return {"mach": NAN, "speed": NAN, "load": NAN, "rate": NAN}

#the load factor a column can hold without losing energy: the angle of attack where the excess power crosses zero, which is
#the last of the turn it can keep up. a column that never runs out of power holds whatever the load limit allows
func sustained_load(column : Dictionary) -> float:
	return column.get("sustained", NAN)

#the load factor the excess power runs out at, walked in between two angles whose powers bracket nothing: the guess is interpolated
#from the two powers and the next one from the result, so the hold ends at the crossing rather than at the sample nearest to it
func power_crossing_load(speed : float, density : float, pressure : float, weight : float, low_alpha : float, low_power : float, high_alpha : float, high_power : float) -> float:
	var load := NAN
	
	for step : int in TRIM_STEPS:
		if is_equal_approx(low_power, high_power): break
		
		var alpha : float = lerpf(low_alpha, high_alpha, clampf(low_power / (low_power - high_power), 0.0, 1.0))
		var reading := level_reading(alpha, speed, density, pressure, weight)
		if is_nan(reading.x): break
		if absf(reading.y) <= POWER_TOLERANCE:
			return reading.x
		
		load = reading.x
		if reading.y > 0.0:
			low_alpha = alpha
			low_power = reading.y
		else:
			high_alpha = alpha
			high_power = reading.y
	
	return load

#the mach range the aircraft itself lives in at this altitude: from under the speed its wing first carries it, to just over
#the fastest level flight it has. an airframe whose top speed and excess power are limited is not handed the room a fast one
#is, so its samples land where its curves actually are instead of in air it cannot fly in
func turn_mach_range(density : float, pressure : float, sound_speed : float, weight : float, fastest := NAN) -> Vector2:
	if is_nan(fastest): fastest = level_speed(density, pressure, sound_speed, weight)
	var top : float = TURN_MACH_LIMIT
	if not is_nan(fastest):
		top = clampf(fastest * 1.05 / sound_speed, TURN_MACH_START, TURN_MACH_LIMIT)
	
	#the bottom is the aircraft's own slowest flying speed, which is the speed its wheels leave the ground at: a chart that
	#started at a mach step of its own choosing would start above the wing for a fast airframe and below it for a slow one, and
	#the speed read off its first column would jump from one altitude to the next with nothing about the aircraft changing
	var slowest := carrying_speed(density, pressure, weight, 300.0 if is_nan(fastest) else fastest)
	var bottom : float = TURN_MACH_START
	if not is_nan(slowest): bottom = slowest * CARRYING_SPEED_MARGIN / maxf(sound_speed, 0.000001)
	
	#an aircraft with no level flight left anywhere, because it has no thrust to hold one, is still given a chart its size rather
	#than the full width of one. one that can fly but is faster than the sweep goes keeps the full width: the two used to share
	#this fallback, which shrank the whole envelope by a third at the height where the top speed stopped being found, and that
	#step is what a climb curve read off the top of the envelope showed as a cliff
	if is_nan(fastest) and is_nan(slowest):
		top = clampf(TURN_MACH_START * 3.0, TURN_MACH_START, TURN_MACH_LIMIT)
	
	return Vector2(clampf(bottom, 0.02, top), top)

#the slowest speed the wing still carries the aircraft at, walked in on because there is no lift curve to read it off. the
#walk keeps the lowest speed it has flown as one end of it, so the answer is always a speed the aircraft holds level flight at
#rather than a guess at the boundary
func carrying_speed(density : float, pressure : float, weight : float, ceiling_speed : float) -> float:
	var slow : float = ENVELOPE_SPEED_FLOOR
	var fast : float = maxf(ceiling_speed, ENVELOPE_SPEED_FLOOR * 2.0)
	if is_nan(level_power(fast, density, pressure, weight)): return NAN
	if is_finite(level_power(slow, density, pressure, weight)): return slow
	
	while fast - slow > CARRYING_SPEED_TOLERANCE:
		var middle : float = (slow + fast) * 0.5
		if is_finite(level_power(middle, density, pressure, weight)): fast = middle
		else: slow = middle
	
	return fast

#the Mach steps the chart is flown at: the number asked for, then split again wherever the column in the middle of two steps
#comes out somewhere those two would not have put it. the sweep ends up dense where the chart bends and coarse where it runs
#straight, rather than paying for the same spacing everywhere
func turn_columns(density : float, pressure : float, sound_speed : float, weight : float, fastest := NAN) -> Array[Dictionary]:
	var span := turn_mach_range(density, pressure, sound_speed, weight, fastest)
	var step : float = (span.y - span.x) / float(turn_datapoints - 1)
	var columns : Array[Dictionary] = []
	for index : int in turn_datapoints:
		columns.append(turn_performance_column(span.x + step * index, density, pressure, sound_speed, weight))
	
	for split : int in TURN_SPLITS:
		var denser : Array[Dictionary] = []
		for index : int in columns.size() - 1:
			var middle := turn_performance_column((columns[index].mach + columns[index + 1].mach) * 0.5, density, pressure, sound_speed, weight)
			denser.append(columns[index])
			if column_bends(columns[index], middle, columns[index + 1]): denser.append(middle)
		denser.append(columns[columns.size() - 1])
		columns = denser
	
	return columns

#whether a column flown between two others holds anything those two would have missed, which is read off the turn rate and the
#excess power at each of its angles of attack against the average of theirs
func column_bends(previous : Dictionary, middle : Dictionary, next : Dictionary) -> bool:
	if column_departure(previous.turn_rates, middle.turn_rates, next.turn_rates) > TURN_BEND_RATE: return true
	
	return column_departure(previous.powers, middle.powers, next.powers) > TURN_BEND_POWER

#how far one column's samples come from the average of the columns either side of it, at the worst of them
func column_departure(previous : PackedFloat64Array, middle : PackedFloat64Array, next : PackedFloat64Array) -> float:
	var departure := 0.0
	for index : int in mini(middle.size(), mini(previous.size(), next.size())):
		departure = maxf(departure, absf(middle[index] - (previous[index] + next[index]) * 0.5))
	
	return departure

#one Mach of the turn performance sweep: the load factor and turn rate at every angle of attack it can hold, the excess power
#at each of them, and the load factor the wing and the declared limit together allow there
func turn_performance_column(mach : float, density : float, pressure : float, sound_speed : float, weight : float, alpha_samples : int = TURN_ALPHA_SAMPLES) -> Dictionary:
	var speed := mach * sound_speed
	var loads := PackedFloat64Array()
	var turn_rates := PackedFloat64Array()
	var powers := PackedFloat64Array()
	var alphas := PackedFloat64Array()
	var level := NAN
	var crossing_load := NAN
	var previous_alpha := NAN
	var previous_load := NAN
	var previous_power := NAN
	
	for sample : int in alpha_samples:
		var alpha : float = remap(sample, 0, alpha_samples - 1, TURN_ALPHA_FLOOR, TURN_ALPHA_LIMIT)
		var force := force_on_level_attitude(alpha, speed, density, pressure)
		var load : float = force.x / weight
		var power : float = speed * force.y / weight
		
		#the straight and level sample comes first in every column: it is the bottom of the chart, a turn of no load factor, and the
		#excess power left over there is what lets an excess power contour run down to the axis and read the top speed off it. it is
		#read off this column's own samples rather than flown again, which is most of what a column used to cost
		if is_nan(level) and is_finite(load) and load >= 1.0:
			#the samples either side of the crossing bracket it, and the angle that carries the weight is walked in from them. a
			#crossing below the first sample, which is where a fast column's is, is walked in from the floor instead
			if is_nan(previous_alpha) or is_nan(previous_load):
				var floor_load : float = level_reading(TURN_ALPHA_FLOOR, speed, density, pressure, weight).x
				level = level_power_between(speed, density, pressure, weight, TURN_ALPHA_FLOOR, floor_load, alpha, load)
			else:
				level = level_power_between(speed, density, pressure, weight, previous_alpha, previous_load, alpha, load)
			
			loads.append(1.0)
			turn_rates.append(0.0)
			powers.append(level)
			alphas.append(alpha)
		
		#the angle the excess power runs out at is walked in from the samples either side of it, once for the column. reading it off
		#the samples alone stepped with their spacing, and that showed as a wave along the altitude charts because every column
		#stepped at a different point of it
		if is_nan(crossing_load) and is_finite(power) and power < 0.0 and is_finite(previous_power) and previous_power >= 0.0:
			crossing_load = power_crossing_load(speed, density, pressure, weight, previous_alpha, previous_power, alpha, power)
		
		previous_alpha = alpha
		previous_load = load
		previous_power = power
		
		#a turn needs the wing to carry more than the aircraft weighs, so a sample under that is no turn at all, and a sample the
		#model could not work out is left out rather than carried into the chart
		if load < 1.0 or not is_finite(load): continue
		
		loads.append(load)
		turn_rates.append(turn_rate(load, speed))
		powers.append(power)
		alphas.append(alpha)
	
	#the column is stopped at the angle of attack that holds the most load factor. past the stall the wing holds less and less,
	#so a contour read off that falling side sits at a lower load factor than one read off the rising side, which is how the
	#contours for two different excess powers came to cross each other
	var held_load := 0.0
	if not loads.is_empty():
		var peak := 0
		for index : int in loads.size():
			if loads[index] > loads[peak]: peak = index
		
		held_load = loads[peak]
		
		#the top of the load curve is walked in between the angles either side of the highest sample rather than read off a curve
		#through the three samples: that fit sits below the true peak by an amount that depends on where the angle grid happened to
		#fall, and every number built on the lift limit inherited the difference
		if peak > 0 and peak + 1 < alphas.size():
			held_load = maxf(held_load, load_peak_between(speed, density, pressure, weight, alphas[peak - 1], alphas[peak + 1]))
		
		loads.resize(peak + 1)
		turn_rates.resize(peak + 1)
		powers.resize(peak + 1)
		alphas.resize(peak + 1)
	
	return {
		"mach": mach,
		"speed": speed,
		"loads": loads,
		"turn_rates": turn_rates,
		"powers": powers,
		#the most the wing can hold, and the most the airframe is cleared for, which is what every line is clipped to
		"held_load": held_load,
		"limit_load": minf(held_load, load_limit),
		"level_power": level,
		"sustained": minf(crossing_load, minf(held_load, load_limit)) if not is_nan(crossing_load) else minf(held_load, load_limit),
	}

#the top of the load curve, walked in between two angles either side of the highest sampled one: the load rises to the stall and
#falls away past it, so the walk finds the top of that hump rather than the highest sample on it
func load_peak_between(speed : float, density : float, pressure : float, weight : float, low_alpha : float, high_alpha : float) -> float:
	var low := low_alpha
	var high := high_alpha
	var left := lerpf(low, high, 0.382)
	var right := lerpf(low, high, 0.618)
	var left_load := level_reading(left, speed, density, pressure, weight).x
	var right_load := level_reading(right, speed, density, pressure, weight).x
	var peak := maxf(left_load, right_load)
	
	for step : int in LIFT_PEAK_STEPS:
		if left_load >= right_load:
			high = right
			right = left
			right_load = left_load
			left = lerpf(low, high, 0.382)
			left_load = level_reading(left, speed, density, pressure, weight).x
			peak = maxf(peak, left_load)
		else:
			low = left
			left = right
			left_load = right_load
			right = lerpf(low, high, 0.618)
			right_load = level_reading(right, speed, density, pressure, weight).x
			peak = maxf(peak, right_load)
	
	return peak

#the radii of the ladder the envelope leaves room for, which is the ones whose line is more than a sliver across the chart
func turn_radii(columns : Array[Dictionary]) -> PackedFloat64Array:
	var radii := PackedFloat64Array()
	if columns.is_empty(): return radii
	
	var narrowest : float = (columns[columns.size() - 1].mach - columns[0].mach) * 0.1
	var widest_speed : float = columns[columns.size() - 1].speed
	var previous_rate := INF
	var radius := TURN_RADIUS_TIGHTEST
	while radius <= TURN_RADIUS_WIDEST:
		var curve := radius_curve(columns, radius)
		var rate := rad_to_deg(widest_speed / radius)
		if curve.size() > 1 and curve[curve.size() - 1].x - curve[0].x >= narrowest and previous_rate - rate >= TURN_RADIUS_MINIMUM_GAP:
			radii.append(radius)
			previous_rate = rate
		radius += TURN_RADIUS_STEP
	
	return radii

#the lift limit: the turn rate the wing can hold at every Mach without stalling, run up to where the declared load factor takes
#the limit over. the point where the two meet is worked out between the columns either side of it, so the lift limit always
#ends exactly on the last load factor line rather than a column away from it
func lift_limit_curve(columns : Array[Dictionary]) -> PackedVector2Array:
	var curve := PackedVector2Array()
	var previous : Dictionary = {}
	for column : Dictionary in columns:
		if column.held_load >= 1.0 and curve.is_empty() and not previous.is_empty():
			#the bottom corner of the envelope, where the wing can only just carry the aircraft in level flight
			curve.append(meets_lift_limit(previous, column, 1.0))
		if column.held_load < 1.0:
			previous = column
			continue
		
		if column.held_load >= load_limit:
			if not previous.is_empty(): curve.append(meets_lift_limit(previous, column, load_limit))
			break
		
		curve.append(Vector2(column.mach, turn_rate(column.held_load, column.speed)))
		previous = column
	
	return curve

#the turn rate against Mach where the aircraft holds this load factor, running from where the limit curve reaches it to where
#the limit leaves it again
func load_curve(columns : Array[Dictionary], load : float) -> PackedVector2Array:
	var curve := PackedVector2Array()
	var previous : Dictionary = {}
	var was_held := false
	for column : Dictionary in columns:
		var held : bool = column.held_load >= load
		
		if held:
			if not was_held and not previous.is_empty(): curve.append(meets_lift_limit(previous, column, load))
			curve.append(Vector2(column.mach, turn_rate(load, column.speed)))
		elif was_held:
			curve.append(meets_lift_limit(previous, column, load))
			break
		
		previous = column
		was_held = held
	
	return curve

#where a load factor line meets the lift limit between two columns, which is the point it starts or stops at. every load factor
#line ends on the lift limit, including the last of them, which ends on the corner where the lift limit reaches the g limit
func meets_lift_limit(previous : Dictionary, column : Dictionary, load : float) -> Vector2:
	var along := straddle_fraction(previous.held_load - load, column.held_load - load)
	var speed : float = lerpf(previous.speed, column.speed, along)
	
	return Vector2(lerpf(previous.mach, column.mach, along), turn_rate(load, speed))

#where a line holding this load factor meets the envelope between two columns, as the point that line passes through there.
#the load factor is what the line itself is at either side of the crossing
func meets_limit(previous : Dictionary, column : Dictionary, previous_load : float, load : float) -> Vector2:
	var along := limit_crossing_along(previous, column, previous_load, load)
	var speed : float = lerpf(previous.speed, column.speed, along)
	
	return Vector2(lerpf(previous.mach, column.mach, along), turn_rate(lerpf(previous_load, load, along), speed))

#whether the straight and level power changes sides of this contour's level between two columns, which is what says the
#contour runs out at the bottom of the chart there rather than being above anything the aircraft can do at that speed
func level_straddles(previous : Dictionary, column : Dictionary, power : float) -> bool:
	var before : float = previous.get("level_power", NAN)
	var after : float = column.get("level_power", NAN)
	if not is_finite(before) or not is_finite(after): return false
	
	return (before - power) * (after - power) <= 0.0

#where a contour starts or ends on the bottom of the chart rather than on the envelope, which is the speed its excess power
#runs out at. the far end of it is where its top speed is read
func leaves_bottom(previous : Dictionary, column : Dictionary, power : float) -> Vector2:
	var along := straddle_fraction(previous.level_power - power, column.level_power - power)
	
	return Vector2(lerpf(previous.mach, column.mach, along), 0.0)

#the point on the envelope at one column, which is where a contour enters it or leaves it when the next column has nothing the
#contour can reach at all: the load it takes is more than the wing holds there
func envelope_point(column : Dictionary) -> Vector2:
	return Vector2(column.mach, turn_rate(column.limit_load, column.speed))

#where a contour starts on the bottom of the chart past the last column that could fly level: walked up from the corner of the
#envelope, which is where the aircraft has no power to spare, to this column, which has at least as much as the contour takes
func bottom_corner_entry(previous : Dictionary, column : Dictionary, power : float) -> Vector2:
	var corner : float = meets_lift_limit(previous, column, 1.0).x
	var along := 0.0
	if is_finite(column.level_power) and column.level_power > 0.0: along = clampf(power / column.level_power, 0.0, 1.0)
	
	return Vector2(lerpf(corner, column.mach, along), 0.0)

#the turn rate against Mach along one excess power contour, as the stretches of it that lie inside the envelope. a contour
#leaves the envelope where holding it would take more load factor than the aircraft has at that Mach, and often comes back in
#further along where the wing has caught up with it, so the contour is not finished at the first crossing
func power_curves(columns : Array[Dictionary], power : float) -> Array[PackedVector2Array]:
	var runs : Array[PackedVector2Array] = []
	var run := PackedVector2Array()
	var previous : Dictionary = {}
	var previous_load := NAN
	var was_held := false
	for column : Dictionary in columns:
		var load : float = interpolate_column(column.powers, column.loads, power)
		var held : bool = not is_nan(load) and load >= 1.0 and load <= column.limit_load
		
		if held:
			#a stretch that starts after a gap is opened on the crossing rather than at the column itself. the contour comes in on
			#the bottom of the chart where the straight and level power has just come up to its level, and on the envelope where the
			#wing has just caught up with the load it takes
			if not was_held and not previous.is_empty():
				if level_straddles(previous, column, power):
					run.append(leaves_bottom(previous, column, power))
				elif previous.limit_load >= 1.0:
					#the wing had no load to give the contour at the column before, so the contour comes in on the envelope
					run.append(envelope_point(previous))
				else:
					#the column before could not fly level either, so the contour starts on the bottom of the chart
					run.append(bottom_corner_entry(previous, column, power))
			
			run.append(Vector2(column.mach, turn_rate(load, column.speed)))
		elif was_held:
			if not is_nan(load):
				run.append(meets_limit(previous, column, previous_load, load))
			elif level_straddles(previous, column, power):
				#nothing in this column has the power left for the contour, and the straight and level powers either side of it
				#straddle the level: it has run out at the bottom of the chart, where a turn of no load factor is
				run.append(leaves_bottom(previous, column, power))
			else:
				#nothing in this column has the load the contour takes, so it is on the envelope when it goes
				run.append(envelope_point(previous))
			
			if run.size() > 1: runs.append(run)
			run = PackedVector2Array()
		
		previous = column
		previous_load = load
		was_held = held
	
	if run.size() > 1: runs.append(run)
	return runs

#the turn rate against Mach along a circle of this radius, from where the circle is a 1 g turn or the airframe can first hold it,
#to where it cannot
func radius_curve(columns : Array[Dictionary], radius : float) -> PackedVector2Array:
	var curve := PackedVector2Array()
	var previous : Dictionary = {}
	var previous_load := NAN
	var was_held := false
	#the speed the circle is a 1 g turn at, which is where its line starts whenever the airframe can hold it more easily than that
	var one_g_speed := sqrt(radius * GRAVITY)
	
	for column : Dictionary in columns:
		#the load factor a circle of this radius takes at this speed, and the part of it pulled sideways, which is the turn itself
		var sideways : float = column.speed * column.speed / (radius * GRAVITY)
		var load : float = sqrt(1.0 + sideways * sideways)
		var held : bool = column.limit_load >= load and sideways >= 1.0
		
		#a line that has just started sits on the later of the two boundaries the circle crossed on its way up: the 1 g one, and the
		#one the airframe can just hold it on. the crossing sits on the circle itself, so the line starts on the ray rather than a
		#shade off it
		if held and not was_held and not previous.is_empty():
			var along := clampf((one_g_speed - previous.speed) / (column.speed - previous.speed), 0.0, 1.0)
			if previous.limit_load < previous_load:
				along = maxf(along, limit_crossing_along(previous, column, previous_load, load))
			curve.append(circle_point(previous, column, along, radius))
		
		if held:
			curve.append(Vector2(column.mach, rad_to_deg(column.speed / radius)))
		elif was_held:
			curve.append(circle_point(previous, column, limit_crossing_along(previous, column, previous_load, load), radius))
			break
		
		previous = column
		previous_load = load
		was_held = held
	
	return curve

#the point on a circle of this radius this share of the way between two columns
func circle_point(previous : Dictionary, column : Dictionary, along : float, radius : float) -> Vector2:
	var speed : float = lerpf(previous.speed, column.speed, along)
	
	return Vector2(lerpf(previous.mach, column.mach, along), rad_to_deg(speed / radius))

#where a family line and the limit curve cross between two columns, as the fraction of the way from the first to the second
func limit_crossing_along(previous : Dictionary, column : Dictionary, previous_load : float, load : float) -> float:
	return straddle_fraction(previous_load - previous.limit_load, load - column.limit_load)

#the excess power contours to draw: the turns the aircraft can hold, from the line of no spare power up to the most it has,
#in equal steps, and the turns it loses energy in, which run from a few meters a second in a gentle turn to thousands at the
#stall and so step through 1, 2 and 5 of each decade. a sample too far out to be a force reading is left out, because one of
#them would set the range every contour on the chart is drawn from
func power_contours(columns : Array[Dictionary]) -> PackedFloat64Array:
	var highest := -INF
	var lowest := INF
	for column : Dictionary in columns:
		for power : float in column.powers:
			if not is_finite(power) or absf(power) > POWER_SANITY_LIMIT: continue
			highest = maxf(highest, power)
			lowest = minf(lowest, power)
	
	var levels := PackedFloat64Array()
	if is_inf(highest): return levels
	
	#the turns it can hold, from the line of no spare power up to the most it has, in equal steps of a number worth reading
	if highest > 0.0:
		var step := nice_step(highest / 4.0)
		if is_finite(step) and step > 0.0:
			var level := 0.0
			while level <= highest and levels.size() < 6:
				levels.append(level)
				level += step
	
	#the turns it loses energy in: a few meters a second in a gentle turn and thousands at the stall, so those levels step through
	#1, 2 and 5 of each decade, down from a decade that spans the loss the chart actually reaches
	if lowest < 0.0:
		var reference : float = -highest if highest < 0.0 else -lowest * 0.1
		var decade := pow(10.0, floorf(log(reference) / log(10.0)))
		var drawn := 0
		while drawn < 6 and -decade >= lowest:
			for tidiness : float in [1.0, 2.0, 5.0]:
				var level := -decade * tidiness
				if drawn >= 6 or level < lowest: continue
				levels.append(level)
				drawn += 1
			decade *= 10.0
	
	return levels


#the airframe: what a sweep borrows from the aircraft it flies, and what it asks of it along the way

#winds the throttle open for a sweep and silences the flight model while it runs: a throttle going up and down inside a sweep
#is the sweep's own doing, and taking it for a change to the flight model would have the aircraft fly itself again
func hold_open_throttle() -> Dictionary:
	var held := {"throttle": 0.0, "thrusters": {}, "silenced": [] as Array[AeroInfluencer3D]}
	if not control: return held
	
	#a control axis smooths and accumulates as it is driven, so the copy of an aircraft that has been flying would be swept from
	#wherever its controls were left. every one of them is put back to nothing before the throttle is wound open
	reset_control_axes()
	
	for influencer : AeroInfluencer3D in influencers:
		if influencer == null or influencer.suppress_flight_model_changed: continue
		influencer.suppress_flight_model_changed = true
		held.silenced.append(influencer)
	
	#the thrusters are wound open on both of the wires thrust arrives by: the control command below, which a thruster's own config
	#reads, and the thruster itself, so the throttle is open whichever of them the sweep reaches it by. each thruster's own
	#throttle is kept, to be put back once the sweep is done
	for thruster : AeroThruster3D in thrusters:
		if thruster == null: continue
		
		held.thrusters[thruster] = thruster.throttle
		var throttle_config : AeroInfluencerControlConfig = thruster.throttle_control_config
		thruster.throttle = throttle_config.min_value if throttle_config else Vector3(0, 0, -1)
	
	held.throttle = control.get_control_command(THROTTLE_AXIS)
	control.set_control_command(THROTTLE_AXIS, 1.0)
	
	#every control is then driven to the state that command holds it in, so the sweep starts with the engine spooled and the
	#surfaces where they belong rather than ramping through its first columns
	settle_controls()
	
	#one attitude is flown before the sweep starts, so anything turning has taken up its speed and the first sample of the chart
	#is read the same way as every other one
	force_and_torque_at(Transform3D(), 100.0, density, pressure)
	return held

#every control axis put back to nothing, which is what a sweep with the throttle closed flies at
func reset_control_axes() -> void:
	if not control: return
	
	for axis : AeroControlConfigAxis in control.control_config.axis_configs:
		axis.input = 0.0
		axis.smoothed_input = 0.0
		axis.command = 0.0
		axis.cumulative_input = 0.0
		axis.cumulative_command = 0.0

#every control of the aircraft driven to the state its command holds it in: a config that ramps toward its command, or holds the
#value it was last driven to, would otherwise sweep from wherever the aircraft happened to be left
func settle_controls() -> void:
	for influencer : AeroInfluencer3D in influencers:
		if influencer == null: continue
		if influencer.actuation_config: influencer.actuation_config.update(influencer, CONTROL_SETTLE_TIME)
		
		var thruster := influencer as AeroThruster3D
		if thruster and thruster.throttle_control_config: thruster.throttle_control_config.update(influencer, CONTROL_SETTLE_TIME)
		
		var propeller := influencer as AeroPropeller3D
		if propeller and propeller.propeller_speed_control_config: propeller.propeller_speed_control_config.update(influencer, CONTROL_SETTLE_TIME)
		
		var cyclic := influencer as AeroCyclicPropeller3D
		if cyclic and cyclic.cyclic_control_config: cyclic.cyclic_control_config.update(influencer, CONTROL_SETTLE_TIME)

#puts back what the sweep borrowed
func restore_throttle(held : Dictionary) -> void:
	if control:
		control.set_control_command(THROTTLE_AXIS, held.throttle)
		for thruster : AeroThruster3D in held.thrusters: thruster.throttle = held.thrusters[thruster]
	
	for influencer : AeroInfluencer3D in held.silenced: influencer.suppress_flight_model_changed = false

#the force and torque on the aircraft flying an attitude at a speed through that air. the arguments are the whole simulation
#state: not one thing is read from the body's own transform or position. an aircraft with something turning is read a quarter of
#a turn apart and averaged, so the same attitude always gives the same answer
func force_and_torque_at(attitude : Transform3D, speed : float, density : float, pressure : float) -> PackedVector3Array:
	if not movers_gathered: gather_movers()
	
	var velocity := Vector3(0, 0, -speed)
	place_movers(0.0)
	var reading := body.calculate_forces_manual(attitude, velocity, Vector3.ZERO, altitude, density, pressure)
	if not movers_are_turning(): return reading
	
	place_movers(PROPELLER_PHASE)
	var quarter_turn_reading := body.calculate_forces_manual(attitude, velocity, Vector3.ZERO, altitude, density, pressure)
	
	return PackedVector3Array([
		(reading[0] + quarter_turn_reading[0]) * 0.5,
		(reading[1] + quarter_turn_reading[1]) * 0.5,
	])

#the lift and the forward force on the aircraft at one angle of attack, flying level at a speed through that air. both are
#forces, so a load factor is the lift over the weight and an excess power is the forward force times the speed over it
func force_on_level_attitude(alpha : float, speed : float, density : float, pressure : float) -> Vector2:
	var attitude := Transform3D(Basis.from_euler(Vector3(deg_to_rad(alpha), 0, 0)), Vector3.ZERO)
	var force : Vector3 = force_and_torque_at(attitude, speed, density, pressure)[0]
	
	return Vector2(force.dot(calculate_lift_direction(attitude.basis)), -force.dot(AIR_DIRECTION))

#the load factor and the power left over at one angle, in level flight at this speed
func level_reading(alpha : float, speed : float, density : float, pressure : float, weight : float) -> Vector2:
	var force := force_on_level_attitude(alpha, speed, density, pressure)
	return Vector2(force.x / weight, speed * force.y / weight)

#the power left over at the angle that carries the aircraft's weight, walked in between two angles whose loads bracket one g. the
#guess is interpolated from the two loads, and the next one from the result of that, so the answer is the crossing itself rather
#than the sample or the chord nearest to it, and it does not move when the grid of samples does
func level_power_between(speed : float, density : float, pressure : float, weight : float, low : float, low_load : float, high : float, high_load : float) -> float:
	for step : int in TRIM_STEPS:
		if is_zero_approx(high_load - low_load): break
		
		var alpha : float = lerpf(low, high, clampf((1.0 - low_load) / (high_load - low_load), 0.0, 1.0))
		var reading := level_reading(alpha, speed, density, pressure, weight)
		if is_nan(reading.x): return NAN
		if absf(reading.x - 1.0) <= TRIM_LOAD_TOLERANCE: return reading.y
		
		if reading.x < 1.0:
			low = alpha
			low_load = reading.x
		else:
			high = alpha
			high_load = reading.x
	
	return level_reading((low + high) * 0.5, speed, density, pressure, weight).y

#the parts of the aircraft that turn, and where each of them sat before the sweep turned anything: gathered once, the first time
#an attitude is flown. a mover that reads its velocity off its own movement is left out, because putting it back would take that
#velocity away
func gather_movers() -> void:
	movers_gathered = true
	for influencer : AeroInfluencer3D in influencers:
		var mover := influencer as AeroMover3D
		if not mover or mover.use_movement_as_velocity: continue
		
		movers.append(mover)
		mover_rests[mover] = mover.default_transform

#whether anything on the aircraft is turning, which is only true once the throttle is open: the static sweeps leave it closed, so
#they fly in a single pass
func movers_are_turning() -> bool:
	for mover in movers:
		if mover.angular_motor.length_squared() > 0.0: return true
	
	return false

#puts every moving part a share of a whole turn round its axis, counted from where it started
func place_movers(turn : float) -> void:
	for mover in movers:
		var rest : Transform3D = mover_rests[mover]
		var axis : Vector3 = mover.angular_motor.normalized()
		if axis.length_squared() <= 0.0: continue
		
		mover.default_transform = Transform3D(rest.basis * Basis(axis, TAU * turn), rest.origin)

#the direction lift is measured along for an attitude: the body's up axis less the part of it running with the airflow, kept
#on the side the chord says once the projection alone would flip over past 90 degrees
func calculate_lift_direction(basis : Basis) -> Vector3:
	var planar_lift_direction := (basis.y * AIR_DIRECTION.dot(basis.z) - basis.z * basis.y.dot(AIR_DIRECTION)).normalized()
	var projected_lift_direction := basis.y - AIR_DIRECTION * basis.y.dot(AIR_DIRECTION)
	if projected_lift_direction.length_squared() <= 0.0001: return planar_lift_direction
	
	projected_lift_direction = projected_lift_direction.normalized()
	return -projected_lift_direction if projected_lift_direction.dot(planar_lift_direction) < 0.0 else projected_lift_direction

#the coefficients of one attitude, which is what every graph in the static analysis is drawn from
func calculate_coefficients(transform : Transform3D) -> Dictionary:
	if not body: return {}
	if test_speed <= 0.0: return {}
	if reference_area <= 0.0 or reference_span <= 0.0 or reference_chord <= 0.0: return {}
	
	var force_and_torque := force_and_torque_at(transform, test_speed, density, pressure)
	
	var dynamic_pressure : float = 0.5 * density * test_speed * test_speed
	if dynamic_pressure <= 0.0: return {}
	
	var basis := transform.basis.orthonormalized()
	var force : Vector3 = force_and_torque[0]
	var torque : Vector3 = force_and_torque[1]
	var reference_force : float = dynamic_pressure * reference_area
	
	return {
		"lift": force.dot(calculate_lift_direction(basis)) / reference_force,
		"drag": force.dot(AIR_DIRECTION) / reference_force,
		"pitch": torque.dot(basis.x) / (reference_force * reference_chord),
		#raw moments about the body axes, which is how a pilot reads pitch/yaw/roll
		"moment_x": torque.dot(basis.x),
		"moment_y": torque.dot(basis.y),
		"moment_z": torque.dot(basis.z),
	}


#reference dimensions

#the dimensions the coefficients are taken against, kept on the sweep so the panel can show them
func measure_reference_dimensions() -> void:
	if reference_area > 0.0 and reference_span > 0.0 and reference_chord > 0.0: return
	
	#a surface can hang off another influencer, like a wing on a swing pivot, so where its tips actually land has to
	#be measured in the body's own space rather than from the position it holds under its parent
	var to_body : Transform3D = body.global_transform.affine_inverse()
	var total_area := 0.0
	var chord_area := 0.0
	var lowest_tip := INF
	var highest_tip := -INF
	
	for node : AeroInfluencer3D in influencers:
		var surface := node as AeroSurface3D
		if not surface: continue
		
		var wing_config : AeroSurfaceConfig = surface.get_wing_config()
		if not wing_config: continue
		
		total_area += wing_config.get_area()
		chord_area += wing_config.get_area() * wing_config.get_chord()
		
		#the span runs along the surface's own x axis, which points up on a vertical fin and so adds no width
		var placement : Transform3D = to_body * surface.global_transform
		for side : float in [-0.5, 0.5]:
			var tip : Vector3 = placement * Vector3(wing_config.get_span() * side, 0, 0)
			lowest_tip = minf(lowest_tip, tip.x)
			highest_tip = maxf(highest_tip, tip.x)
	
	if total_area <= 0.0 or is_inf(lowest_tip): return
	
	#the span is what the tips measure out to, except on a body with nothing sticking out sideways, like one made of fins
	#only. there the mean chord of the surfaces is all there is to go on, and the span comes back from it
	var span : float = highest_tip - lowest_tip
	var mean_chord : float = chord_area / total_area
	if is_zero_approx(span) and mean_chord > 0.0: span = total_area / mean_chord
	
	#a dimension set by hand is kept, and the ones left at 0 take what the aircraft measures out to. a body with no width
	#to it at all is left without one rather than given an endless chord, which the sweeps then report as no data
	if reference_area <= 0.0: reference_area = total_area
	if reference_span <= 0.0: reference_span = span
	if reference_chord <= 0.0 and not is_zero_approx(reference_span): reference_chord = reference_area / reference_span





#utils: the arithmetic the sweeps are read with, which knows nothing of aircraft, charts or docks, and is here
#rather than beside the sweeps that use it, because most of it is used from more than one of them

#the turn rate a level turn at this load factor comes to at this speed, in degrees per second
func turn_rate(load : float, speed : float) -> float:
	if load <= 1.0 or speed <= 0.0: return 0.0
	return rad_to_deg(GRAVITY * sqrt(load * load - 1.0) / speed)

#the radius a level turn at this load factor comes to at this speed, in meters
func turn_radius(load : float, speed : float) -> float:
	if load <= 1.0 or speed <= 0.0: return NAN
	return speed * speed / (GRAVITY * sqrt(load * load - 1.0))

#a speed at another mach of the same air, which is what a column at this one says the speed there is
func speed_at_mach(column : Dictionary, mach : float) -> float:
	return column.speed * mach / maxf(column.mach, 0.000001)

#the value at a target on one of the sweep's columns, interpolated between the two samples either side of it, or NAN when the
#column never reaches the target
func interpolate_column(samples : PackedFloat64Array, values : PackedFloat64Array, target : float) -> float:
	for index : int in samples.size() - 1:
		var low := samples[index]
		var high := samples[index + 1]
		if target < minf(low, high) or target > maxf(low, high): continue
		if is_equal_approx(low, high): continue
		return lerpf(values[index], values[index + 1], (target - low) / (high - low))
	
	return NAN

#how far between two samples a value passes from one side of zero to the other, as the share of the way from the first to the second
func straddle_fraction(before : float, after : float) -> float:
	if is_zero_approx(before - after): return 0.0
	
	return clampf(before / (before - after), 0.0, 1.0)

#the value of the curve through three points at one of them
func curve_through(first : Vector2, second : Vector2, third : Vector2, x : float) -> float:
	var one : float = (x - second.x) * (x - third.x) / ((first.x - second.x) * (first.x - third.x)) * first.y
	var two : float = (x - first.x) * (x - third.x) / ((second.x - first.x) * (second.x - third.x)) * second.y
	var three : float = (x - first.x) * (x - second.x) / ((third.x - first.x) * (third.x - second.x)) * third.y
	
	return one + two + three

#the turning point of the curve through three samples, as a position between them and the value there. the columns either side of the
#one being refined are not evenly spaced, so the curve is fitted through the three points as they sit
func parabola_turning_point(before : Vector2, middle : Vector2, after : Vector2) -> Vector2:
	#the fit needs three points in order: anything else is a sweep the caller has not sorted, and the curve through it means nothing
	if not (before.x < middle.x and middle.x < after.x): return middle
	
	var span : float = after.x - before.x
	if is_zero_approx(span): return middle
	
	var first_slope : float = (middle.y - before.y) / maxf(middle.x - before.x, 0.000001)
	var second_slope : float = (after.y - middle.y) / maxf(after.x - middle.x, 0.000001)
	var curvature : float = (second_slope - first_slope) / span
	if is_zero_approx(curvature): return middle
	
	var mach : float = clampf((before.x + middle.x) * 0.5 - first_slope / (2.0 * curvature), before.x, after.x)
	var along : float = mach - middle.x
	
	return Vector2(mach, middle.y + first_slope * along + curvature * along * (mach - before.x))

#the peak or the valley of the curve through the samples around one of them, as the position between them and the value there.
#a sample with one beside it the sweep could not work out is left as it is: the curve through those means nothing
func refined_extreme(columns : Array[Dictionary], values : PackedFloat64Array, best : int, smallest : bool) -> Vector2:
	var value : float = values[best]
	if best == 0 or best + 1 >= columns.size(): return Vector2(columns[best].mach, value)
	if not is_finite(values[best - 1]) or not is_finite(values[best + 1]): return Vector2(columns[best].mach, value)
	
	var turned := parabola_turning_point(
		Vector2(columns[best - 1].mach, values[best - 1]),
		Vector2(columns[best].mach, value),
		Vector2(columns[best + 1].mach, values[best + 1]))
	
	return Vector2(turned.x, minf(value, turned.y) if smallest else maxf(value, turned.y))

#the top of a sampled curve, read off the three samples around it: the peak of a curve through them sits above the highest
#sample unless that sample happened to land on top of it, and this is what keeps the lift limit and the corner from stepping
#with the sample spacing
func refined_peak_load(before : float, at : float, after : float) -> float:
	var curvature := 2.0 * at - before - after
	if curvature <= 0.0: return at
	
	var rise := (after - before) * (after - before) / (8.0 * curvature)
	
	#a peak can rise no further above its sample than the drop to the lower of the two beside it
	return at + minf(rise, at - minf(before, after))

#a step rounded up to 1, 2 or 5 times a power of ten, so the contours land on numbers worth reading
func nice_step(raw_step : float) -> float:
	if raw_step <= 0.0: return 1.0
	
	var magnitude := pow(10.0, floorf(log(raw_step) / log(10.0)))
	for tidiness : float in [1.0, 2.0, 5.0, 10.0]:
		if raw_step / magnitude <= tidiness: return magnitude * tidiness
	
	return magnitude * 10.0
