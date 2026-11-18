@tool
extends VBoxContainer
##The wind tunnel dock: the panels, the settings they are flown at, and the routing that decides which aircraft is being
##looked at. the sweeps live at the bottom of this script, and know nothing of graphs, labels or the editor.

#the color each curve is drawn in, in the order the sweeps reach for them
const CURVE_COLORS := [
	Color(1.0, 0.35, 0.35), Color(0.4, 1.0, 0.45), Color(0.45, 0.7, 1.0),
	Color(1.0, 0.83, 0.4), Color(0.8, 0.6, 1.0),
]
#what a field says when there is nothing to report
const NO_DATA := "n/a"

@export_group("Sweep")
##Airspeed every point of a sweep is flown at.
@export var test_speed : float = 250:
	set(value):
		test_speed = value
		queue_recalculate()

##Points simulated in each sweep. Drop it for a quick look at the shape of a curve, raise it to smooth the curves out.
@export var sweep_datapoints : int = 96:
	set(value):
		sweep_datapoints = maxi(value, 2)
		queue_recalculate()

@export_group("Reference dimensions")
##Reference dimensions for the coefficients. Left at 0 they are estimated from the aircraft the dock has open, and they
##are estimated again when another aircraft is opened. A value set by hand overrides the estimate until then.
@export var reference_area : float = 0.0
@export var reference_span : float = 0.0
@export var reference_chord : float = 0.0

@export_group("Turn performance")
##Altitude the dock flies at, in metres above sea level. Every graph uses the air this declares, so nothing depends on where
##the aircraft sits in the scene.
@export var altitude : float = 5000.0:
	set(value):
		altitude = value
		turn_performance_stale = true
		queue_recalculate()

##The load factor the airframe is cleared for, which caps the turn rate the wing could otherwise reach.
@export var load_limit : float = 9.0:
	set(value):
		load_limit = value
		turn_performance_stale = true
		queue_recalculate()

##Mach steps the turn performance is sampled at, each of them flown through the whole angle of attack sweep.
@export var turn_datapoints : int = 64:
	set(value):
		turn_datapoints = maxi(value, 2)
		turn_performance_stale = true
		queue_recalculate()

var aerobody : AeroBody3D = null:
	set(value):
		if aerobody == value: return
		
		if aerobody and aerobody.flight_model_changed.is_connected(queue_flight_model_changed):
			aerobody.flight_model_changed.disconnect(queue_flight_model_changed)
		
		aerobody = value
		
		#another aircraft measures out to different dimensions, so the ones the last one came to are dropped and measured
		#again for this one. naming no aircraft drops them too, so the next one is never given the old ones
		reference_area = 0.0
		reference_span = 0.0
		reference_chord = 0.0
		
		#nothing is redrawn for an aircraft that is not there: the last one's results stay on screen, so they can still be
		#read while another scene is open
		if aerobody:
			queue_flight_model_changed()
			aerobody.flight_model_changed.connect(queue_flight_model_changed)


#virtuals

func _ready() -> void:
	resized.connect(fit_graph_columns)
	fit_graph_columns()
	
	#the performance chart carries a family of lines, so its readout reports the one under the cursor rather than every line
	#crossing it, and says what the value it reports is measured in
	%TurnPerformanceGraph.readout_mode = AeroGraph.ReadoutMode.NEAREST_POINT
	%TurnPerformanceGraph.readout_value_suffix = " deg/s"
	
	if not Engine.is_editor_hint(): return
	
	#the dock can be built, or reopened, after a scene is already open, so scene_changed never fires for it
	visibility_changed.connect(func() -> void: _on_editor_scene_changed(EditorInterface.get_edited_scene_root()))
	EditorInterface.get_selection().selection_changed.connect(_on_editor_selection_changed)
	
	#the editor restores the scene it had open a few frames after the dock is built, so wait for it instead of missing it
	var frames_left := 120
	while frames_left > 0 and EditorInterface.get_edited_scene_root() == null:
		await get_tree().process_frame
		frames_left -= 1
	
	_on_editor_scene_changed(EditorInterface.get_edited_scene_root())

#editor

#the dock reports on the aircraft the open scene is built around
func _on_editor_scene_changed(scene_root : Node) -> void:
	if not is_visible_in_tree(): return
	
	if scene_root is AeroBody3D:
		aerobody = scene_root

