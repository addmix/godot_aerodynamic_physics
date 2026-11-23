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
#the measurement the control response tab flies, a step of one axis recorded frame by frame
const ControlResponse = preload("res://addons/godot_aerodynamic_physics/wind_tunnel/control_response.gd")
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
		if is_node_ready():
			%StaticAltitude.value = value
			%TurnAltitude.value = value
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

@export_group("Altitude sweep")
##Altitudes the numbers that change with height are worked out at, between sea level and 15 km.
@export var altitude_steps : int = 13:
	set(value):
		altitude_steps = maxi(value, 2)
		altitude_stale = true
		queue_recalculate()

##Speeds each of those altitudes is swept through, which is what smooths the curves against height.
@export var altitude_datapoints : int = 12:
	set(value):
		altitude_datapoints = maxi(value, 6)
		altitude_stale = true
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
	
	#the settings the dock was handed before it was built go on display now the fields are there
	%TestingSpeed.value = test_speed
	%StaticAltitude.value = altitude
	%SweepDatapoints.value = sweep_datapoints
	%TurnAltitude.value = altitude
	%LoadLimit.value = load_limit
	%TurnPoints.value = turn_datapoints
	%AltitudeSteps.value = altitude_steps
	%AltitudeSamples.value = altitude_datapoints
	
	#the sweeps' copy of the aircraft lives in a viewport of its own: it is in a tree, so it initializes exactly as it does in a
	#scene, but it never draws and its world is its own
	simulation_view = SubViewport.new()
	simulation_view.own_world_3d = true
	simulation_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(simulation_view)
	
	#a tab that was not being looked at is flown when it is opened, and a dock that was closed catches up when it reopens
	%Tabs.tab_changed.connect(queue_recalculate.unbind(1))
	%Tabs.tab_changed.connect(_on_tab_changed)
	visibility_changed.connect(queue_recalculate)
	
	#anything the tests are flown from asks for them again when it changes, once the change has settled
	%ResponseAxis.item_selected.connect(queue_response_tests.unbind(1))
	%ResponseSpeed.value_changed.connect(queue_response_tests.unbind(1))
	%ResponsePressures.value_changed.connect(queue_response_tests.unbind(1))
	%ResponseSkipLowest.value_changed.connect(queue_response_tests.unbind(1))
	
	if not Engine.is_editor_hint(): return
	
	#the dock can be built, or reopened, after a scene is already open, so scene_changed never fires for it
	visibility_changed.connect(func() -> void: _on_editor_scene_changed(EditorInterface.get_edited_scene_root()))
	EditorInterface.get_selection().selection_changed.connect(_on_editor_selection_changed)
	#an undo or a redo can put a value back without running the setter that reports it, so the aircraft is read back after one
	EditorInterface.get_editor_undo_redo().version_changed.connect(_on_undo_redo)
	
	#the editor restores the scene it had open a few frames after the dock is built, so wait for it instead of missing it
	var frames_left := 120
	while frames_left > 0 and EditorInterface.get_edited_scene_root() == null:
		await get_tree().process_frame
		frames_left -= 1
	
	_on_editor_scene_changed(EditorInterface.get_edited_scene_root())

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
	
	#the response tab keeps itself current: a recalculation asked for by an edit is dropped while that edit's tests are still
	#settling, so one is asked for again once they have
	if response_stale and worker_task == -1 and aerobody and is_visible_in_tree() and %Tabs.current_tab == RESPONSE_TAB:
		if Time.get_ticks_msec() - response_asked_msec >= RESPONSE_SETTLE_MSEC: queue_recalculate()

#whether a part is carried by something that turns, which places it itself, so the copy leaves it where it was put
func is_turned_part(influencer : AeroInfluencer3D, copy : AeroBody3D) -> bool:
	var node : Node = influencer.get_parent()
	while node and node != copy:
		if node is AeroMover3D: return true
		node = node.get_parent()
	
	return false

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
#the numbers under the turn chart stand four to a row where there is this much width, and pair up below it. the switch has
#to sit clear of the width four of them need, or the dock could never be dragged narrow enough to ask for two
var turn_metrics_row_width := 640.0
#the share of the dock's height the turn chart keeps for itself, with the grid under it taking the rest
var turn_chart_height_share := 0.6
#the height the graphs in the grids take, as a share of the dock's own and within bounds, so they fit the screen the editor is on
#rather than being one size everywhere, and stay readable on a short one
var graph_height_share := 0.30
var graph_height_floor := 240.0
var graph_height_ceiling := 520.0
#the error chart and the breakdowns in the row are the densest charts in the tab, so they take a share of the dock of their own
#rather than a grid cell's
var response_chart_height_share := 0.45
var response_chart_height_floor := 340.0
var response_chart_height_ceiling := 760.0
#how wide a graph of the pressure row is drawn, in line heights of the dock's own text: a fixed width rather than a share of the
#dock, so a wider dock shows more of them side by side instead of the same number at a higher resolution
var response_chart_width_lines := 15
#how wide a graph has to be before the numbers along its axes stop reading, in line heights of the dock's own text, so it
#follows the editor's font size instead of growing with the height of the screen the dock happens to be on
var graph_minimum_width_lines := 13
#the color a boundary is drawn in, where one part of a chart gives way to another: the end of the take-off run, the height a
#climb runs out at. it is the color the grid is drawn in, so it reads as a boundary rather than as data
var boundary_rule_color := Color(0.72, 0.72, 0.72, 0.5)

func fit_graph_columns() -> void:
	var columns : int = 2 if size.x >= two_column_width else 1
	%GraphGrid.columns = columns
	%AltitudeGrid.columns = columns
	%PerformanceGrid.columns = columns
	%ResponseGrid.columns = columns
	%TurnMetrics.columns = 4 if size.x >= turn_metrics_row_width else 2
	
	#the turn chart takes its share of the dock's height, so the grid under it is what scrolls rather than the chart shrinking with it
	%TurnPerformanceGraph.custom_minimum_size.y = size.y * turn_chart_height_share
	
	#every chart in the grids is the same height as every other, that height following the dock, and the same width as every
	#other, which is what the dock is never dragged below
	var graph_height : float = clampf(size.y * graph_height_share, graph_height_floor, graph_height_ceiling)
	var graph_width : float = minimum_graph_width()
	for grid : GridContainer in [%GraphGrid, %AltitudeGrid, %PerformanceGrid, %ResponseGrid]:
		for child : Node in grid.get_children():
			if child is AeroGraph: child.custom_minimum_size = Vector2(graph_width, graph_height)
	
	#the error chart stands taller than a grid chart, because the space between its curves is what it is read for
	%ResponseErrorGraph.custom_minimum_size = Vector2(graph_width, response_chart_height())
	%ResponseLoadTimeGraph.custom_minimum_size = Vector2(graph_width, response_chart_height())
	
	#the row of breakdowns at different pressures stands the same height, and each keeps its share of the dock's width
	for cell : Node in %PressureCharts.get_children():
		var graph := cell.get_node_or_null("PressureGraph") as AeroGraph
		if graph: graph.custom_minimum_size = Vector2(response_chart_width(), response_chart_height())

#the width a graph is squeezed to before there is nothing left to read on it
func minimum_graph_width() -> float:
	return get_theme_default_font_size() * graph_minimum_width_lines

#the height the response charts are drawn at, as a share of the dock's own and within bounds
func response_chart_height() -> float:
	return clampf(size.y * response_chart_height_share, response_chart_height_floor, response_chart_height_ceiling)

#the width a graph of the pressure row is drawn at, which is the same on every dock
func response_chart_width() -> float:
	return get_theme_default_font_size() * response_chart_width_lines


