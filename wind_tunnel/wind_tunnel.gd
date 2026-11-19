@tool
extends Control
##The wind tunnel dock: the panels, the settings they are flown at, and the routing that decides which aircraft is being
##looked at. the sweeps live in aircraft_sweeps.gd, and are flown on a worker thread against a copy of the aircraft so the
##editor is left free while they run.

#the color each curve is drawn in, in the order the sweeps reach for them
const CURVE_COLORS := [
	Color(1.0, 0.35, 0.35), Color(0.4, 1.0, 0.45), Color(0.45, 0.7, 1.0),
	Color(1.0, 0.83, 0.4), Color(0.8, 0.6, 1.0),
]
#what a field says when there is nothing to report
const NO_DATA := "n/a"
#the sweeps themselves, which the dock runs on a worker thread
const AircraftSweeps = preload("res://addons/godot_aerodynamic_physics/wind_tunnel/aircraft_sweeps.gd")
#the air the sweeps fall back to while the atmosphere tables have nothing to say
const SEA_LEVEL_DENSITY := 1.225
const SEA_LEVEL_PRESSURE := 101325.0

@export_group("Sweep")
##Airspeed every point of a sweep is flown at.
@export var test_speed : float = 250:
	set(value):
		test_speed = value
		static_stale = true
		queue_recalculate()

##Points simulated in each sweep. Drop it for a quick look at the shape of a curve, raise it to smooth the curves out.
@export var sweep_datapoints : int = 96:
	set(value):
		sweep_datapoints = maxi(value, 2)
		static_stale = true
		queue_recalculate()

@export_group("Reference dimensions")
##Reference dimensions for the coefficients. Left at 0 they are estimated from the aircraft the dock has open, and they
##are estimated again when another aircraft is opened. A value set by hand overrides the estimate until then.
@export var reference_area : float = 0.0
@export var reference_span : float = 0.0
@export var reference_chord : float = 0.0

@export_group("Turn performance")
##Altitude the dock flies at, in meters above sea level. Every graph uses the air this declares, so nothing depends on where
##the aircraft sits in the scene.
@export var altitude : float = 5000.0:
	set(value):
		altitude = value
		static_stale = true
		turn_performance_stale = true
		queue_recalculate()

##The load factor the airframe is cleared for, which caps the turn rate the wing could otherwise reach. Naming an aircraft
##takes it from that aircraft's flight assist g limiter, to the next whole g above it.
@export var load_limit : float = 9.0:
	set(value):
		load_limit = value
		if is_node_ready(): %LoadLimit.value = value
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
			pull_load_limit()
			queue_flight_model_changed()
			aerobody.flight_model_changed.connect(queue_flight_model_changed)

#the load the airframe is cleared for is the aircraft's own: the next whole g above what its flight assist limits it to
func pull_load_limit() -> void:
	for child : Node in aerobody.get_children():
		if child is AeroControlComponent and child.flight_assist:
			load_limit = floorf(child.flight_assist.g_limit) + 1.0
			return


#virtuals

func _ready() -> void:
	resized.connect(fit_graph_columns)
	fit_graph_columns()
	
	#an aircraft named before the dock was built has already set the load limit, which goes on display now the field is there
	%LoadLimit.value = load_limit
	
	#the sweeps' copy of the aircraft lives in a viewport of its own: it is in a tree, so it initializes exactly as it does in a
	#scene, but it never draws and its world is its own
	simulation_view = SubViewport.new()
	simulation_view.own_world_3d = true
	simulation_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(simulation_view)
	
	#a tab that was not being looked at is flown when it is opened, and a dock that was closed catches up when it reopens
	%Tabs.tab_changed.connect(queue_recalculate.unbind(1))
	visibility_changed.connect(queue_recalculate)
	
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