#picking a node moves the dock onto the aircraft that node is part of, so clicking a wing reports on the body it belongs to
func _on_editor_selection_changed() -> void:
	if not is_visible_in_tree(): return
	
	var selected := EditorInterface.get_selection().get_selected_nodes()
	if selected.is_empty(): return
	
	var body := find_aerobody(selected[0])
	if body: aerobody = body

#the body a node belongs to, which is the node itself when it is one. only the selection and what it hangs off decide
#which aircraft is being looked at, so nothing else in the scene is searched for one
func find_aerobody(node : Node) -> AeroBody3D:
	var scene_root := EditorInterface.get_edited_scene_root()
	while node:
		if node is AeroBody3D: return node
		if node == scene_root: return null
		node = node.get_parent()
	
	return null

#layout

#two graph columns need roughly this much width to stay readable, so a narrow dock stacks them instead
var two_column_width := 860.0

func fit_graph_columns() -> void:
	%GraphGrid.columns = 2 if size.x >= two_column_width else 1


#recalculating

#set while a recalculation is waiting for the next idle frame, which is what keeps a burst of changes to one sweep
var recalculation_queued := false

#set when something the turn performance is flown from changed: the aircraft, its configuration or the air the dock is
#declared to fly in. the settings that only move the other graphs leave it alone, so a change of test speed or datapoint
#count does not fly the turn sweep again
var turn_performance_stale := true

#asks for a recalculation on the next idle frame, so dragging a spinbox or moving a wing re-runs the sweeps once the
#changes settle instead of once per change
func queue_recalculate() -> void:
	#the exported setters also run while the dock is still being built, where there is nothing to report on yet
	if not is_inside_tree(): return
	if recalculation_queued: return
	
	recalculation_queued = true
	recalculate.call_deferred()

#the aircraft changing shape or moving an influencer changes what it can turn at, so the performance sweep is queued too
func queue_flight_model_changed() -> void:
	turn_performance_stale = true
	queue_recalculate()

#one pass over the aircraft: every graph refilled from the sweeps, then the metrics
func recalculate() -> void:
	recalculation_queued = false
	
	#with no aircraft named the dock keeps what it is showing rather than blanking it, which is what leaves the last
	#aircraft's results there to be read while another scene is open
	if not aerobody: return
	
	%AircraftName.text = aerobody.name
	
	var results := static_analysis()
	
	draw_static_analysis(results)
	
	if turn_performance_stale:
		turn_performance_stale = false
		draw_turn_performance(turn_performance())


#drawing

#the static analysis: the coefficient curves, the moment curves, the drag polar and the numbers under them
func draw_static_analysis(results : Dictionary) -> void:
	var alpha : Dictionary = results.alpha
	var beta : Dictionary = results.beta
	
	assign_curves(%LiftDragGraph, [
		{"color": CURVE_COLORS[0], "name": "CL", "points": alpha.lift},
		{"color": CURVE_COLORS[1], "name": "CD", "points": alpha.drag},
		{"color": CURVE_COLORS[2], "name": "L/D", "points": alpha.ratio, "normalized_y": true},
	])
	
	assign_curves(%PitchMomentsGraph, [
		{"color": CURVE_COLORS[0], "name": "Mx (pitch)", "points": alpha.pitch},
		{"color": CURVE_COLORS[1], "name": "My (yaw)", "points": alpha.yaw},
		{"color": CURVE_COLORS[2], "name": "Mz (roll)", "points": alpha.roll},
	])
	
	assign_curves(%SideslipMomentsGraph, [
		{"color": CURVE_COLORS[0], "name": "Mx (pitch)", "points": beta.pitch},
		{"color": CURVE_COLORS[1], "name": "My (yaw)", "points": beta.yaw},
		{"color": CURVE_COLORS[2], "name": "Mz (roll)", "points": beta.roll},
	])
	
	assign_curves(%RollMomentsGraph, [
		{"color": CURVE_COLORS[2], "name": "Mz (roll)", "points": results.roll.moment},
	])
	
	assign_curves(%PolarGraph, [
		{"color": CURVE_COLORS[2], "name": "CL vs CD", "points": alpha.polar, "parameters": alpha.polar_alphas},
	])
	
	update_metrics(results.metrics)