#recalculating

#the tabs a sweep is flown for: the static analysis, the turn performance, and the numbers that change with altitude
const STATIC_TAB := 0
const PERFORMANCE_TAB := 2
const ALTITUDE_TAB := 3
#set while a recalculation is waiting for the end of the frame, which is what folds a burst of changes into one sweep
var recalculation_queued := false
#a sweep that lands sooner than this never puts the sheet up, so quick recalculations do not flash it
const BUSY_SHEET_DELAY := 300
#how much of the dock shows through while a sweep flies: what is there fades toward the panel behind it rather than being covered
var busy_fade := 0.2
#when the sweep in flight started, in milliseconds
var busy_since_msec := 0

#set when something the static analysis is flown from changed: the aircraft, the air, the speed or the sample count
var static_stale := true

#set when something the turn performance is flown from changed: the aircraft, its configuration or the air the dock is
#declared to fly in. the settings that only move the other graphs leave it alone, so a change of test speed or datapoint
#count does not fly the turn sweep again
var turn_performance_stale := true

#set when something the altitude sweep is flown from changed: the aircraft and its configuration, but not the air the turn
#chart is declared to fly in, which the altitude sweep works out for itself
var altitude_stale := true

#asks for a recalculation at the end of the frame, so a burst of changes within one frame starts one sweep. the sweeps fly
#on a worker, so the dock keeps up with the aircraft while it is being edited instead of waiting for the edits to settle
func queue_recalculate() -> void:
	#the exported setters also run while the dock is still being built, where there is nothing to report on yet
	if not is_inside_tree(): return
	if recalculation_queued: return
	
	recalculation_queued = true
	recalculate.call_deferred()

#the aircraft changing shape or moving an influencer changes what it can turn at, so the performance sweep is queued too
func queue_flight_model_changed() -> void:
	static_stale = true
	turn_performance_stale = true
	altitude_stale = true
	response_stale = true
	response_asked_msec = Time.get_ticks_msec()
	queue_recalculate()

#the aircraft as the sweeps read it, gathered into one number: its mass properties, and every value stored on the parts it is
#made of. it is taken when a sweep starts and again after an undo or a redo
var swept_model := 0

#the stored properties each kind of part reports, worked out once rather than for every read of the model
var stored_property_names := {}

func part_property_names(influencer : AeroInfluencer3D) -> PackedStringArray:
	#parts of one native class can carry different scripts, and with them different values to read
	var part_script : Script = influencer.get_script()
	var key : Variant = part_script if part_script else influencer.get_class()
	if stored_property_names.has(key): return stored_property_names[key]
	
	var names := PackedStringArray()
	for property : Dictionary in influencer.get_property_list():
		if (property.usage & PROPERTY_USAGE_STORAGE) != 0: names.append(property.name)
	
	stored_property_names[key] = names
	return names

func flight_model_fingerprint() -> int:
	if not aerobody: return 0
	
	var values : Array = [aerobody.mass, aerobody.center_of_mass]
	for node : Node in aerobody.find_children("*", "AeroInfluencer3D", true, false):
		var influencer := node as AeroInfluencer3D
		values.append(influencer.get_class())
		values.append(influencer.transform)
		for name : StringName in part_property_names(influencer):
			var value : Variant = influencer.get(name)
			#the configs are resources, which report their own changes rather than being read here
			if value is Resource: continue
			values.append(value)
	
	return hash(values)

#an undo or a redo is read back rather than trusted to have reported itself, and the sweeps are flown again only when what the
#aircraft is made of has actually moved, so undoing something else costs nothing
func _on_undo_redo() -> void:
	if not aerobody or not is_visible_in_tree(): return
	
	var model := flight_model_fingerprint()
	if model == swept_model: return
	
	swept_model = model
	queue_flight_model_changed()

#the sweep in flight, and the copy of the aircraft the worker flies it against. the dock touches none of these until the
#task is done, and the thread touches nothing else
var worker_task := -1
var worker_copy : AeroBody3D
var worker_sweeps : AircraftSweeps
var worker_results := {}
var worker_runs_static := false
var worker_runs_turn := false
var worker_runs_altitude := false
var worker_runs_response := false
var worker_dirty := false

#the sheet drawn over the dock while the sweeps are flying, so it is clear the numbers are being worked out and that the
#settings under it are not to be touched until they land. the root stacks it over the panel, so it fills the dock wherever
#the editor moves the dock to
@onready var busy_sheet : ColorRect = %BusySheet
#where the copy of the aircraft the worker flies is put
var simulation_view : SubViewport

#raises or drops the sheet, which also swallows the clicks that would change the settings under it, and fades what is under it
#toward the panel behind it: nothing is laid over the page, so its gray is untouched and the charts are what recede into it
func set_busy(busy : bool) -> void:
	busy_sheet.visible = busy
	%Panel.modulate.a = busy_fade if busy else 1.0

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
	var sweep_altitude : bool = %Tabs.current_tab == ALTITUDE_TAB and altitude_stale
	#the response tests wait for the edits to settle, so dragging a part does not fly a step per frame
	var sweep_response : bool = %Tabs.current_tab == RESPONSE_TAB and response_stale \
		and Time.get_ticks_msec() - response_asked_msec >= RESPONSE_SETTLE_MSEC
	if not sweep_static and not sweep_turn and not sweep_altitude and not sweep_response: return
	
	#a sweep already in flight is left to finish rather than interrupted, and flown again as soon as it lands
	if worker_task != -1:
		worker_dirty = true
		return
	
	start_sweeps(sweep_static, sweep_turn, sweep_altitude, sweep_response)