#the tabs a sweep is flown for: the static analysis, and the turn performance
const STATIC_TAB := 0
const PERFORMANCE_TAB := 2
#set while a recalculation is waiting for the end of the frame, which is what folds a burst of changes into one sweep
var recalculation_queued := false
#a sweep that lands sooner than this never puts the sheet up, so quick recalculations do not flash it
const BUSY_SHEET_DELAY := 300
#when the sweep in flight started, in milliseconds
var busy_since_msec := 0

#set when something the static analysis is flown from changed: the aircraft, the air, the speed or the sample count
var static_stale := true

#set when something the turn performance is flown from changed: the aircraft, its configuration or the air the dock is
#declared to fly in. the settings that only move the other graphs leave it alone, so a change of test speed or datapoint
#count does not fly the turn sweep again
var turn_performance_stale := true

#asks for a recalculation at the end of the frame, so a burst of changes within one frame starts one sweep. the sweeps fly
#on a worker, so the dock keeps up with the aircraft while it is being edited instead of waiting for the edits to settle
func queue_recalculate() -> void:
	#the exported setters also run while the dock is still being built, where there is nothing to report on yet
	if not is_inside_tree(): return
	if recalculation_queued: return
	
	recalculation_queued = true
	recalculate.call_deferred()

func _process(_delta : float) -> void:
	#a finished sweep is taken the moment it lands
	if worker_task != -1:
		if WorkerThreadPool.is_task_completed(worker_task):
			WorkerThreadPool.wait_for_task_completion(worker_task)
			worker_task = -1
			finish_sweeps()
			set_busy(false)
		else:
			#a sweep that is still flying after a moment is worth showing: the sheet comes up late so a quick one never flashes it
			if not busy_sheet.visible:
				if Time.get_ticks_msec() - busy_since_msec < BUSY_SHEET_DELAY: return
				set_busy(true)

#the aircraft changing shape or moving an influencer changes what it can turn at, so the performance sweep is queued too
func queue_flight_model_changed() -> void:
	static_stale = true
	turn_performance_stale = true
	queue_recalculate()

#the sweep in flight, and the copy of the aircraft the worker flies it against. the dock touches none of these until the
#task is done, and the thread touches nothing else
var worker_task := -1
var worker_copy : AeroBody3D
var worker_sweeps : AircraftSweeps
var worker_results := {}
var worker_runs_static := false
var worker_runs_turn := false
var worker_dirty := false

#the sheet drawn over the dock while the sweeps are flying, so it is clear the numbers are being worked out and that the
#settings under it are not to be touched until they land. the root stacks it over the panel, so it fills the dock wherever
#the editor moves the dock to
@onready var busy_sheet : ColorRect = %BusySheet
#where the copy of the aircraft the worker flies is put
var simulation_view : SubViewport

#raises or drops the sheet, which also swallows the clicks that would change the settings under it
func set_busy(busy : bool) -> void:
	busy_sheet.visible = busy

func is_busy() -> bool:
	return busy_sheet.visible

#one pass over the aircraft: every graph refilled from the sweeps, then the metrics
func recalculate() -> void:
	recalculation_queued = false
	
	#with no aircraft named the dock keeps what it is showing rather than blanking it, which is what leaves the last
	#aircraft's results there to be read while another scene is open
	if not aerobody or not is_visible_in_tree(): return
	
	%AircraftName.text = aerobody.name
	
	#only the tab being looked at is flown: the other one keeps what it shows and catches up when it is opened, which is
	#what keeps a change to the aircraft from paying for a sweep nobody is reading
	var sweep_static : bool = %Tabs.current_tab == STATIC_TAB and static_stale
	var sweep_turn : bool = %Tabs.current_tab == PERFORMANCE_TAB and turn_performance_stale
	if not sweep_static and not sweep_turn: return
	
	#a sweep already in flight is left to finish rather than interrupted, and flown again as soon as it lands
	if worker_task != -1:
		worker_dirty = true
		return
	
	start_sweeps(sweep_static, sweep_turn)