#every field is blank until the number it is read off says otherwise
func update_metrics(metrics : Dictionary) -> void:
	for value_label : Label in [%SpeedValue, %PressureValue, %AreaValue, %SpanValue, %ChordValue, %LiftMaxValue, %RatioValue, %GlideValue, %SinkValue, %StiffnessValue, %MarginValue]:
		value_label.text = NO_DATA
	
	%SpeedValue.text = "%.0f m/s" % test_speed
	%PressureValue.text = "%.1f kPa" % (metrics.dynamic_pressure / 1000.0)
	%AreaValue.text = "%.2f m²" % reference_area
	%SpanValue.text = "%.2f m" % reference_span
	%ChordValue.text = "%.2f m" % reference_chord
	
	if not is_nan(metrics.lift_max):
		%LiftMaxValue.text = "%.3f (at %.1f°)" % [metrics.lift_max, metrics.lift_max_alpha]
	if not is_nan(metrics.ratio):
		%RatioValue.text = "%.2f (at %.1f°)" % [metrics.ratio, metrics.ratio_alpha]
	if not is_nan(metrics.glide_speed):
		%GlideValue.text = "%.1f m/s" % metrics.glide_speed
	if not is_nan(metrics.sink_rate):
		%SinkValue.text = "%.1f m/s" % metrics.sink_rate
	if not is_nan(metrics.stiffness):
		%StiffnessValue.text = "%.3f" % metrics.stiffness
	if not is_nan(metrics.margin):
		%MarginValue.text = "%.1f %% chord" % metrics.margin

#the turn performance chart: the families of lines, the names of each family, and the conditions the chart is flown at
func draw_turn_performance(chart : Dictionary) -> void:
	%TurnPerformanceGraph.clear_curves()
	%TurnPerformanceGraph.clear_labels()
	
	var definitions : Array = []
	var families : Array[Dictionary] = []
	
	#the turn radius lines go down first, so the families the chart is read for sit over them
	for family : Dictionary in chart.radii:
		var points : PackedVector2Array = family.points
		definitions.append({
			"color": Color(CURVE_COLORS[3], 0.7), "name": "radius %d m" % roundi(family.radius),
			"label": "%d m" % roundi(family.radius), "label_position": label_position(points, radius_label_fraction),
			"points": points,
		})
	if not chart.radii.is_empty():
		families.append({"text": "TURN RADIUS (M)", "points": chart.radii[chart.radii.size() / 2].points, "start": 0.55, "end": 0.85})
	
	#the lift limit, which is where the wing stalls. it runs up to the last load factor line, which is what closes the top of the
	#chart and stands for the g limit
	if chart.limit.size() > 1:
		definitions.append({"color": CURVE_COLORS[0], "name": "lift limit", "points": chart.limit, "width": 2.0})
	
	#the 1 g line, which is where every turn radius line starts at its lower end: the turn rate of a turn pulling 1 g sideways. it
	#carries the load factor colour because that is what it is, and its number is the bottom of the same staircase of numbers
	if chart.one_g.size() > 1:
		definitions.append({"color": CURVE_COLORS[2], "name": "1 g pull", "points": chart.one_g})
		%TurnPerformanceGraph.add_label("1 g", chart.one_g[0], Vector2(load_label_span, 0.0), HORIZONTAL_ALIGNMENT_RIGHT)
	
	#the constant load factor lines, which are turns the aircraft can pull while it still has the lift for them. each one is
	#named just to the left of where it starts on the lift limit, so the numbers step up the side of the chart. they are written
	#before anything else, because that is the room nothing else is allowed to take
	for family : Dictionary in chart.loads:
		if family.points.is_empty(): continue
		
		definitions.append({
			"color": CURVE_COLORS[2], "name": "load factor %s" % format_load(family.load), "points": family.points,
		})
		var start : Vector2 = family.points[0]
		%TurnPerformanceGraph.add_label(format_load(family.load), start, Vector2(load_label_span, 0.0), HORIZONTAL_ALIGNMENT_RIGHT)
	#the load factor name runs up the chart beside the numbers, above where the numbers start and clear of them
	if not chart.loads.is_empty() and chart.limit.size() > 2:
		families.append({"text": "LOAD FACTOR (G)", "points": chart.limit, "start": 0.28, "end": 0.42, "clear": load_name_clearance})
	
	#the constant excess power contours, which are the turns it can hold rather than fall out of. a contour that leaves the
	#envelope and comes back is drawn as more than one line, and only the longest of its stretches carries the name
	for family : Dictionary in chart.powers:
		var longest : int = longest_run(family.runs)
		for index : int in family.runs.size():
			var run : PackedVector2Array = family.runs[index]
			if run.size() < 2: continue
			
			var labelled : bool = index == longest
			var definition := {"color": CURVE_COLORS[1], "name": "excess power %d m/s" % roundi(family.level), "points": run}
			if labelled:
				definition["label"] = "%d m/s" % roundi(family.level)
				definition["label_position"] = label_position(run, power_label_fraction)
			definitions.append(definition)
	
	#the name of that family goes along the longest stretch of the contour through the middle of the chart
	if not chart.powers.is_empty():
		var middle : Array = chart.powers[chart.powers.size() / 2].runs
		families.append({"text": "EXCESS POWER (M/S)", "points": middle[longest_run(middle)], "start": 0.45, "end": 0.7})
	
	assign_curves(%TurnPerformanceGraph, definitions)
	add_family_labels(families)
	%TurnPerformanceGraph.title = "Turn performance at %d m, %d g limit" % [roundi(altitude), roundi(load_limit)]