#deep-copies the aircraft for the worker to fly, so the sweeps never touch the nodes being edited. the copy goes into a
#viewport of its own, so it enters a tree and initializes like any aircraft, and is then taken out of the frame's way: it does
#not process, show or collide with anything
func start_sweeps(sweep_static : bool, sweep_turn : bool, sweep_altitude : bool, sweep_response : bool) -> void:
	#what the sweeps are about to fly is kept, so an undo or a redo can be told apart from one that changed nothing
	swept_model = flight_model_fingerprint()
	
	worker_copy = copy_aircraft()
	#a sweep works its forces out for itself rather than flying the copy frame by frame, so the copy is taken out of the frame's
	#way: it does not process, show or collide with anything
	worker_copy.process_mode = Node.PROCESS_MODE_DISABLED
	
	#the nodes the sweeps reach into are gathered here, on the main thread: a thread may not search the scene itself. the
	#thrusters are the influencers that also carry a throttle, so the one search covers both
	var influencers : Array[AeroInfluencer3D] = []
	var thrusters : Array[AeroThruster3D] = []
	for node : Node in worker_copy.find_children("*", "AeroInfluencer3D", true, false):
		var influencer := node as AeroInfluencer3D
		influencers.append(influencer)
		if influencer is AeroThruster3D: thrusters.append(influencer)
	
	#the copy is only ever read by the worker, where a signal can neither be inspected nor emitted: its parts are silenced so the
	#sweeps' surface moves and propeller phasing do not announce a flight model change to listeners that are not there
	for influencer : AeroInfluencer3D in influencers: influencer.suppress_flight_model_changed = true
	
	worker_sweeps = AircraftSweeps.new()
	worker_sweeps.body = worker_copy
	worker_sweeps.influencers = influencers
	worker_sweeps.thrusters = thrusters
	worker_sweeps.control = control_component(worker_copy)
	#the inertia is read here, where the physics server answers at once: a worker asking for it waits about a second a call
	worker_sweeps.inertia = worker_copy.get_moment_of_inertia()
	worker_sweeps.test_speed = test_speed
	worker_sweeps.sweep_datapoints = sweep_datapoints
	worker_sweeps.reference_area = reference_area
	worker_sweeps.reference_span = reference_span
	worker_sweeps.reference_chord = reference_chord
	worker_sweeps.altitude = altitude
	worker_sweeps.density = density_at(altitude)
	worker_sweeps.pressure = pressure_at(altitude)
	worker_sweeps.sound_speed = sound_speed_at(altitude)
	worker_sweeps.load_limit = load_limit
	worker_sweeps.turn_datapoints = turn_datapoints
	worker_sweeps.altitude_datapoints = altitude_datapoints
	worker_sweeps.response_axis = response_axis()
	worker_sweeps.response_speed = %ResponseSpeed.value
	worker_sweeps.response_pressures = roundi(%ResponsePressures.value)
	worker_sweeps.response_skip_lowest = roundi(%ResponseSkipLowest.value)
	worker_sweeps.response_seconds = RESPONSE_SECONDS
	
	#the speed envelope is flown over a ladder of altitudes, so the air at each of them goes with the sweep
	for index : int in altitude_steps:
		var height : float = remap(index, 0, altitude_steps - 1, AircraftSweeps.ENVELOPE_ALTITUDE_FLOOR, AircraftSweeps.ENVELOPE_ALTITUDE_CEILING)
		worker_sweeps.altitudes.append(height)
		worker_sweeps.altitude_densities.append(density_at(height))
		worker_sweeps.altitude_pressures.append(pressure_at(height))
		worker_sweeps.altitude_sound_speeds.append(sound_speed_at(height))
	
	#the sweeps are marked fresh as they are handed over, so an edit arriving mid-flight marks them stale again
	if sweep_static: static_stale = false
	if sweep_turn: turn_performance_stale = false
	if sweep_altitude: altitude_stale = false
	if sweep_response: response_stale = false
	worker_runs_static = sweep_static
	worker_runs_turn = sweep_turn
	worker_runs_altitude = sweep_altitude
	worker_runs_response = sweep_response
	worker_results = {}
	worker_task = WorkerThreadPool.add_task(run_sweeps, false, "wind tunnel sweeps")
	busy_since_msec = Time.get_ticks_msec()

#the worker thread: flies the sweeps against the copy and leaves the results where the dock picks them up
func run_sweeps() -> void:
	var results := {}
	if worker_runs_static: results["static"] = worker_sweeps.static_analysis()
	if worker_runs_turn: results["turn"] = worker_sweeps.turn_performance()
	if worker_runs_altitude: results["altitude"] = worker_sweeps.altitude_sweep()
	if worker_runs_response: results["response"] = worker_sweeps.control_response()
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
	if results.has("altitude"): draw_altitude_sweep(results["altitude"])
	if results.has("response"): draw_control_response(results["response"])
	
	if worker_dirty:
		worker_dirty = false
		queue_recalculate()

#a copy of the aircraft for a run to fly against, so the nodes being edited are never touched. it goes into the dock's own
#viewport, so it enters a tree and initializes like any aircraft, and it keeps its script instances: a deep duplicate would
#instantiate them and the copied nodes would come out without their behavior
func copy_aircraft() -> AeroBody3D:
	var copy : AeroBody3D = aerobody.duplicate()
	
	#a run flies the copy at the attitude it is given, so it is put at the origin facing forward before it enters the tree
	copy.transform = Transform3D()
	copy.linear_velocity = Vector3.ZERO
	copy.angular_velocity = Vector3.ZERO
	copy.visible = false
	copy.collision_layer = 0
	copy.collision_mask = 0
	
	#the pose each part was authored with is the one the aircraft being copied remembers: a part's default pose is settled as it
	#enters the tree, so a copied part would take the pose it was copied at for its own, which for an aircraft that has been flying
	#is a deflected one. the poses are put back once the copy is in the tree, because a part settles its own state as it enters
	var authored_poses := {}
	for node : Node in aerobody.find_children("*", "AeroInfluencer3D", true, false):
		var influencer := node as AeroInfluencer3D
		if influencer.actuation_config == null or is_turned_part(influencer, aerobody): continue
		authored_poses[aerobody.get_path_to(influencer)] = influencer.default_transform
	
	simulation_view.add_child(copy)
	
	for path : NodePath in authored_poses:
		var part := copy.get_node_or_null(path) as AeroInfluencer3D
		if part: part.transform = authored_poses[path]
	
	#the copy takes its own copy of everything a run drives. the editor leaves these resources shared with the aircraft in the
	#scene, so a run opening the throttle would be flying the aircraft being edited as well, and its preview would hand the change
	#back as an edit of the model, which starts a sweep over again
	for node : Node in copy.find_children("*", "AeroControlComponent", true, false):
		var component := node as AeroControlComponent
		if component.control_config: component.control_config = component.control_config.duplicate(true)
		if component.flight_assist: component.flight_assist = component.flight_assist.duplicate(true)
	
	for node : Node in copy.find_children("*", "AeroInfluencer3D", true, false):
		var influencer := node as AeroInfluencer3D
		if influencer.actuation_config:
			influencer.actuation_config = influencer.actuation_config.duplicate(true)
		if influencer is AeroThruster3D and influencer.throttle_control_config:
			influencer.throttle_control_config = influencer.throttle_control_config.duplicate(true)
		if influencer is AeroPropeller3D and influencer.propeller_speed_control_config:
			influencer.propeller_speed_control_config = influencer.propeller_speed_control_config.duplicate(true)
		if influencer is AeroCyclicPropeller3D and influencer.cyclic_control_config:
			influencer.cyclic_control_config = influencer.cyclic_control_config.duplicate(true)
	
	return copy

#the control component of an aircraft, which is the only one the flight assist and the controls are read from
func control_component(body : AeroBody3D) -> AeroControlComponent:
	for child : Node in body.get_children():
		if child is AeroControlComponent: return child
	
	return null

#the air the sweeps are flown in, asked for at the declared altitude or at any height the speed envelope is flown through. it
#comes from the atmosphere tables, and nothing about where the aircraft sits in the scene goes into it
func density_at(height : float) -> float:
	var density : float = AeroUnits.get_density_at_altitude(height)
	return density if density > 0.0 else SEA_LEVEL_DENSITY

func pressure_at(height : float) -> float:
	var pressure : float = AeroUnits.get_pressure_at_altitude(height)
	return pressure if pressure > 0.0 else SEA_LEVEL_PRESSURE

func sound_speed_at(height : float) -> float:
	return AeroUnits.get_speed_of_sound_at_pressure_and_density(pressure_at(height), density_at(height))


#control response

#how long a step is flown for: long enough for a quick rate to peak and settle and for what is left over to show, short enough
#to wait for
const RESPONSE_SECONDS := 5.0
#seconds added to the time before the breakdown logs it. a plain log stretches the first frame across half the chart; the larger this
#is the less the first moments are stretched and the more room the rest of the run gets
const RESPONSE_TIME_OFFSET := 0.2

#the tab the response tests belong to, and how long a change to the aircraft has to sit before they are flown again, so dragging
#a part does not fly a step per frame
const RESPONSE_TAB := 1
const RESPONSE_SETTLE_MSEC := 400

#set when the aircraft changed under the tests, and when that change was last seen
var response_stale := true
var response_asked_msec := 0

#the button flies the tests without waiting for the edits to settle
func _on_response_run_pressed() -> void:
	response_stale = true
	response_asked_msec = 0
	queue_recalculate()

#opening the response tab flies its tests at once rather than waiting for the edits to settle
func _on_tab_changed(index : int) -> void:
	if index == RESPONSE_TAB: response_asked_msec = 0