#deep-copies the aircraft for the worker to fly, so the sweeps never touch the nodes being edited. the copy goes into a
#viewport of its own, so it enters a tree and initializes like any aircraft, and is then taken out of the frame's way: it does
#not process, show or collide with anything
func start_sweeps(sweep_static : bool, sweep_turn : bool) -> void:
	#the copy has to keep its script instances: a deep duplicate would instantiate them and the copied nodes would come out
	#without their behavior. the resources they share are only read by the sweeps, so sharing them is safe
	worker_copy = aerobody.duplicate()
	worker_copy.process_mode = Node.PROCESS_MODE_DISABLED
	worker_copy.visible = false
	worker_copy.collision_layer = 0
	worker_copy.collision_mask = 0
	simulation_view.add_child(worker_copy)
	
	#the nodes the sweeps reach into are gathered here, on the main thread: a thread may not search the scene itself
	var influencers : Array[AeroInfluencer3D] = []
	for node : Node in worker_copy.find_children("*", "AeroInfluencer3D", true, false):
		influencers.append(node as AeroInfluencer3D)
	var thrusters : Array[AeroThruster3D] = []
	for node : Node in worker_copy.find_children("*", "AeroThruster3D", true, false):
		thrusters.append(node as AeroThruster3D)
	
	worker_sweeps = AircraftSweeps.new()
	worker_sweeps.body = worker_copy
	worker_sweeps.influencers = influencers
	worker_sweeps.thrusters = thrusters
	for child : Node in worker_copy.get_children():
		if child is AeroControlComponent: worker_sweeps.control = child
	worker_sweeps.test_speed = test_speed
	worker_sweeps.sweep_datapoints = sweep_datapoints
	worker_sweeps.reference_area = reference_area
	worker_sweeps.reference_span = reference_span
	worker_sweeps.reference_chord = reference_chord
	worker_sweeps.altitude = altitude
	worker_sweeps.density = air_density()
	worker_sweeps.pressure = air_pressure()
	worker_sweeps.sound_speed = speed_of_sound()
	worker_sweeps.load_limit = load_limit
	worker_sweeps.turn_datapoints = turn_datapoints
	
	#the sweeps are marked fresh as they are handed over, so an edit arriving mid-flight marks them stale again
	if sweep_static: static_stale = false
	if sweep_turn: turn_performance_stale = false
	worker_runs_static = sweep_static
	worker_runs_turn = sweep_turn
	worker_results = {}
	worker_task = WorkerThreadPool.add_task(run_sweeps, false, "wind tunnel sweeps")
	busy_since_msec = Time.get_ticks_msec()

#the worker thread: flies the sweeps against the copy and leaves the results where the dock picks them up
func run_sweeps() -> void:
	var results := {}
	if worker_runs_static: results["static"] = worker_sweeps.static_analysis()
	if worker_runs_turn: results["turn"] = worker_sweeps.turn_performance()
	worker_results = results

#takes the results of a finished sweep and puts the copy away, on the main thread
func finish_sweeps() -> void:
	var results := worker_results
	worker_results = {}
	
	#the copy measured the dimensions if they were not set by hand, and the panel reports the ones it came to
	reference_area = worker_sweeps.reference_area
	reference_span = worker_sweeps.reference_span
	reference_chord = worker_sweeps.reference_chord
	
	simulation_view.remove_child(worker_copy)
	worker_copy.queue_free()
	worker_copy = null
	worker_sweeps = null
	
	if results.has("static"): draw_static_analysis(results["static"])
	if results.has("turn"): draw_turn_performance(results["turn"])
	
	if worker_dirty:
		worker_dirty = false
		queue_recalculate()

#the air the sweeps are flown in: the declared altitude, and nothing about where the aircraft sits in the scene
func air_density() -> float:
	var density : float = AeroUnits.get_density_at_altitude(altitude)
	return density if density > 0.0 else SEA_LEVEL_DENSITY