#the name of each family of lines, written along a run of it and turned to follow that run, so the numbers on the lines
#read as one family without a legend. each family is named where its lines stand furthest apart: the radius lines fan out to
#the right, the load factor name runs up the side the numbers step up, and the contours run through the middle
func add_family_labels(families : Array[Dictionary]) -> void:
	for family : Dictionary in families:
		var curve : PackedVector2Array = family.points
		if curve.size() < 3: continue
		
		var from := point_across(curve, family.start)
		var to := point_across(curve, family.end)
		%TurnPerformanceGraph.add_label(family.text, from, to - from, HORIZONTAL_ALIGNMENT_CENTER, family.get("clear", 0.0))

#a load factor written the way it is set: whole g's without a decimal, the rest with one
func format_load(load : float) -> String:
	if is_equal_approx(load, roundf(load)): return "%d g" % roundi(load)
	return "%.1f g" % load

#which of a contour's stretches is the longest, which is the one that carries the family's name
func longest_run(runs : Array) -> int:
	var longest := 0
	for index : int in runs.size():
		if runs[index].size() > runs[longest].size(): longest = index
	
	return longest

#the point this share of the way across a curve's run on the x axis, which is where a family is named. it is found by value
#rather than by sample, so the name stays where it is however finely the curve is sampled
func point_across(curve : PackedVector2Array, fraction : float) -> Vector2:
	var x : float = lerpf(curve[0].x, curve[curve.size() - 1].x, fraction)
	for index : int in curve.size() - 1:
		var span := curve[index + 1].x - curve[index].x
		if is_zero_approx(span): continue
		
		var along := (x - curve[index].x) / span
		if along < 0.0 or along > 1.0: continue
		
		return curve[index].lerp(curve[index + 1], along)
	
	return curve[curve.size() - 1]

#where a turn radius line carries its name: at its end, where the lines stand furthest apart
var radius_label_fraction := 1.0
#where an excess power contour carries its name: up along it where the contours stand apart, rather than at its foot, where
#the whole family converges with the radius lines and their names
var power_label_fraction := 0.3
#the run a load factor number is written along: a short one, which only says that the number reads straight across the chart
#rather than turned along the line it belongs to
var load_label_span := 0.03
#how far left of the lift limit the load factor name stands, which is clear of the numbers written against that limit
var load_name_clearance := 46.0

#the x a curve is asked to carry its name at, taken at this share of its run
func label_position(curve : PackedVector2Array, fraction : float) -> float:
	if curve.size() < 2: return 0.0
	return lerpf(curve[0].x, curve[curve.size() - 1].x, fraction)

#each curve is a color, a legend name and its points, and optionally the parameter its samples were taken at, a normalized y
#flag, the width it is drawn at, or the word written along it and the x value it is written at
func assign_curves(graph : AeroGraph, definitions : Array) -> void:
	graph.clear_curves()
	for definition : Dictionary in definitions:
		var parameters : PackedFloat32Array = definition.get("parameters", PackedFloat32Array())
		var curve := graph.add_curve(definition.points, definition.color, definition.name, parameters)
		curve.normalize_y = definition.get("normalized_y", false)
		curve.width = definition.get("width", 0.0)
		if definition.has("label"):
			graph.add_curve_label(curve, definition.label, definition.label_position)


#signal handlers

func _on_recalculate_button_pressed() -> void:
	queue_recalculate()

func _on_testing_speed_value_changed(value : float) -> void:
	test_speed = value