#a change to what the tests are flown from marks them stale, and they are flown once the change has settled
func queue_response_tests() -> void:
	response_stale = true
	response_asked_msec = Time.get_ticks_msec()
	queue_recalculate()

#the axis the menu names
func response_axis() -> String:
	return %ResponseAxis.get_item_text(%ResponseAxis.selected)

#takes the last step's curves off the step charts
func clear_step_graphs() -> void:
	%ResponseRateGraph.clear_curves()
	%ResponseLoadGraph.clear_curves()
	%ResponseLoadGraph.clear_rules()
	%ResponseLoadGraph.clear_labels()

#the control response the worker flew: the airframe's own answer, the step at the chosen speed, the row across the regime, and
#the error chart that compares it
func draw_control_response(result : Dictionary) -> void:
	#an aircraft with no control component has nothing to measure at all
	if not result.has_control:
		clear_step_graphs()
		clear_pressure_charts()
		%ResponseResult.text = "This aircraft has no control component to measure."
		return
	
	var index : int = result.index
	var curves : Array = result.effectiveness
	var names : Array[String] = ["Mx (pitch)", "My (yaw)", "Mz (roll)"]
	
	%ResponseEffectivenessGraph.clear_curves()
	%ResponseEffectivenessGraph.add_curve(curves[index], CURVE_COLORS[index], names[index])
	
	#what the command drags along with it: the two axes it was not asked for, so a pitch input that rolls the aircraft is visible
	%ResponseCouplingGraph.clear_curves()
	for other : int in 3:
		if other == index: continue
		%ResponseCouplingGraph.add_curve(curves[other], CURVE_COLORS[other], names[other])
	
	%ResponseDeflectionGraph.clear_curves()
	var deflections : Array = result.deflections
	for surface_index : int in deflections.size():
		var deflection : ControlResponse.Deflection = deflections[surface_index]
		%ResponseDeflectionGraph.add_curve(deflection.points, CURVE_COLORS[surface_index % CURVE_COLORS.size()], deflection.surface)
	
	#no assist means no step was flown: the airframe's answer is all there is, and the tab says why
	if result.chosen == null:
		clear_step_graphs()
		clear_pressure_charts()
		%ResponseResult.text = "No flight assist on this aircraft: only the airframe's answer is measured."
		return
	
	draw_response(result.chosen)
	clear_pressure_charts()
	
	#the row spans the regime in dynamic pressure rather than in speed, because the regime is a range of pressure: one pressure is
	#the same trim and the same response whatever height it is flown at. where the sweeps cannot work the range out, the row shows
	#the chosen speed alone
	var conditions : PackedVector2Array = result.conditions
	var traces : Array = result.traces
	var below : int = result.corner_index
	var above : int = conditions.size() - below - 1
	var stats_all : Array[Dictionary] = []
	for condition_index : int in traces.size():
		var condition : Vector2 = conditions[condition_index]
		var trace : ControlResponse.Trace = traces[condition_index]
		var color : Color = condition_color(condition_index, below, above)
		var stats := response_stats(trace)
		#at and below the corner the airframe is what stops the pull, so the shape of the response is not the gains' doing
		if condition_index <= below: stats.damping = "wing-limited"
		stats_all.append(stats)
		add_pressure_graph(condition, trace, color, stats)
		draw_pressure_error(condition, trace, color)
	
	#the load each condition pulls against time. the rate curves overshoot while the angle of attack is being taken up, which is the
	#right shape for getting to the limit quickly, so the quantity being aimed at is drawn here instead
	draw_load_curves(conditions, traces, result.chosen.g_limit, below, above)
	
	#the ceiling the limit is asked to fit under, in the air these tests are flown in: the wing's own load against speed, so the
	#speed below which no tune can reach the limit is a crossing on this chart rather than a guess
	draw_capability(result.load_ceiling, result.chosen.g_limit)
	
	#the condition furthest from an ideal response is the one worth tuning against, and its sign says on which side of the limit
	var worst := 0.0
	var worst_pressure := NAN
	for stats_index : int in stats_all.size():
		if stats_all[stats_index].damping == "wing-limited": continue
		if absf(stats_all[stats_index].off) <= absf(worst): continue
		worst = stats_all[stats_index].off
		worst_pressure = conditions[stats_index].x / 1000.0
	if not is_nan(worst_pressure):
		%ResponseResult.text += " · furthest off: %.1f kPa at %+.0f%%·s" % [worst_pressure, worst]
	
	if is_nan(result.regime.x):
		%ResponseResult.text += " The flight regime could not be worked out, so the row shows the chosen speed only."

#how a condition's load answers the limit: how long it took to get there, how far over it went, when it last left the band
#around it, and how much of the run was spent on the wrong side. the last one is signed, so a negative score is a response that
#never came up to the limit and a positive one is a response that sat over it
func response_stats(trace : ControlResponse.Trace) -> Dictionary:
	var stats := {"damping": "over-damped", "rise": NAN, "peak": 0.0, "settle": NAN, "off": 0.0}
	var count : int = trace.load.size()
	var limit : float = trace.g_limit
	if count < 2 or limit <= 0.0: return stats
	
	var times := trace.times()
	var step : float = times[count - 1] / float(count - 1)
	var peak := -INF
	var off := 0.0
	for index : int in count:
		peak = maxf(peak, trace.load[index])
		off += (trace.load[index] - limit) / limit * step
	stats.peak = peak - limit
	stats.off = off * 100.0
	
	for sample : int in count:
		if trace.load[sample] < 0.9 * limit: continue
		stats.rise = times[sample]
		break
	
	#the last moment it was outside two percent of the limit: everything after that is settled
	var outside := -1.0
	for moment : int in count:
		if absf(trace.load[moment] - limit) > 0.02 * limit: outside = times[moment]
	if outside < times[count - 1]: stats.settle = outside
	
	var overshoot : float = stats.peak / limit
	if stats.settle >= 0.0:
		stats.damping = "under-damped" if overshoot > 0.05 else ("lightly damped" if overshoot > 0.01 else "damped")
	else:
		stats.damping = "under-damped" if overshoot > 0.05 else "over-damped"
	
	return stats

#the load each condition pulls, against time and against the limit, with the moment it first reached it marked: the number
#this chart is read for is how long that took
func draw_load_curves(conditions : PackedVector2Array, traces : Array, limit : float, below : int, above : int) -> void:
	var graph : AeroGraph = %ResponseLoadTimeGraph
	graph.clear_curves()
	graph.clear_rules()
	graph.clear_labels()
	graph.clear_markers()
	
	for index : int in traces.size():
		var trace : ControlResponse.Trace = traces[index]
		var color : Color = condition_color(index, below, above)
		var log_times := response_log_times(trace)
		graph.add_curve(trace_points(log_times, trace.load), color, "%.2f kPa" % (conditions[index].x / 1000.0))
		
		if limit <= 0.0: continue
		var times := trace.times()
		for sample : int in trace.load.size():
			if trace.load[sample] < limit - 0.02: continue
			graph.add_marker(Vector2(log_times[sample], trace.load[sample]), "Reaches the limit", "%.2f kPa: %.2f s" % [conditions[index].x / 1000.0, times[sample]], color)
			break
	
	if limit <= 0.0: return
	graph.add_y_rule(limit, boundary_rule_color)
	var shown : Rect2 = graph.visible_bounds()
	graph.add_label("%.1f g limit" % limit, Vector2(shown.end.x, limit), Vector2(1.0, 0.0), HORIZONTAL_ALIGNMENT_RIGHT)