func air_pressure() -> float:
	var pressure : float = AeroUnits.get_pressure_at_altitude(altitude)
	return pressure if pressure > 0.0 else SEA_LEVEL_PRESSURE

func speed_of_sound() -> float:
	return AeroUnits.get_speed_of_sound_at_pressure_and_density(air_pressure(), air_density())

#the worker is holding the copy while the dock is going away, so it is waited for rather than left reading freed nodes
func _exit_tree() -> void:
	if worker_task == -1: return
	WorkerThreadPool.wait_for_task_completion(worker_task)
	worker_task = -1
	if worker_copy:
		simulation_view.remove_child(worker_copy)
		worker_copy.queue_free()
		worker_copy = null
	worker_sweeps = null


#drawing

#the static analysis: the coefficient curves, the moment curves, the drag polar and the numbers under them
func draw_static_analysis(results : Dictionary) -> void:
	var alpha : Dictionary = results.alpha
	var beta : Dictionary = results.beta
	var inertia := get_body_inertia()
	
	assign_curves(%LiftDragGraph, [
		{"color": CURVE_COLORS[0], "name": "CL", "points": alpha.lift},
		{"color": CURVE_COLORS[1], "name": "CD", "points": alpha.drag},
		{"color": CURVE_COLORS[2], "name": "L/D", "points": alpha.ratio, "normalized_y": true},
	])
	
	assign_curves(%PitchMomentsGraph, [
		{"color": CURVE_COLORS[0], "name": "Mx (pitch)", "points": angular_acceleration(alpha.pitch, inertia.x)},
		{"color": CURVE_COLORS[1], "name": "My (yaw)", "points": angular_acceleration(alpha.yaw, inertia.y)},
		{"color": CURVE_COLORS[2], "name": "Mz (roll)", "points": angular_acceleration(alpha.roll, inertia.z)},
	])
	
	assign_curves(%SideslipMomentsGraph, [
		{"color": CURVE_COLORS[0], "name": "Mx (pitch)", "points": angular_acceleration(beta.pitch, inertia.x)},
		{"color": CURVE_COLORS[1], "name": "My (yaw)", "points": angular_acceleration(beta.yaw, inertia.y)},
		{"color": CURVE_COLORS[2], "name": "Mz (roll)", "points": angular_acceleration(beta.roll, inertia.z)},
	])
	
	assign_curves(%RollMomentsGraph, [
		{"color": CURVE_COLORS[2], "name": "Mz (roll)", "points": angular_acceleration(results.roll.moment, inertia.z)},
	])
	
	assign_curves(%PolarGraph, [
		{"color": CURVE_COLORS[2], "name": "CL vs CD", "points": alpha.polar, "parameters": alpha.polar_alphas},
	])
	
	update_metrics(results.metrics)

#the inertia each axis turns against, which the body works out for itself: the engine's own numbers once it has stepped
#physics, and the same sum over its collision shapes when it has not, which is the case in the editor
func get_body_inertia() -> Vector3:
	return aerobody.get_moment_of_inertia() if is_instance_valid(aerobody) else Vector3.ONE

#the moments the sweeps report turned into the angular acceleration each one would produce, so the same reading means the
#same thing on every aircraft instead of running to millions of newton meters on the heavy ones
func angular_acceleration(moments : PackedVector2Array, inertia : float) -> PackedVector2Array:
	var accelerated := PackedVector2Array()
	for moment : Vector2 in moments:
		accelerated.append(Vector2(moment.x, moment.y / inertia))
	return accelerated

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
	#carries the load factor color because that is what it is, and its number is the bottom of the same staircase of numbers
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
			
			var labeled : bool = index == longest
			var definition := {"color": CURVE_COLORS[1], "name": "excess power %d m/s" % roundi(family.level), "points": run}
			if labeled:
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