func _on_sweep_datapoints_value_changed(value : float) -> void:
	sweep_datapoints = int(value)

func _on_altitude_value_changed(value : float) -> void:
	altitude = value

func _on_load_limit_value_changed(value : float) -> void:
	load_limit = value

func _on_turn_datapoints_value_changed(value : float) -> void:
	turn_datapoints = int(value)












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
const TURN_ALPHA_SAMPLES := 25
const TURN_MACH_START := 0.2
const TURN_MACH_LIMIT := 1.6
#the load factor a turn pulling 1 g sideways comes to, which is the flattest turn the chart reads a radius off and the line every
#turn radius line starts on
const ONE_G_TURN_LOAD := sqrt(2.0)
#the control axis the thrusters read their throttle from, which the turn sweep holds wide open
const THROTTLE_AXIS := "throttle"
#the turn radii a chart draws lines for, graduated every step of this many metres from the tightest circle worth drawing out
#to the widest, rather than whatever the sweep works out to, so the family reads the same however finely it is flown
const TURN_RADIUS_STEP := 300.0
const TURN_RADIUS_TIGHTEST := 300.0
const TURN_RADIUS_WIDEST := 10000.0
#how close together two of those lines may come, in degrees a second where they are nearest the widest end of the chart, before
#the one after is left out. a graduation of 200 metres is worth drawing while the lines still read apart, and past that the
#family thins out instead of piling up in the corner
const TURN_RADIUS_MINIMUM_GAP := 0.8
#how far a column flown between two others may come from where those two would have put it before the sweep is split again along
#it, in degrees a second of turn rate and in metres a second of excess power. past these the column is one the chart would have
#drawn a kink without, so it is kept
const TURN_BEND_RATE := 0.06
const TURN_BEND_POWER := 0.6
#how many times the sweep is split again: enough for the parts of the chart that bend hardest to fill in without every part of
#the chart paying for it
const TURN_SPLITS := 2


#the static analysis, as every curve its graphs draw and the numbers the metrics are read from
func static_analysis() -> Dictionary:
	measure_reference_dimensions()
	
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

#rolling an aircraft that holds a fixed flight path turns the airflow towards its wing tips, so the wings stop seeing the
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
	if not aerobody: return 0.0
	
	var dynamic_pressure : float = 0.5 * air_density() * test_speed * test_speed
	if dynamic_pressure <= 0.0 or reference_area <= 0.0: return 0.0
	
	var required_lift : float = aerobody.mass * GRAVITY / (dynamic_pressure * reference_area)
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
		"dynamic_pressure": 0.5 * air_density() * test_speed * test_speed,
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
		var aircraft_weight : float = aerobody.mass * GRAVITY
		metrics.glide_speed = sqrt(2.0 * aircraft_weight / (air_density() * reference_area * lift_at_highest_ratio))
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
	var chart := {"limit": PackedVector2Array(), "one_g": PackedVector2Array(), "loads": [], "powers": [], "radii": []}
	if not aerobody: return chart
	
	var weight : float = aerobody.mass * GRAVITY
	var density := air_density()
	var pressure := air_pressure()
	var sound_speed := speed_of_sound()
	if weight <= 0.0 or sound_speed <= 0.0: return chart
	
	#the chart is about the thrust the aircraft has to hold a turn with, so the throttle is wound open for the columns and let
	#back down after them. the airframe is silenced for that, because a throttle going up and down inside a sweep is the
	#sweep's own doing and taking it for a change to the flight model would have it fly itself again
	var controls := control_component()
	var silenced : Array[AeroInfluencer3D] = []
	var held_throttles : Dictionary = {}
	var held_throttle := 0.0
	if controls:
		for node : Node in aerobody.find_children("*", "AeroInfluencer3D", true, false):
			var influencer := node as AeroInfluencer3D
			if influencer == null or influencer.suppress_flight_model_changed: continue
			influencer.suppress_flight_model_changed = true
			silenced.append(influencer)
		
		#the thrusters are wound open on both of the wires thrust arrives by. a running game reads the control command below,
		#while the editor never updates an influencer's control transform at all, so a sweep flown there has to set the throttle
		#on the thruster itself. each thruster's own throttle is kept, to be put back once the sweep is done
		for node : Node in aerobody.find_children("*", "AeroThruster3D", true, false):
			var thruster := node as AeroThruster3D
			if thruster == null: continue
			
			held_throttles[thruster] = thruster.throttle
			var throttle_config : AeroInfluencerControlConfig = thruster.throttle_control_config
			thruster.throttle = throttle_config.min_value if throttle_config else Vector3(0, 0, -1)
		
		held_throttle = controls.get_control_command(THROTTLE_AXIS)
		controls.set_control_command(THROTTLE_AXIS, 1.0)
	
	var columns := turn_columns(density, pressure, sound_speed, weight)
	
	if controls:
		controls.set_control_command(THROTTLE_AXIS, held_throttle)
		for thruster : AeroThruster3D in held_throttles: thruster.throttle = held_throttles[thruster]
	for influencer : AeroInfluencer3D in silenced: influencer.suppress_flight_model_changed = false
	
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
	
	return chart