#the most load the wing can hold at each speed in this air, against the limit it is asked to pull
func draw_capability(curve : PackedVector2Array, limit : float) -> void:
	var graph : AeroGraph = %ResponseCapabilityGraph
	graph.clear_curves()
	graph.clear_rules()
	graph.clear_labels()
	graph.clear_markers()
	
	#the ceiling a pilot actually gets: the wing below the corner, and the declared limit above it, which is what keeps the wing's
	#own figures (eighty-odd g at the top of the speed range) from squashing the limit into the foot of the chart
	var held := PackedVector2Array()
	var corner := Vector2.ZERO
	var reaches := false
	for point : Vector2 in curve:
		if limit > 0.0 and not reaches and point.y >= limit:
			reaches = true
			corner = Vector2(point.x, limit)
		held.append(Vector2(point.x, minf(point.y, limit) if limit > 0.0 else point.y))
	
	graph.add_curve(held, Color(1, 1, 1, 0.8), "Max load")
	if limit <= 0.0: return
	
	graph.add_y_rule(limit, boundary_rule_color)
	var shown : Rect2 = graph.visible_bounds()
	graph.add_label("%.1f g limit" % limit, Vector2(shown.end.x, limit), Vector2(1.0, 0.0), HORIZONTAL_ALIGNMENT_RIGHT)
	
	#the corner, in white because that is the color the row puts on it: below it the wing cannot reach the limit at all, whatever
	#the gains are
	if reaches: graph.add_marker(corner, "Holds the limit", "%.1f m/s" % corner.x, Color(1, 1, 1))

#the color a condition is known by in both charts: red through yellow under the speed the wing first holds the limit at, that
#speed in white, and green through blue above it, so the row reads as the two sides of the corner at a glance
func condition_color(index : int, below : int, above : int) -> Color:
	if index == below: return Color(1, 1, 1)
	if index < below:
		return Color.from_hsv(remap(index, 0.0, maxf(below - 1.0, 1.0), 0.0, 0.16), 0.65, 1.0)
	return Color.from_hsv(remap(index - below - 1.0, 0.0, maxf(above - 1.0, 1.0), 0.33, 0.6), 0.65, 1.0)

#one graph of the row: the breakdown at one dynamic pressure, named with the pressure and the speed it came to, so a run of them
#can be read side by side and the response compared across the regime
func add_pressure_graph(condition : Vector2, trace : ControlResponse.Trace, color : Color, stats : Dictionary) -> void:
	var cell := %PressureCell.duplicate() as VBoxContainer
	cell.unique_name_in_owner = false
	cell.visible = true
	%PressureCharts.add_child(cell)
	
	#the label carries the color of this pressure's curve in the error chart, so a curve and the graph under it are read as a pair
	var name_label : Label = cell.get_node("PressureLabel")
	name_label.text = "%.2f kPa · %.0f m/s" % [condition.x / 1000.0, condition.y]
	name_label.add_theme_color_override("font_color", color)
	
	#the response itself, said in words: when it converges, how far over the limit it goes, and how far off an ideal one it is
	var stats_label : Label = cell.get_node("PressureStats")
	var settle := "never" if is_nan(stats.settle) else "%.1f s" % stats.settle
	stats_label.text = "%s\nconverges %s, peak %+.1f g" % [stats.damping, settle, stats.peak]
	stats_label.tooltip_text = "%s: reached 90%% of the limit at %s, settled at %s, peak %+.2f g, off target %+.0f%%·s (%.0f%% %s the limit)" % [
		stats.damping,
		"never" if is_nan(stats.rise) else "%.2f s" % stats.rise,
		settle, stats.peak, stats.off, absf(stats.off), "over" if stats.off > 0.0 else "under"]
	
	var graph : AeroGraph = cell.get_node("PressureGraph")
	graph.custom_minimum_size = Vector2(response_chart_width(), response_chart_height())
	draw_breakdown(graph, trace)

#one pressure's rate error through the step, on the same log time axis as the breakdowns, so every condition in the row can be read
#against the others in one chart. the error is what the aircraft reached less what the assist asked for: under the zero line it is
#short of the request, above it it overshot, and a curve that settles on zero is the response the tuning is after
func draw_pressure_error(condition : Vector2, trace : ControlResponse.Trace, color : Color) -> void:
	var log_times := response_log_times(trace)
	var error := PackedVector2Array()
	for index : int in mini(log_times.size(), trace.achieved_rate.size()):
		error.append(Vector2(log_times[index], rad_to_deg(trace.achieved_rate[index] - trace.commanded_rate[index])))
	
	%ResponseErrorGraph.add_curve(error, color, "%.2f kPa" % (condition.x / 1000.0))

#takes the row down to its own template and the error chart back to nothing, which is how the next run starts
func clear_pressure_charts() -> void:
	for cell : Node in %PressureCharts.get_children():
		if cell == %PressureCell: continue
		%PressureCharts.remove_child(cell)
		cell.queue_free()
	
	%ResponseErrorGraph.clear_curves()
	%ResponseLoadTimeGraph.clear_curves()
	%ResponseLoadTimeGraph.clear_rules()
	%ResponseLoadTimeGraph.clear_labels()
	%ResponseLoadTimeGraph.clear_markers()
	%ResponseCapabilityGraph.clear_curves()
	%ResponseCapabilityGraph.clear_rules()
	%ResponseCapabilityGraph.clear_labels()
	%ResponseCapabilityGraph.clear_markers()


#drawing

#where a turn radius line carries its name: at its end, where the lines stand furthest apart
var radius_label_fraction := 1.0
#where an excess power contour carries its name: up along it where the contours stand apart, rather than at its foot, where
#the whole family converges with the radius lines and their names
var power_label_fraction := 0.3
#the run a load factor number is written along: a short one, which only says that the number reads straight across the chart
#rather than turned along the line it belongs to
var load_label_span := 0.03
#how far the held turn's name is lifted off the fastest turn's, for the times the two sit on the same point
var turn_label_lift := 18.0
#how far left of the lift limit the load factor name stands, which is clear of the numbers written against that limit
var load_name_clearance := 46.0
#the contour through nothing is the edge of a turn the aircraft can hold rather than fall out of, so it is drawn this much heavier
#than the others, while a contour of energy lost is a turn it cannot hold at all and is drawn this much fainter and thinner
var zero_power_width := 2.0
var negative_power_width := 0.8
var negative_power_fade := 0.35

