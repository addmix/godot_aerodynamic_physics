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
	visibility_changed.connect(queue_recalculate)
	
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

#whether a part is carried by something that turns, which places it itself, so the copy leaves it where it was put
func is_turned_part(influencer : AeroInfluencer3D) -> bool:
	var node : Node = influencer.get_parent()
	while node and node != worker_copy:
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
	%TurnMetrics.columns = 4 if size.x >= turn_metrics_row_width else 2
	
	#the turn chart takes its share of the dock's height, so the grid under it is what scrolls rather than the chart shrinking with it
	%TurnPerformanceGraph.custom_minimum_size.y = size.y * turn_chart_height_share
	
	#every chart in the grids is the same height as every other, that height following the dock, and the same width as every
	#other, which is what the dock is never dragged below
	var graph_height : float = clampf(size.y * graph_height_share, graph_height_floor, graph_height_ceiling)
	var graph_width : float = minimum_graph_width()
	for grid : GridContainer in [%GraphGrid, %AltitudeGrid, %PerformanceGrid]:
		for child : Node in grid.get_children():
			if child is AeroGraph: child.custom_minimum_size = Vector2(graph_width, graph_height)

#the width a graph is squeezed to before there is nothing left to read on it
func minimum_graph_width() -> float:
	return get_theme_default_font_size() * graph_minimum_width_lines


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
	if not sweep_static and not sweep_turn and not sweep_altitude: return
	
	#a sweep already in flight is left to finish rather than interrupted, and flown again as soon as it lands
	if worker_task != -1:
		worker_dirty = true
		return
	
	start_sweeps(sweep_static, sweep_turn, sweep_altitude)

#deep-copies the aircraft for the worker to fly, so the sweeps never touch the nodes being edited. the copy goes into a
#viewport of its own, so it enters a tree and initializes like any aircraft, and is then taken out of the frame's way: it does
#not process, show or collide with anything
func start_sweeps(sweep_static : bool, sweep_turn : bool, sweep_altitude : bool) -> void:
	#what the sweeps are about to fly is kept, so an undo or a redo can be told apart from one that changed nothing
	swept_model = flight_model_fingerprint()
	
	#the copy has to keep its script instances: a deep duplicate would instantiate them and the copied nodes would come out
	#without their behavior
	worker_copy = aerobody.duplicate()
	#the sweeps fly the copy at the attitude they are given, so it is put at the origin facing forward before it enters the tree,
	#and every part of it is put back to the pose it was authored with: a control surface's node is written to as it deflects and
	#a turning part's as it turns, so a copy of an aircraft that has been flying would take those poses for neutral ones and the
	#same aircraft would chart slightly differently every time it was swept
	worker_copy.transform = Transform3D()
	for node : Node in worker_copy.find_children("*", "AeroInfluencer3D", true, false):
		var influencer := node as AeroInfluencer3D
		if influencer.actuation_config == null or is_turned_part(influencer): continue
		influencer.transform = influencer.default_transform
	worker_copy.linear_velocity = Vector3.ZERO
	worker_copy.angular_velocity = Vector3.ZERO
	worker_copy.process_mode = Node.PROCESS_MODE_DISABLED
	worker_copy.visible = false
	worker_copy.collision_layer = 0
	worker_copy.collision_mask = 0
	simulation_view.add_child(worker_copy)
	
	#the nodes the sweeps reach into are gathered here, on the main thread: a thread may not search the scene itself. the
	#thrusters are the influencers that also carry a throttle, so the one search covers both
	var influencers : Array[AeroInfluencer3D] = []
	var thrusters : Array[AeroThruster3D] = []
	for node : Node in worker_copy.find_children("*", "AeroInfluencer3D", true, false):
		var influencer := node as AeroInfluencer3D
		influencers.append(influencer)
		if influencer is AeroThruster3D: thrusters.append(influencer)
	
	#the copy takes its own copy of everything a sweep drives. the editor leaves these resources shared with the aircraft in the
	#scene, so a sweep opening the throttle would be flying the aircraft being edited as well, and its preview would hand the change
	#back as an edit of the model, which starts the sweep over again
	for node : Node in worker_copy.find_children("*", "AeroControlComponent", true, false):
		var component := node as AeroControlComponent
		if component.control_config: component.control_config = component.control_config.duplicate(true)
		if component.flight_assist: component.flight_assist = component.flight_assist.duplicate(true)
	
	for influencer : AeroInfluencer3D in influencers:
		if influencer.actuation_config:
			influencer.actuation_config = influencer.actuation_config.duplicate(true)
		if influencer is AeroThruster3D and influencer.throttle_control_config:
			influencer.throttle_control_config = influencer.throttle_control_config.duplicate(true)
		if influencer is AeroPropeller3D and influencer.propeller_speed_control_config:
			influencer.propeller_speed_control_config = influencer.propeller_speed_control_config.duplicate(true)
		if influencer is AeroCyclicPropeller3D and influencer.cyclic_control_config:
			influencer.cyclic_control_config = influencer.cyclic_control_config.duplicate(true)
	
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
	worker_sweeps.density = density_at(altitude)
	worker_sweeps.pressure = pressure_at(altitude)
	worker_sweeps.sound_speed = sound_speed_at(altitude)
	worker_sweeps.load_limit = load_limit
	worker_sweeps.turn_datapoints = turn_datapoints
	worker_sweeps.altitude_datapoints = altitude_datapoints
	
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
	worker_runs_static = sweep_static
	worker_runs_turn = sweep_turn
	worker_runs_altitude = sweep_altitude
	worker_results = {}
	worker_task = WorkerThreadPool.add_task(run_sweeps, false, "wind tunnel sweeps")
	busy_since_msec = Time.get_ticks_msec()

#the worker thread: flies the sweeps against the copy and leaves the results where the dock picks them up
func run_sweeps() -> void:
	var results := {}
	if worker_runs_static: results["static"] = worker_sweeps.static_analysis()
	if worker_runs_turn: results["turn"] = worker_sweeps.turn_performance()
	if worker_runs_altitude: results["altitude"] = worker_sweeps.altitude_sweep()
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
	
	if worker_dirty:
		worker_dirty = false
		queue_recalculate()

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
			boundary_rule_color, "", PackedFloat32Array(), true)
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