#the Mach steps the chart is flown at: the number asked for, then split again wherever the column in the middle of two steps
#comes out somewhere those two would not have put it. the sweep ends up dense where the chart bends and coarse where it runs
#straight, rather than paying for the same spacing everywhere
func turn_columns(density : float, pressure : float, sound_speed : float, weight : float) -> Array[Dictionary]:
	var step : float = (TURN_MACH_LIMIT - TURN_MACH_START) / float(turn_datapoints - 1)
	var columns : Array[Dictionary] = []
	for index : int in turn_datapoints:
		columns.append(turn_performance_column(TURN_MACH_START + step * index, density, pressure, sound_speed, weight))
	
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
func turn_performance_column(mach : float, density : float, pressure : float, sound_speed : float, weight : float) -> Dictionary:
	var speed := mach * sound_speed
	var loads := PackedFloat64Array()
	var turn_rates := PackedFloat64Array()
	var powers := PackedFloat64Array()
	
	for sample : int in TURN_ALPHA_SAMPLES:
		var alpha : float = remap(sample, 0, TURN_ALPHA_SAMPLES - 1, 0.0, TURN_ALPHA_LIMIT)
		var attitude := Transform3D(Basis.from_euler(Vector3(deg_to_rad(alpha), 0, 0)), Vector3.ZERO)
		var force : Vector3 = force_and_torque_at(attitude, speed, density, pressure)[0]
		var load : float = force.dot(calculate_lift_direction(attitude.basis)) / weight
		
		#a turn needs the wing to carry more than the aircraft weighs, so a sample under that is no turn at all, and a sample the
		#model could not work out is left out rather than carried into the chart
		if load < 1.0 or not is_finite(load): continue
		
		loads.append(load)
		turn_rates.append(turn_rate(load, speed))
		powers.append(speed * -force.dot(AIR_DIRECTION) / weight)
	
	#the column is stopped at the angle of attack that holds the most load factor. past the stall the wing holds less and less,
	#so a contour read off that falling side sits at a lower load factor than one read off the rising side, which is how the
	#contours for two different excess powers came to cross each other
	var peak := 0
	for index : int in loads.size():
		if loads[index] > loads[peak]: peak = index
	if not loads.is_empty():
		loads.resize(peak + 1)
		turn_rates.resize(peak + 1)
		powers.resize(peak + 1)
	
	var held_load : float = loads[loads.size() - 1] if not loads.is_empty() else 0.0
	
	return {
		"mach": mach,
		"speed": speed,
		"loads": loads,
		"turn_rates": turn_rates,
		"powers": powers,
		#the most the wing can hold, and the most the airframe is cleared for, which is what every line is clipped to
		"held_load": held_load,
		"limit_load": minf(held_load, load_limit),
	}

#the component the aircraft is flown through, which is where the thrusters read their throttle from
func control_component() -> AeroControlComponent:
	for child : Node in aerobody.get_children():
		if child is AeroControlComponent: return child
	
	return null

#the turn rate a level turn at this load factor comes to at this speed, in degrees per second
func turn_rate(load : float, speed : float) -> float:
	if load <= 1.0 or speed <= 0.0: return 0.0
	return rad_to_deg(GRAVITY * sqrt(load * load - 1.0) / speed)

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
	var span : float = column.held_load - previous.held_load
	var along : float = 0.0 if is_zero_approx(span) else clampf((load - previous.held_load) / span, 0.0, 1.0)
	var speed : float = lerpf(previous.speed, column.speed, along)
	
	return Vector2(lerpf(previous.mach, column.mach, along), turn_rate(load, speed))