#the static analysis: the coefficient curves, the moment curves, the drag polar and the numbers under them
func draw_static_analysis(results : Dictionary) -> void:
	var alpha : Dictionary = results.alpha
	var beta : Dictionary = results.beta
	var inertia := get_body_inertia()
	
	%LiftDragGraph.clear_curves()
	%LiftDragGraph.add_curve(alpha.lift, CURVE_COLORS[0], "CL")
	%LiftDragGraph.add_curve(alpha.drag, CURVE_COLORS[1], "CD")
	#the lift to drag ratio is drawn against the full height of the graph rather than the coefficient scale, so it is added
	#on its own and says so
	var ratio_curve : AeroGraph.CurveData = %LiftDragGraph.add_curve(alpha.ratio, CURVE_COLORS[2], "L/D")
	ratio_curve.normalize_y = true
	
	%PitchMomentsGraph.clear_curves()
	%PitchMomentsGraph.add_curve(angular_acceleration(alpha.pitch, inertia.x), CURVE_COLORS[0], "Mx (pitch)")
	%PitchMomentsGraph.add_curve(angular_acceleration(alpha.yaw, inertia.y), CURVE_COLORS[1], "My (yaw)")
	%PitchMomentsGraph.add_curve(angular_acceleration(alpha.roll, inertia.z), CURVE_COLORS[2], "Mz (roll)")
	
	%SideslipMomentsGraph.clear_curves()
	%SideslipMomentsGraph.add_curve(angular_acceleration(beta.pitch, inertia.x), CURVE_COLORS[0], "Mx (pitch)")
	%SideslipMomentsGraph.add_curve(angular_acceleration(beta.yaw, inertia.y), CURVE_COLORS[1], "My (yaw)")
	%SideslipMomentsGraph.add_curve(angular_acceleration(beta.roll, inertia.z), CURVE_COLORS[2], "Mz (roll)")
	
	%RollMomentsGraph.clear_curves()
	%RollMomentsGraph.add_curve(angular_acceleration(results.roll.moment, inertia.z), CURVE_COLORS[2], "Mz (roll)")
	
	%PolarGraph.clear_curves()
	%PolarGraph.add_curve(alpha.polar, CURVE_COLORS[2], "CL vs CD", alpha.polar_alphas)
	
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
	blank_labels([%SpeedValue, %PressureValue, %AreaValue, %SpanValue, %ChordValue, %LiftMaxValue, %RatioValue, %GlideValue, %SinkValue, %StiffnessValue, %MarginValue])
	
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
	
	var families : Array[Dictionary] = []
	
	#the turn radius lines go down first, so the families the chart is read for sit over them
	for family : Dictionary in chart.radii:
		var points : PackedVector2Array = family.points
		var radius_line : AeroGraph.CurveData = %TurnPerformanceGraph.add_curve(points, Color(CURVE_COLORS[3], 0.7), "radius %d m" % roundi(family.radius))
		%TurnPerformanceGraph.add_curve_label(radius_line, "%d m" % roundi(family.radius), label_position(points, radius_label_fraction))
	if not chart.radii.is_empty():
		families.append({"text": "TURN RADIUS (M)", "points": chart.radii[chart.radii.size() / 2].points, "start": 0.55, "end": 0.85})
	
	#the lift limit, which is where the wing stalls. it runs up to the last load factor line, which is what closes the top of the
	#chart and stands for the g limit
	if chart.limit.size() > 1:
		var limit_line : AeroGraph.CurveData = %TurnPerformanceGraph.add_curve(chart.limit, CURVE_COLORS[0], "lift limit")
		limit_line.width = 2.0
	
	#the 1 g line, which is where every turn radius line starts at its lower end: the turn rate of a turn pulling 1 g sideways. it
	#carries the load factor color because that is what it is, and its number is the bottom of the same staircase of numbers
	if chart.one_g.size() > 1:
		%TurnPerformanceGraph.add_curve(chart.one_g, CURVE_COLORS[2], "1 g pull")
		%TurnPerformanceGraph.add_label("1 g", chart.one_g[0], Vector2(load_label_span, 0.0), HORIZONTAL_ALIGNMENT_RIGHT)
	
	#the constant load factor lines, which are turns the aircraft can pull while it still has the lift for them. each one is
	#named just to the left of where it starts on the lift limit, so the numbers step up the side of the chart. they are written
	#before anything else, because that is the room nothing else is allowed to take
	for family : Dictionary in chart.loads:
		if family.points.is_empty(): continue
		
		%TurnPerformanceGraph.add_curve(family.points, CURVE_COLORS[2], "load factor %s" % format_load(family.load))
		var start : Vector2 = family.points[0]
		%TurnPerformanceGraph.add_label(format_load(family.load), start, Vector2(load_label_span, 0.0), HORIZONTAL_ALIGNMENT_RIGHT)
	#the load factor name runs up the chart beside the numbers, above where the numbers start and clear of them
	if not chart.loads.is_empty() and chart.limit.size() > 2:
		families.append({"text": "LOAD FACTOR (G)", "points": chart.limit, "start": 0.28, "end": 0.42, "clear": load_name_clearance})
	
	#the constant excess power contours, which are the turns it can hold rather than fall out of. a contour that leaves the
	#envelope and comes back is drawn as more than one line, and only the longest of its stretches carries the name
	for family : Dictionary in chart.powers:
		var longest : int = longest_run(family.runs)
		var level : float = family.level
		for index : int in family.runs.size():
			var run : PackedVector2Array = family.runs[index]
			if run.size() < 2: continue
			
			var color : Color = CURVE_COLORS[1]
			var width := 0.0
			if is_zero_approx(level):
				width = zero_power_width
			elif level < 0.0:
				color = Color(CURVE_COLORS[1], negative_power_fade)
				width = negative_power_width
			
			#a contour of energy lost carries no name of its own: the family name says what the faint lines are, and the numbers
			#are kept for the turns the aircraft can actually hold
			var labeled : bool = index == longest and level >= 0.0
			var contour : AeroGraph.CurveData = %TurnPerformanceGraph.add_curve(run, color, "excess power %d m/s" % roundi(level))
			if width > 0.0: contour.width = width
			if labeled:
				%TurnPerformanceGraph.add_curve_label(contour, "%d m/s" % roundi(level), label_position(run, power_label_fraction))
	
	#the name of that family goes along the longest stretch of the contour through the middle of the chart
	if not chart.powers.is_empty():
		var middle : Array = chart.powers[chart.powers.size() / 2].runs
		families.append({"text": "EXCESS POWER (M/S)", "points": middle[longest_run(middle)], "start": 0.45, "end": 0.7})
	
	add_family_labels(families)
	
	#the numbers the strip reports are marked where they sit, so a reading is never far from its place on the chart. the held
	#turn can sit on the fastest one, so its name is lifted clear of the first
	var metrics : Dictionary = chart.get("metrics", {})
	%TurnPerformanceGraph.clear_markers()
	mark_turn_point(metrics.get("corner", {}), "Max turn rate", CURVE_COLORS[0], 0.0)
	mark_turn_point(metrics.get("sustained", {}), "Sustained turn", CURVE_COLORS[1], turn_label_lift)
	mark_turn_point(metrics.get("tightest", {}), "Min turn radius", CURVE_COLORS[2], 0.0)
	
	update_turn_metrics(metrics)
	
	#the speed the aircraft gains in level flight at each speed, charted below the turn chart: the line reaches nothing where the
	#aircraft has no acceleration left to give, which is its top speed. the speed axis runs from a standstill to a round step past
	#that speed, so the numbers along it read as round ones, and the line only starts where the aircraft first carries its weight
	var acceleration : PackedVector2Array = chart.get("acceleration", PackedVector2Array())
	var fastest : float = 0.0
	if not acceleration.is_empty(): fastest = acceleration[acceleration.size() - 1].x
	
	var reach : float = maxf(fastest * 1.05, 10.0)
	var step : float = nearest_round_step(reach / float(maxi(%AccelerationGraph.axis_divisions.x, 1)))
	var top : float = step * ceilf(reach / step)
	
	%AccelerationGraph.auto_bounds_x = false
	%AccelerationGraph.axis_divisions.x = maxi(roundi(top / step), 1)
	%AccelerationGraph.lower_bound = Vector2(0.0, %AccelerationGraph.lower_bound.y)
	%AccelerationGraph.upper_bound = Vector2(top, %AccelerationGraph.upper_bound.y)
	
	var takeoff : PackedVector2Array = chart.get("takeoff", PackedVector2Array())
	%AccelerationGraph.clear_curves()
	%AccelerationGraph.add_curve(acceleration, CURVE_COLORS[1], "In flight")
	%AccelerationGraph.add_curve(takeoff, CURVE_COLORS[3], "Take-off run")
	
	#the speed the aircraft leaves the ground at is a line across the chart, washed back to a standstill so the run reads as the
	#stretch of chart it is, and named with the ground it covers
	%AccelerationGraph.clear_labels()
	if takeoff.size() > 1:
		var liftoff : float = takeoff[takeoff.size() - 1].x
		var shown : Rect2 = %AccelerationGraph.visible_bounds()
		var liftoff_line : AeroGraph.CurveData = %AccelerationGraph.add_curve(
			PackedVector2Array([Vector2(liftoff, shown.position.y), Vector2(liftoff, shown.end.y)]),
			boundary_rule_color, "", PackedFloat32Array(), 1.0)
		liftoff_line.fill_axis = AeroGraph.Axis.X
		liftoff_line.fill_color = Color(CURVE_COLORS[3], 0.18)
		
		var distance : float = chart.get("takeoff_distance", NAN)
		var run_name := "Take-off run" if is_nan(distance) else "Take-off run %.0f m" % distance
		%AccelerationGraph.add_label(run_name, takeoff[takeoff.size() / 2], Vector2(1.0, 0.0))

#one of the numbers under the chart, marked where it sits and named beside it, `lift` pixels clear of the line it sits on
func mark_turn_point(point : Dictionary, name : String, color : Color, lift : float) -> void:
	var rate : float = point.get("rate", NAN)
	var mach : float = point.get("mach", NAN)
	if is_nan(rate) or is_nan(mach): return
	
	var value := Vector2(mach, rate)
	%TurnPerformanceGraph.add_marker(value, name, "%s: M %.2f, %.1f deg/s" % [name, mach, rate], color)
	%TurnPerformanceGraph.add_label(name, value, Vector2(1, 0), HORIZONTAL_ALIGNMENT_LEFT, lift)

#one part of the assist's answer, in rate terms: the requested rate plus the rate this part adds to it. drawn from the frame after
#the step, whose derivative kick is over within a tick and would otherwise set the scale of the whole chart
func add_command_part(graph : AeroGraph, times : PackedFloat32Array, requested : PackedFloat32Array, gains : PackedFloat32Array,
		part : PackedFloat32Array, color : Color, name : String) -> void:
	var values := PackedFloat32Array()
	for index : int in requested.size():
		values.append(requested[index] + part[index] * gains[index])
	
	graph.add_curve(trace_points(times, values, 1), color, name)

#the times the breakdowns are read at: log10 of the seconds plus the offset, so the first moments keep a share of the chart
#while the last seconds keep one of their own
func response_log_times(trace : ControlResponse.Trace) -> PackedFloat32Array:
	var times := PackedFloat32Array()
	for stamp : float in trace.times():
		times.append(log(stamp + RESPONSE_TIME_OFFSET) / log(10.0))
	
	return times

#a run of angles in radians, in degrees
func degrees(values : PackedFloat32Array) -> PackedFloat32Array:
	var converted := PackedFloat32Array()
	for value : float in values:
		converted.append(rad_to_deg(value))
	
	return converted