#where a line holding this load factor meets the envelope between two columns, as the point that line passes through there.
#the load factor is what the line itself is at either side of the crossing
func meets_limit(previous : Dictionary, column : Dictionary, previous_load : float, load : float) -> Vector2:
	var along := limit_crossing_along(previous, column, previous_load, load)
	var speed : float = lerpf(previous.speed, column.speed, along)
	
	return Vector2(lerpf(previous.mach, column.mach, along), turn_rate(lerpf(previous_load, load, along), speed))

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
			#a stretch that starts after a gap opens on the crossing rather than at the column itself
			if not was_held and not previous.is_empty() and not is_nan(previous_load):
				run.append(meets_limit(previous, column, previous_load, load))
			run.append(Vector2(column.mach, turn_rate(load, column.speed)))
		elif was_held:
			if not is_nan(load): run.append(meets_limit(previous, column, previous_load, load))
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
	var before : float = previous_load - previous.limit_load
	var after : float = load - column.limit_load
	
	return 0.0 if is_zero_approx(before - after) else clampf(before / (before - after), 0.0, 1.0)

#the excess power contours to draw. an aircraft with power to spare is drawn from nothing up to the most it has, in equal
#steps. an aircraft with none is drawn by the energy it loses instead, which runs from a few metres a second in a gentle turn to
#thousands at the stall, so those levels step through 1, 2 and 5 of each decade and a handful of them cover the spread
func power_contours(columns : Array[Dictionary]) -> PackedFloat64Array:
	var highest := -INF
	var lowest := INF
	for column : Dictionary in columns:
		for power : float in column.powers:
			highest = maxf(highest, power)
			lowest = minf(lowest, power)
	
	var levels := PackedFloat64Array()
	if is_inf(highest): return levels
	
	if highest >= 0.0:
		var step := nice_step(highest / 4.0)
		if not is_finite(step) or step <= 0.0: return levels
		
		var level := 0.0
		while level <= highest and level >= lowest:
			levels.append(level)
			level += step
		return levels
	
	var decade := pow(10.0, floorf(log(-highest) / log(10.0)))
	if not is_finite(decade) or decade <= 0.0: return levels
	
	while levels.size() < 6 and -decade >= lowest:
		for tidiness : float in [1.0, 2.0, 5.0]:
			var level := -decade * tidiness
			if levels.size() < 6 and level <= highest and level >= lowest: levels.append(level)
		decade *= 10.0
	
	return levels

#a step rounded up to 1, 2 or 5 times a power of ten, so the contours land on numbers worth reading
func nice_step(raw_step : float) -> float:
	if raw_step <= 0.0: return 1.0
	
	var magnitude := pow(10.0, floorf(log(raw_step) / log(10.0)))
	for tidiness : float in [1.0, 2.0, 5.0, 10.0]:
		if raw_step / magnitude <= tidiness: return magnitude * tidiness
	
	return magnitude * 10.0


#the air

#the air every sweep is worked out in: the declared altitude, and nothing about where the aircraft sits in the scene
func air_density() -> float:
	var density : float = AeroUnits.get_density_at_altitude(altitude)
	return density if density > 0.0 else SEA_LEVEL_DENSITY

func air_pressure() -> float:
	var pressure : float = AeroUnits.get_pressure_at_altitude(altitude)
	return pressure if pressure > 0.0 else SEA_LEVEL_PRESSURE

func speed_of_sound() -> float:
	return AeroUnits.get_speed_of_sound_at_pressure_and_density(air_pressure(), air_density())

#the force and torque on the aircraft flying an attitude at a speed through that air. the arguments are the whole simulation
#state: not one thing is read from the body's own transform or position
func force_and_torque_at(attitude : Transform3D, speed : float, density : float, pressure : float) -> PackedVector3Array:
	return aerobody.calculate_forces_manual(attitude, Vector3(0, 0, -speed), Vector3.ZERO, altitude, density, pressure)

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
	if not aerobody: return {}
	if test_speed <= 0.0: return {}
	if reference_area <= 0.0 or reference_span <= 0.0 or reference_chord <= 0.0: return {}
	
	var density := air_density()
	var force_and_torque := force_and_torque_at(transform, test_speed, density, air_pressure())
	
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
	var to_body : Transform3D = aerobody.global_transform.affine_inverse()
	var total_area := 0.0
	var chord_area := 0.0
	var lowest_tip := INF
	var highest_tip := -INF
	
	for node : Node in aerobody.find_children("*", "AeroInfluencer3D", true, false):
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