#one array of samples against the run's times, from `first` on
func trace_points(times : PackedFloat32Array, values : PackedFloat32Array, first := 0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index : int in range(first, mini(times.size(), values.size())):
		points.append(Vector2(times[index], values[index]))
	
	return points

#the answer to a control step: the rate the assist asked for beside the rate the aircraft reached, the load the pull put on it, and
#the parts the command was built from
func draw_response(trace : ControlResponse.Trace) -> void:
	if trace.commanded_rate.is_empty(): return
	
	var times := trace.times()
	var demanded := PackedVector2Array()
	var reached := PackedVector2Array()
	for index : int in times.size():
		demanded.append(Vector2(times[index], rad_to_deg(trace.commanded_rate[index])))
		reached.append(Vector2(times[index], rad_to_deg(trace.achieved_rate[index])))
	
	clear_step_graphs()
	%ResponseRateGraph.add_curve(demanded, Color(1, 1, 1, 0.45), "Commanded")
	%ResponseRateGraph.add_curve(reached, CURVE_COLORS[1], "Achieved")
	%ResponseLoadGraph.add_curve(trace_points(times, trace.load), CURVE_COLORS[3], "Load factor")
	
	#the load the airframe is cleared for is ruled across the chart, where the pull is read against it
	if trace.g_limit > 0.0:
		%ResponseLoadGraph.add_y_rule(trace.g_limit, boundary_rule_color)
		var shown : Rect2 = %ResponseLoadGraph.visible_bounds()
		%ResponseLoadGraph.add_label("%.1f g limit" % trace.g_limit, Vector2(shown.end.x, trace.g_limit), Vector2(1.0, 0.0), HORIZONTAL_ALIGNMENT_RIGHT)
	
	var peak := 0.0
	for value : float in trace.achieved_rate: peak = maxf(peak, value)
	
	#the worst share of its own request the limiters took, said beside the numbers so a chart with no band on it is not a puzzle:
	#when they take nothing the request and the command are the same line and there is nothing to fill
	var asked_values := trace.requested()
	var lost_share := 0
	for index : int in asked_values.size():
		var asked : float = absf(asked_values[index])
		if asked < 0.001: continue
		lost_share = maxi(lost_share, roundi((asked - absf(trace.command[index])) / asked * 100.0))
	
	%ResponseResult.text = "%s step at %.0f m/s, %.0f m: demand %.1f deg/s, peak %.1f deg/s, load %.1f g, limiters took up to %d%%" % [
		trace.axis.capitalize(), trace.speed, trace.altitude, rad_to_deg(trace.commanded_rate[trace.commanded_rate.size() - 1]),
		rad_to_deg(peak), trace.load[trace.load.size() - 1], lost_share]

#the parts the command was built from, on the log time axis the breakdown is read on: the request, what each part adds to it, the
#command they add up to, the command the surfaces were given, and the rate the aircraft reached, with the gap between the request
#and that rate filled. drawn into whichever graph is handed in, so the row at different pressures and the one chart at the chosen
#speed are the same chart
func draw_breakdown(graph : AeroGraph, trace : ControlResponse.Trace) -> void:
	#the breakdown runs on a log time axis: the early tenths keep more room than a linear axis gives them, while the last seconds keep
	#a share of their own, so the step and the settle can be read on one chart. the offset keeps the first frame from taking half the
	#chart, and the axis label says what the scale is
	var log_times := response_log_times(trace)
	
	#the assist's answer to the request, drawn in the units the request is made in. the rate a command stands for is read through the
	#assist's own calibration: the rate the request asks for divided by the feed-forward command meant to produce it, which takes the
	#airspeed and the air density out of the numbers. feed-forward's line is therefore the requested rate, and each part is that rate
	#plus what the part adds to it, so the parts are read side by side rather than piled on each other
	var requested_rates := degrees(trace.commanded_rate)
	var gains := PackedFloat32Array()
	for index : int in requested_rates.size():
		var feed_forward : float = trace.feed_forward[index]
		gains.append(1.0 if absf(feed_forward) < 0.0001 else requested_rates[index] / feed_forward)
	
	var requested_line : AeroGraph.CurveData = graph.add_curve(trace_points(log_times, requested_rates, 1),
		Color(1, 1, 1, 0.35), "Requested")
	add_command_part(graph, log_times, requested_rates, gains, trace.proportional, CURVE_COLORS[0], "+P")
	add_command_part(graph, log_times, requested_rates, gains, trace.integral, CURVE_COLORS[2], "+I")
	add_command_part(graph, log_times, requested_rates, gains, trace.derivative, CURVE_COLORS[3], "+D")
	
	#the command every part adds up to and the command the surfaces were given, both read in the same rate: where the two come apart,
	#the limiters are taking something
	var commands := PackedFloat32Array()
	var delivered := PackedFloat32Array()
	for index : int in requested_rates.size():
		commands.append(requested_rates[index] + (trace.proportional[index] + trace.integral[index] + trace.derivative[index]) * gains[index])
		delivered.append(trace.command[index] * gains[index])
	
	var ask : AeroGraph.CurveData = graph.add_curve(trace_points(log_times, commands, 1),
		Color(CURVE_COLORS[4], 0.8), "Command")
	var given : AeroGraph.CurveData = graph.add_curve(trace_points(log_times, delivered, 1),
		Color(1, 1, 1, 0.85), "Delivered")
	given.width = 2.0
	
	#the error the chart is read for: the gap between the rate that was asked for and the rate the aircraft reached, red while
	#the aircraft is short of the request and green once it is over it
	var achieved : AeroGraph.CurveData = graph.add_curve(trace_points(log_times, degrees(trace.achieved_rate), 1),
		CURVE_COLORS[1], "Achieved", PackedFloat32Array(), 2.0)
	achieved.fill_to = requested_line
	achieved.fill_color = Color(CURVE_COLORS[0], 0.4)
	achieved.fill_above_color = Color(CURVE_COLORS[1], 0.4)

#the altitude tab: how the numbers that change with height come out, one chart per number
func draw_altitude_sweep(sweep : Dictionary) -> void:
	draw_altitude_curve(%SpeedAltitudeGraph, sweep.get("speed", PackedVector2Array()))
	draw_altitude_curve(%ClimbAltitudeGraph, sweep.get("climb", PackedVector2Array()))
	draw_altitude_curve(%TurnRateAltitudeGraph, sweep.get("turn_rate", PackedVector2Array()))
	draw_altitude_curve(%SustainedAltitudeGraph, sweep.get("sustained", PackedVector2Array()))
	draw_altitude_curve(%LoadAltitudeGraph, sweep.get("load", PackedVector2Array()))
	draw_altitude_curve(%RadiusAltitudeGraph, sweep.get("radius", PackedVector2Array()))
	
	#the height the aircraft stops climbing at is ruled across the climb chart, where the curve runs out of rate to climb with
	var climb : PackedVector2Array = sweep.get("climb", PackedVector2Array())
	%ClimbAltitudeGraph.clear_rules()
	%ClimbAltitudeGraph.clear_labels()
	if climb.is_empty(): return
	
	var ceiling : float = sweep.get("ceiling", NAN)
	var shown : Rect2 = %ClimbAltitudeGraph.visible_bounds()
	
	#if it is still climbing at the top of the sweep it reaches higher than the tab goes, which is said rather than left out
	if is_nan(ceiling):
		%ClimbAltitudeGraph.add_label("Ceiling above %d m" % roundi(climb[climb.size() - 1].y), Vector2(shown.end.x, shown.end.y), Vector2(1.0, 0.0), HORIZONTAL_ALIGNMENT_RIGHT)
		return
	
	%ClimbAltitudeGraph.add_y_rule(ceiling, boundary_rule_color)
	%ClimbAltitudeGraph.add_label("Ceiling %d m" % roundi(ceiling), Vector2(shown.end.x, ceiling), Vector2(1.0, 0.0), HORIZONTAL_ALIGNMENT_RIGHT)

#one number drawn against altitude
func draw_altitude_curve(graph : AeroGraph, points : PackedVector2Array) -> void:
	graph.clear_curves()
	graph.add_curve(points, CURVE_COLORS[1], graph.title)

#the numbers under the chart, blank until the sweep says otherwise
func update_turn_metrics(metrics : Dictionary) -> void:
	blank_labels([%CornerValue, %CornerRateValue, %SustainedValue, %SustainedRateValue, %RadiusValue, %TopSpeedValue, %ThrustWeightValue])
	
	var corner : Dictionary = metrics.get("corner", {})
	if not corner.is_empty() and not is_nan(corner.speed):
		%CornerValue.text = "M %.2f, %.0f m/s, %.1f g" % [corner.mach, corner.speed, corner.load]
		%CornerRateValue.text = "%.1f deg/s" % corner.rate
	
	var sustained : Dictionary = metrics.get("sustained", {})
	if not sustained.is_empty() and not is_nan(sustained.speed):
		%SustainedValue.text = "M %.2f, %.0f m/s, %.1f g" % [sustained.mach, sustained.speed, sustained.load]
		%SustainedRateValue.text = "%.1f deg/s" % sustained.rate
	var tightest : Dictionary = metrics.get("tightest", {})
	if not tightest.is_empty() and not is_nan(tightest.meters):
		%RadiusValue.text = "%.0f m, M %.2f" % [tightest.meters, tightest.mach]
	var top : Dictionary = metrics.get("top", {})
	if not top.is_empty() and not is_nan(top.speed):
		%TopSpeedValue.text = "M %.2f, %.0f m/s" % [top.mach, top.speed]
	
	var thrust_to_weight : float = metrics.get("thrust_to_weight", NAN)
	if not is_nan(thrust_to_weight):
		%ThrustWeightValue.text = "%.2f" % thrust_to_weight

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

#signal handlers

func _on_recalculate_button_pressed() -> void:
	#the button is the way to fly a sweep again once the dock can no longer tell its results are out of date, which is
	#what happens when a script is reloaded under it: the tab being looked at is marked stale and flown as it is
	match %Tabs.current_tab:
		STATIC_TAB: static_stale = true
		PERFORMANCE_TAB: turn_performance_stale = true
		ALTITUDE_TAB: altitude_stale = true
	queue_recalculate()

func _on_testing_speed_value_changed(value : float) -> void:
	test_speed = value

func _on_sweep_datapoints_value_changed(value : float) -> void:
	sweep_datapoints = int(value)

func _on_altitude_value_changed(value : float) -> void:
	altitude = value

func _on_altitude_steps_value_changed(value : float) -> void:
	altitude_steps = int(value)

func _on_altitude_samples_value_changed(value : float) -> void:
	altitude_datapoints = int(value)

func _on_load_limit_value_changed(value : float) -> void:
	load_limit = value

func _on_turn_datapoints_value_changed(value : float) -> void:
	turn_datapoints = int(value)




#utils: the arithmetic the drawing is read with. none of it knows anything of this dock or of a graph node, and it is here
#rather than beside the drawing that reaches for it because more than one of those drawings does

#every field of a readout blank, until the numbers it is read off say otherwise
func blank_labels(labels : Array[Label]) -> void:
	for label : Label in labels: label.text = NO_DATA

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
	var x := label_position(curve, fraction)
	for index : int in curve.size() - 1:
		var span := curve[index + 1].x - curve[index].x
		if is_zero_approx(span): continue
		
		var along := (x - curve[index].x) / span
		if along < 0.0 or along > 1.0: continue
		
		return curve[index].lerp(curve[index + 1], along)
	
	return curve[curve.size() - 1]

#the x a curve is asked to carry its name at, taken at this share of its run
func label_position(curve : PackedVector2Array, fraction : float) -> float:
	if curve.size() < 2: return 0.0
	return lerpf(curve[0].x, curve[curve.size() - 1].x, fraction)

#a step rounded to the nearest 1, 2 or 5 times a power of ten, so an axis built from it is numbered with round figures
func nearest_round_step(raw_step : float) -> float:
	if raw_step <= 0.0: return 1.0
	
	var magnitude := pow(10.0, floorf(log(raw_step) / log(10.0)))
	var best := magnitude
	for candidate : float in [magnitude, magnitude * 2.0, magnitude * 5.0, magnitude * 10.0]:
		if absf(candidate - raw_step) < absf(best - raw_step): best = candidate
	
	return best
