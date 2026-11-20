@icon("res://addons/godot_aerodynamic_physics/icons/AeroGraph.svg")
@tool
extends PanelContainer
class_name AeroGraph
##Draws a set of curves on a fitted grid, with tick labels, axis titles and a legend.

#which side of the plot a band of labels sits on: before it, on the axis itself, or after it
enum Placement { BEFORE, ON_AXIS, AFTER }
#where a plate of text sits: in a corner of the plot, or in a band above it that the plot leaves room for
enum PlatePlacement { TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT, ABOVE }
#which axis the readout follows the cursor along: the x axis, reporting each curve's y, or the y axis, reporting its x
enum ReadoutAxis { X, Y }
#what the readout reports: every curve crossing the cursor's line, or the curve passing closest to the cursor itself
enum ReadoutMode { CROSSHAIR, NEAREST_POINT }


#TODO:
#display curves as points
#dashed/dotted curve display
#curve downsampling
#default curve colors


@export_group("Features")
##Draws the legend plate, which names the curves that have an entry in names.
@export var show_legend : bool = true:
	set(x):
		show_legend = x; queue_redraw()
##Draws the readout plate at the cursor, which reports the x under it and the value of every curve there.
@export var show_readout : bool = true:
	set(x):
		show_readout = x; queue_redraw()
##Marks the cursor's position with a line through the plot.
@export var show_crosshair : bool = true:
	set(x):
		show_crosshair = x; queue_redraw()
##Writes the cursor's coordinates at the ends of its crosshair, inside the plot.
@export var show_crosshair_values : bool = false:
	set(x):
		show_crosshair_values = x; queue_redraw()
##Marks where each curve crosses either axis.
@export var show_axis_crossings : bool = true:
	set(x):
		show_axis_crossings = x; queue_redraw()
##Marks where each curve turns around, so its peaks and troughs.
@export var show_curve_extrema : bool = true:
	set(x):
		show_curve_extrema = x; queue_redraw()
##Marks where two curves cross each other.
@export var show_curve_intersections : bool = true:
	set(x):
		show_curve_intersections = x; queue_redraw()
##Marks where a curve crosses itself, which a curve that doubles back on itself does.
@export var show_curve_self_intersections : bool = true:
	set(x):
		show_curve_self_intersections = x; queue_redraw()
##Draws the two zero lines over the grid, only while zero is inside the plot.
@export var show_zero_lines : bool = true:
	set(x):
		show_zero_lines = x; queue_redraw()

@export_group("Readout")
##Which axis the readout follows the cursor along: each curve is read where the cursor sits on that axis.
@export var readout_axis : ReadoutAxis = ReadoutAxis.X:
	set(x):
		readout_axis = x; queue_redraw()
##What the readout reports: every curve crossing the cursor's line, or only the curve passing closest to the cursor.
@export var readout_mode : ReadoutMode = ReadoutMode.CROSSHAIR:
	set(x):
		readout_mode = x; queue_redraw()
##How close the cursor has to come to a curve for NEAREST_POINT to report it.
@export var nearest_point_reach := 24.0:
	set(x):
		nearest_point_reach = x; queue_redraw()
##Steps an open plate across the plot when the cursor is sitting on it, so it never covers the value being looked at.
@export var plates_dodge_cursor : bool = true:
	set(x):
		plates_dodge_cursor = x; queue_redraw()
##Steps the readout across the plot when the marker readout is showing in its corner, so the two don't cover each other.
@export var readout_dodges_markers : bool = true:
	set(x):
		readout_dodges_markers = x; queue_redraw()

@export_group("Axes")
##Fit the x axis to the data, rather than to the bounds set below.
@export var auto_bounds_x : bool = true:
	set(x):
		auto_bounds_x = x; queue_redraw()
##Fit the y axis to the data, rather than to the bounds set below.
@export var auto_bounds_y : bool = true:
	set(x):
		auto_bounds_y = x; queue_redraw()
##Keep zero on the y axis when it is fitted to the data, for a chart whose values never run below it.
@export var auto_bounds_keep_zero_y : bool = false:
	set(x):
		auto_bounds_keep_zero_y = x; queue_redraw()
##Pull the x axis symmetric around zero, so zero sits in the middle of the plot whatever the data reaches.
@export var center_x_on_zero : bool = false:
	set(x):
		center_x_on_zero = x; queue_redraw()
##Pull the y axis symmetric around zero, for graphs where the sign of a value matters.
@export var center_y_on_zero : bool = false:
	set(x):
		center_y_on_zero = x; queue_redraw()
##Bounds used by an axis that is not fitted to the data, one component per axis.
@export var lower_bound := Vector2(-180, -180):
	set(x):
		lower_bound = x; queue_redraw()
@export var upper_bound := Vector2(180, 180):
	set(x):
		upper_bound = x; queue_redraw()
##Divisions each axis is fitted into, which is also how many gridlines are drawn across it.
@export var axis_divisions := Vector2i(8, 8):
	set(x):
		axis_divisions = x; queue_redraw()

@export_group("Text")
##Text drawn above the plot. Leave it empty for no title row.
@export var title : String = "":
	set(x):
		title = x; queue_redraw()
##Name written below the plot.
@export var x_label : String = "":
	set(x):
		x_label = x; queue_redraw()
##Name written beside the plot.
@export var y_label : String = "":
	set(x):
		y_label = x; queue_redraw()
##Heading for the parameter column of the readout.
@export var parameter_label : String = "":
	set(x):
		parameter_label = x; queue_redraw()

@export_group("Placement")
##Where the numbers of the x axis are written: BEFORE is under the plot, AFTER is over it, or ON_AXIS along the zero
##line, which takes no room of its own.
@export var x_tick_label_placement : Placement = Placement.BEFORE:
	set(x):
		x_tick_label_placement = x; queue_redraw()
##Where the numbers of the y axis are written: BEFORE is left of the plot, AFTER is right of it, or ON_AXIS along the
##zero line, which takes no room of its own.
@export var y_tick_label_placement : Placement = Placement.BEFORE:
	set(x):
		y_tick_label_placement = x; queue_redraw()
##Where the name of the x axis is written. ON_AXIS writes it inside the plot along the zero line.
@export var x_label_placement : Placement = Placement.BEFORE:
	set(x):
		x_label_placement = x; queue_redraw()
##Where the name of the y axis is written. ON_AXIS writes it inside the plot along the zero line.
@export var y_label_placement : Placement = Placement.BEFORE:
	set(x):
		y_label_placement = x; queue_redraw()
##Where the legend is drawn: a corner of the plot, or a band above it, where it never covers the curves.
@export var legend_placement : PlatePlacement = PlatePlacement.TOP_LEFT:
	set(x):
		legend_placement = x; queue_redraw()
##Where the readout is drawn: a corner of the plot, or a band above it, where it never covers the curves.
@export var readout_placement : PlatePlacement = PlatePlacement.BOTTOM_RIGHT:
	set(x):
		readout_placement = x; queue_redraw()

@export_group("Visuals")
@export_subgroup("Layout")
##Lays the legend out in a line instead of in a column.
@export var legend_horizontal : bool = false:
	set(x):
		legend_horizontal = x; queue_redraw()
##Lays the readout out in a line instead of in a column.
@export var readout_horizontal : bool = false:
	set(x):
		readout_horizontal = x; queue_redraw()
##Lays the marker readout out in a line instead of in a column.
@export var marker_readout_horizontal : bool = false:
	set(x):
		marker_readout_horizontal = x; queue_redraw()

@export_subgroup("Curves and dots")
##The width of a curve in pixels. Below 1 the curve falls back to a thin line strip, which is never antialiased.
@export_range(0.5, 4.0, 0.5) var curve_width := 1.0:
	set(x):
		curve_width = x; queue_redraw()
##Every dot the graph draws is this big.
@export_range(0.5, 8.0, 0.5) var dot_radius := 2.0:
	set(x):
		dot_radius = x; queue_redraw()
##Smooths the edges of the curves and the dots.
@export var antialiased : bool = true:
	set(x):
		antialiased = x; queue_redraw()

@export_subgroup("Zero lines")
##The width the zero lines are drawn at, wide enough to read as an axis rather than as a grid line.
@export_range(1.0, 4.0, 0.5) var zero_line_width := 2.0:
	set(x):
		zero_line_width = x; queue_redraw()
##The color the zero lines are drawn in.
@export var zero_line_color := Color(1.0, 1.0, 1.0, 0.3):
	set(x):
		zero_line_color = x; queue_redraw()


#theme
#the font and the size the theme draws with, taken from it in _ready so the labels read like the text around them
var font : Font:
	get:
		return get_theme_default_font()
var font_size : int:
	get:
		return get_theme_default_font_size()

#the color the theme writes text in, which is what the labels are drawn with
var text_color : Color:
	get: return get_theme_color("font_color", "Label")


#curve data
#each curve carries its samples, its color, its legend entry, the value each sample was taken at, and which of its axes
#are normalized. the list order is the drawing order and the legend order. curves are built from a script rather than
#from the inspector, because godot cannot save an inner class into a scene
class CurveData:
	var points := PackedVector2Array()
	var color := Color.WHITE
	##The width this curve is drawn at. Left at 0 it is drawn at the graph's curve_width.
	var width := 0.0
	##The legend entry. a curve with no name is drawn but not listed.
	var legend_name : String = ""
	##The value each sample was taken at, reported by the readout beside the value. It holds one value per sample or is
	##left out.
	var parameters := PackedFloat32Array()
	##Draw the samples against 0..1 on this axis instead of against the axis scale, so the curve spans the plot.
	var normalize_x := false
	var normalize_y := false
	
	#what the samples span, as a rect holding the lowest and the highest of each axis
	func reach() -> Rect2:
		var span := Rect2(points[0], Vector2.ZERO)
		for index : int in range(1, points.size()):
			span = span.expand(points[index])
		return span

var curves : Array[CurveData] = []

#adds a curve of these points in this color, under this legend entry, and hands it back so anything else can be set on it.
#the points can be an Array of Vector2 or Vector2i, typed or not, or a PackedVector2Array
func add_curve(points : Variant, color : Color, legend_name : String = "", parameters : PackedFloat32Array = PackedFloat32Array(), redraw : bool = true) -> CurveData:
	var curve := CurveData.new()
	curve.points = to_packed_points(points)
	curve.color = color
	curve.legend_name = legend_name
	curve.parameters = parameters
	curves.append(curve)
	if redraw: queue_redraw()
	return curve

#the record one curve is drawn from: the arguments add_curve() takes, gathered up so a list of curves can be passed around
static func create_curve(points : Variant, color : Color, name : String, parameters : PackedFloat32Array = PackedFloat32Array()) -> Dictionary:
	return {"points": points, "color": color, "name": name, "parameters": parameters}

#adds every curve of the array, each as add_curve() takes it, and redraws once for the lot
func add_curves(definitions : Array, redraw : bool = true) -> void:
	for definition : Dictionary in definitions:
		add_curve(definition.points, definition.color, definition.name, definition.parameters, false)
	
	if redraw: queue_redraw()

#adds a sample to the end of a curve and redraws, for data that arrives a point at a time
func append_sample(curve : CurveData, point : Vector2) -> void:
	curve.points.append(point)
	queue_redraw()

#moves a curve to another place in the list, which is also where it sits in the legend
func move_curve(curve : CurveData, index : int) -> void:
	var from := curves.find(curve)
	if from < 0: return
	var to := clampi(index, 0, curves.size() - 1)
	if from == to: return
	curves.remove_at(from)
	curves.insert(to, curve)
	queue_redraw()

#removes a curve, and its samples with it
func remove_curve(curve : CurveData) -> void:
	if curve == null: return
	curves.erase(curve)
	queue_redraw()

#removes every curve
func clear_curves() -> void:
	curves.clear()
	queue_redraw()

#words written in the plot that name a family of curves rather than one of them. each holds its point and the run it
#follows in the values the curves are drawn in, so a word follows the line it names however the axes are scaled
var labels : Array[Dictionary] = []
#rules drawn down the plot at a value on the x axis, which mark where something changes without taking part in the axis bounds
var x_rules : Array[Dictionary] = []

#a dot of the caller's own, given in the same values the curves are drawn at, listed under a kind and read out with the
#words it is given
func add_marker(value : Vector2, kind : String, text : String, color : Color) -> void:
	marked_points.append({"value": value, "kind": kind, "text": text, "color": color})
	cached_marker_key = []
	queue_redraw()

#takes the caller's dots off the chart, which is what a drawing of fresh data starts with
func clear_markers() -> void:
	marked_points.clear()
	cached_marker_key = []
	queue_redraw()

#writes a word in the plot at a point, turned to follow the run the direction gives, both in the values the curves are drawn
#in. `align` puts the word beside the point instead of across it, and `clear` stands it that many pixels further off its run
func add_label(text : String, position : Vector2, direction : Vector2, align : HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER, clear : float = 0.0) -> void:
	labels.append({"text": text, "position": position, "direction": direction, "align": align, "clear": clear})
	queue_redraw()

func add_x_rule(value : float, color : Color, width := 1.0) -> void:
	x_rules.append({"value": value, "color": color, "width": width})
	queue_redraw()

#takes the rules off the chart
func clear_rules() -> void:
	if x_rules.is_empty(): return
	
	x_rules.clear()
	queue_redraw()

#a marked range on one axis, and a marked rectangle, kept as the values they were given
enum Axis { X, Y }

class Span:
	var axis := 0
	var from := 0.0
	var to := 0.0
	var color := Color.WHITE
	var fill_color := Color(0.0, 0.0, 0.0, 0.0)
	var fill := true

class Area:
	var rect := Rect2()
	var color := Color.WHITE
	var fill_color := Color(0.0, 0.0, 0.0, 0.0)
	var fill := true

var spans : Array[Span] = []
var areas : Array[Area] = []
#how much of the line color a region's wash is made of when no fill color of its own is given
var region_fill_alpha := 0.12
#the weight the two lines of a span are drawn at
var span_line_width := 1.0

#a range on one axis: the two lines at its ends and a wash between them. the wash is the line color faded unless a fill color
#is given, and it is left out when `draw_fill` is false
func add_span(axis : Axis, from : float, to : float, color : Color, fill_color := Color(0, 0, 0, 0), draw_fill := true) -> void:
	var span := Span.new()
	span.axis = axis
	span.from = minf(from, to)
	span.to = maxf(from, to)
	span.color = color
	span.fill_color = fill_color if fill_color.a > 0.0 else Color(color, region_fill_alpha)
	span.fill = draw_fill
	spans.append(span)
	queue_redraw()

#a rectangle in the values the curves are drawn in, filled and outlined the same way a span is
func add_area(rect : Rect2, color : Color, fill_color := Color(0, 0, 0, 0), draw_fill := true) -> void:
	var area := Area.new()
	area.rect = rect.abs()
	area.color = color
	area.fill_color = fill_color if fill_color.a > 0.0 else Color(color, region_fill_alpha)
	area.fill = draw_fill
	areas.append(area)
	queue_redraw()

#takes the marked ranges and areas off the chart
func clear_regions() -> void:
	spans.clear()
	areas.clear()
	queue_redraw()

#writes a word along a curve at a value on its own x axis, following the curve there and keeping clear of it
func add_curve_label(curve : CurveData, text : String, position : float, align : HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER, clear : float = 0.0) -> void:
	var anchor := curve_label_anchor(curve, position)
	if anchor.is_empty(): return
	add_label(text, anchor.point, anchor.direction, align, clear)

#takes those words away again
func clear_labels() -> void:
	if labels.is_empty(): return
	labels.clear()
	queue_redraw()




#virtuals
func _gui_input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		hover_position = (event as InputEventMouseMotion).position

func _notification(what : int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		hover_position = Vector2(-1.0, -1.0)
	elif what == NOTIFICATION_THEME_CHANGED or what == NOTIFICATION_RESIZED:
		queue_redraw()

#the plot: the axes, the curves and everything on top of them, in the order they are layered
func _draw() -> void:
	#the y axis is fitted first, because its tick labels set the width of the column the plot starts after
	var bounds := calculate_bounds()
	var y_axis_fit := calculate_axis_fit(bounds.y_lower_bound, bounds.y_upper_bound, axis_divisions.y, auto_bounds_y and not is_view_assigned())
	
	#the frame is drawn outside-in: every band around the plot is drawn where it goes, and the plot is whatever of the
	#panel the bands leave
	var frame := build_frame(bounds, y_axis_fit)
	var plot : Rect2 = frame.plot
	var x_axis_fit : AxisFit = frame.x_axis_fit
	#where the zero lines land, which is where an on-axis band hangs its labels
	var axis_cross := map_value_to_plot(Vector2.ZERO, plot, x_axis_fit, y_axis_fit, false, false).clamp(plot.position, plot.end)
	
	#a plot narrower than its own tick labels has nothing left to draw in
	var smallest_plot_side := spacing(10.0)
	if plot.size.x <= smallest_plot_side or plot.size.y <= smallest_plot_side: return
	
	draw_grid(plot, axis_cross, x_axis_fit, y_axis_fit)
	draw_regions(plot, x_axis_fit, y_axis_fit)
	draw_rules(plot, x_axis_fit)
	draw_curves(plot, x_axis_fit, y_axis_fit)
	draw_markers(plot, x_axis_fit, y_axis_fit)
	draw_labels(plot, x_axis_fit, y_axis_fit)
	draw_axis_names(plot, axis_cross)
	draw_cursor(plot, x_axis_fit, y_axis_fit, frame.readout_band)
	if show_legend: draw_legend(plot, frame.legend_band)


#layout
#the room the bands around the plot take, in pixels at the reference size, scaled by spacing()
#air between the plot and the panel edge, and between the plot and everything drawn around it
var panel_margin := 4.0
var title_gap := 2.0
#space above the title, on top of the panel margin
var title_margin := 0.0
#how far the name rows are trimmed off a whole line box: x for the x name, y for the rotated y name
var label_trim := Vector2(8.0, 10.0)
#how far the tick rows are trimmed off a whole line box, one component per axis
var tick_trim := Vector2(2.0, 2.0)
#how far the tick numbers are nudged toward the plot, so the rows of numbers hug it, one component per axis
var tick_label_nudge := Vector2(2.0, 2.0)
#how far the rotated y name sits in from the panel edge, and how far the x name sits from its tick labels
var y_label_inset := 5.0
var x_label_nudge := 7.0
#the air either side of a tick label, including between a label written on an axis and the line it sits against
var tick_label_padding := 2.0

#the frame around the plot: every band it holds — the title, the bands the plates above the plot sit in, the tick rows
#and the axis names — is measured here in one pass and drawn here in one pass, so the plot is the room they leave and
#no band is measured twice. it hands back the plot that is left, the x axis fit the tick row was drawn from, and the
#bands the plates above the plot go in
func build_frame(bounds : Dictionary, y_axis_fit : AxisFit) -> Dictionary:
	var ascent := font.get_ascent(font_size)
	var descent := font.get_descent(font_size)
	var line_height := ascent + descent
	var frame := Rect2(Vector2.ZERO, get_rect().size).grow(-spacing(panel_margin))
	var panel_top := frame.position.y
	
	#the bands beside the plot are measured first, because the tick row along the bottom is fitted to the width they
	#leave: the tick column, and the rotated name beyond it
	var left_bands := 0.0
	var right_bands := 0.0
	if y_tick_label_placement == Placement.BEFORE: left_bands += y_axis_fit.tick_width + spacing(tick_label_padding)
	elif y_tick_label_placement == Placement.AFTER: right_bands += y_axis_fit.tick_width + spacing(tick_label_padding)
	
	#the rotated name needs room for its glyphs, and for an ascent when the tick labels sit on the axis instead of
	#holding the plot off the panel edge
	var y_name_height : float = line_height - spacing(label_trim.y)
	if y_tick_label_placement == Placement.ON_AXIS: y_name_height = maxf(y_name_height, ascent)
	if y_label != "" and y_label_placement == Placement.BEFORE: left_bands += spacing(y_label_inset) + y_name_height
	elif y_label != "" and y_label_placement == Placement.AFTER: right_bands += spacing(y_label_inset) + y_name_height
	
	var x_axis_fit := calculate_axis_fit(bounds.x_lower_bound, bounds.x_upper_bound, axis_divisions.x, auto_bounds_x and not is_view_assigned(), frame.size.x - left_bands - right_bands)
	
	#the rows above and below the plot: the tick row on whichever side it was asked for, and the name row on whichever
	#side that was asked for, pulled up beside its numbers when the two share a side. the tick row is a trimmed line box
	#tall and not there at all when its labels sit on the axis; the name row is a whole line over the plot and a trimmed
	#one under it
	var x_tick_row_height := 0.0 if x_tick_label_placement == Placement.ON_AXIS else line_height - spacing(tick_trim.x)
	var x_name_row_height := line_height if x_label_placement == Placement.AFTER else line_height - spacing(label_trim.x)
	var x_name_gap := spacing(panel_margin)
	if x_tick_label_placement == x_label_placement and x_tick_label_placement != Placement.ON_AXIS:
		x_name_gap = -spacing(x_label_nudge)
	
	var top_rows := 0.0
	var bottom_rows := 0.0
	if x_tick_label_placement == Placement.AFTER: top_rows += x_tick_row_height
	elif x_tick_label_placement == Placement.BEFORE: bottom_rows += x_tick_row_height
	if x_label != "" and x_label_placement == Placement.AFTER: top_rows += x_name_row_height + maxf(x_name_gap, 0.0)
	elif x_label != "" and x_label_placement == Placement.BEFORE: bottom_rows += x_name_row_height + maxf(x_name_gap, 0.0)
	
	#the title takes the top of the frame, above the plot's own side of it
	if title != "":
		frame = frame.grow_side(SIDE_TOP, -(spacing(title_margin) + line_height + spacing(title_gap)))
	
	#the bands the plates above the plot are drawn into: the legend nearest the title, the readout nearest the plot.
	#both are reserved whether the plates are showing or not, so the plot does not change size as the cursor comes and goes
	var legend_band := Rect2()
	var readout_band := Rect2()
	if legend_is_above():
		legend_band = Rect2(frame.position, Vector2(frame.size.x, plate_band_height()))
		frame = frame.grow_side(SIDE_TOP, -plate_band_height())
	if readout_is_above():
		readout_band = Rect2(frame.position, Vector2(frame.size.x, plate_band_height()))
		frame = frame.grow_side(SIDE_TOP, -plate_band_height())
	
	#the plot: the frame less every band measured around it
	var plot := Rect2(
		Vector2(frame.position.x + left_bands, frame.position.y - top_rows),
		Vector2(frame.size.x - left_bands - right_bands, frame.size.y - top_rows - bottom_rows)
	)
	
	#the chrome, drawn outside-in: the title at the panel's top, then the rows and the names against the plot's edges
	if title != "":
		draw_string(font, Vector2(frame.position.x + left_bands, panel_top + spacing(title_margin) + ascent), title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
	draw_x_tick_row(x_axis_fit, plot)
	draw_x_name(plot, x_tick_row_height, x_name_gap)
	draw_y_tick_column(y_axis_fit, plot)
	draw_y_axis_name(frame, plot)
	
	return {"plot": plot, "x_axis_fit": x_axis_fit, "legend_band": legend_band, "readout_band": readout_band}

#the tick row along the x axis, drawn against whichever edge of the plot its labels were asked for. the end labels
#are aligned on the plot's corners instead of centered, so the row can run to the panel edge
func draw_x_tick_row(x_axis_fit : AxisFit, plot : Rect2) -> void:
	if x_tick_label_placement == Placement.ON_AXIS: return
	
	var baseline := plot.end.y + font.get_ascent(font_size) - spacing(tick_label_nudge.x)
	if x_tick_label_placement == Placement.AFTER: baseline = plot.position.y - spacing(tick_label_nudge.x)
	
	for index : int in x_axis_fit.tick_values.size():
		var tick_label : String = x_axis_fit.labels[index]
		var label_width := measure_text_width(tick_label)
		var x := plot.position.x + plot.size.x * axis_fraction(x_axis_fit, x_axis_fit.tick_values[index])
		
		#a label is centered on its own tick, and pulled inside the plot at either edge so the first and last still read
		var label_left := clampf(x - label_width * 0.5, plot.position.x, plot.end.x - label_width)
		draw_string(font, Vector2(label_left, baseline), tick_label, HORIZONTAL_ALIGNMENT_LEFT, label_width, font_size, text_color)

#the x axis name, drawn beyond its tick row on whichever side of the plot it was asked for
func draw_x_name(plot : Rect2, tick_row_height : float, name_gap : float) -> void:
	if x_label == "" or x_label_placement == Placement.ON_AXIS: return
	
	var ascent := font.get_ascent(font_size)
	var line_height := ascent + font.get_descent(font_size)
	if x_label_placement == Placement.AFTER:
		var top : float = plot.position.y - tick_row_height - name_gap - line_height + ascent
		draw_string(font, Vector2(plot.position.x, top), x_label, HORIZONTAL_ALIGNMENT_CENTER, plot.size.x, font_size, text_color)
	else:
		var bottom : float = plot.end.y + tick_row_height + name_gap + ascent
		draw_string(font, Vector2(plot.position.x, bottom), x_label, HORIZONTAL_ALIGNMENT_CENTER, plot.size.x, font_size, text_color)

#the tick column beside the plot, its labels spread down the plot's height. the outer ones are nudged inside, so the
#first clears the title row and the last clears the x tick row
func draw_y_tick_column(y_axis_fit : AxisFit, plot : Rect2) -> void:
	if y_tick_label_placement == Placement.ON_AXIS: return
	
	#the side the column sits on decides where its labels start and which way they run from there
	var x : float = plot.position.x - y_axis_fit.tick_width
	var align := HORIZONTAL_ALIGNMENT_RIGHT
	if y_tick_label_placement == Placement.AFTER:
		x = plot.end.x + spacing(tick_label_padding)
		align = HORIZONTAL_ALIGNMENT_LEFT
	
	var ascent := font.get_ascent(font_size)
	var descent := font.get_descent(font_size)
	var tick_count := y_axis_fit.tick_values.size()
	for index : int in tick_count:
		#the labels run top down, so the highest value comes first
		var tick_index := tick_count - 1 - index
		var y := plot.position.y + plot.size.y * (1.0 - axis_fraction(y_axis_fit, y_axis_fit.tick_values[tick_index]))
		var tick_label : String = y_axis_fit.labels[tick_index]
		var baseline := y + (ascent - descent) * 0.5
		if index == 0: baseline = y + ascent
		elif index == tick_count - 1: baseline = y - descent
		
		draw_string(font, Vector2(x, baseline), tick_label, align, y_axis_fit.tick_width, font_size, text_color)

#the rotated y axis name, snapped to whole pixels so its glyphs are not resampled half a pixel off and left blurry
func draw_y_axis_name(frame : Rect2, plot : Rect2) -> void:
	if y_label == "" or y_label_placement == Placement.ON_AXIS: return
	
	var ascent := font.get_ascent(font_size)
	var descent := font.get_descent(font_size)
	var name_x : float = frame.position.x + spacing(y_label_inset)
	if y_label_placement == Placement.AFTER: name_x = frame.end.x - spacing(y_label_inset)
	draw_set_transform(Vector2(roundf(name_x), roundf(plot.get_center().y)), -PI * 0.5, Vector2.ONE)
	draw_string(font, Vector2(roundf(-measure_text_width(y_label) * 0.5), roundf((ascent - descent) * 0.5)), y_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


#view
#a view takes the visible range over from what the axes fit to, which is what a zoom or a pan of the graph changes.
#nothing here is wired to the mouse: a script drives these from its own input handling
#the range the view shows. an empty one holds nothing, which is what tells the graph there is no view and its axes fit
#to the data instead
var view := Rect2():
	set(x):
		view = x; queue_redraw()

#whether a view has taken the visible range over from what the axes fit to
func is_view_assigned() -> bool:
	return view.has_area()

#shows this range on both axes instead of the range the axes fit to
func set_view(view_bounds : Rect2) -> void:
	view = view_bounds

#goes back to showing whatever the axes fit to
func clear_view() -> void:
	view = Rect2()

#the range the axes are showing right now, whether that is a view or what they fit to
func visible_bounds() -> Rect2:
	if is_view_assigned(): return view
	
	var bounds := calculate_bounds()
	return Rect2(
		Vector2(bounds.x_lower_bound, bounds.y_lower_bound),
		Vector2(bounds.x_upper_bound - bounds.x_lower_bound, bounds.y_upper_bound - bounds.y_lower_bound)
	)

#scales the visible range about a point given in plot fractions, so (0.5, 0.5) is the middle of the plot and a factor
#under 1 zooms in
func zoom_view(factor : float, focus := Vector2(0.5, 0.5)) -> void:
	if factor <= 0.0: return
	var view_bounds := visible_bounds()
	var focus_point := view_bounds.position + view_bounds.size * focus
	set_view(Rect2(focus_point - (focus_point - view_bounds.position) * factor, view_bounds.size * factor))

#moves the visible range by a fraction of its own width and height, so dragging a tenth of the plot pans a tenth of it
func pan_view(offset := Vector2.ZERO) -> void:
	var view_bounds := visible_bounds()
	set_view(Rect2(view_bounds.position + view_bounds.size * offset, view_bounds.size))


#bounds
#an empty or flat dataset gets opened out to this half span, so the axis always has something to fit
var fallback_axis_span := 1.0

#the bounds each axis is showing: the range a view has taken over, or what the data reaches, or the ones set on the node
func calculate_bounds() -> Dictionary:
	if is_view_assigned():
		return {
			"x_lower_bound": view.position.x,
			"x_upper_bound": view.end.x,
			"y_lower_bound": view.position.y,
			"y_upper_bound": view.end.y,
		}
	
	#what the curves that speak to an axis' scale reach on it, as a lower to upper range per axis. a curve normalized on
	#an axis says nothing about that axis' scale, so it widens the other range only
	var x_reach := Vector2(INF, -INF)
	var y_reach := Vector2(INF, -INF)
	if auto_bounds_x or auto_bounds_y:
		for curve : CurveData in curves:
			if curve.points.is_empty(): continue
			
			var span := curve.reach()
			if not curve.normalize_x:
				x_reach.x = minf(x_reach.x, span.position.x)
				x_reach.y = maxf(x_reach.y, span.end.x)
			if not curve.normalize_y:
				y_reach.x = minf(y_reach.x, span.position.y)
				y_reach.y = maxf(y_reach.y, span.end.y)
	
	#an axis whose numbers never run below nothing keeps zero at its foot, however little of it the data reaches
	if auto_bounds_y and auto_bounds_keep_zero_y and is_finite(y_reach.x):
		y_reach.x = minf(y_reach.x, 0.0)
	
	#each axis fits to what its curves reach, or shows the bounds set on the node
	var x_range := fit_axis_range(x_reach.x, x_reach.y, center_x_on_zero) if auto_bounds_x else Vector2(lower_bound.x, upper_bound.x)
	var y_range := fit_axis_range(y_reach.x, y_reach.y, center_y_on_zero) if auto_bounds_y else Vector2(lower_bound.y, upper_bound.y)
	
	return {
		"x_lower_bound": x_range.x,
		"x_upper_bound": x_range.y,
		"y_lower_bound": y_range.x,
		"y_upper_bound": y_range.y,
	}

#an axis given nothing to fit, or nothing wider than a point, is opened out to the fallback span. a symmetric axis is
#pulled around zero instead
func fit_axis_range(axis_lower : float, axis_upper : float, centered : bool) -> Vector2:
	#an axis nothing was found for is a point at zero, which the rest of this opens out like any other point
	if is_inf(axis_lower) or is_nan(axis_lower):
		axis_lower = 0.0
		axis_upper = 0.0
	
	if centered:
		var extent := maxf(absf(axis_lower), absf(axis_upper))
		if is_zero_approx(extent): extent = fallback_axis_span
		return Vector2(-extent, extent)
	
	if is_equal_approx(axis_lower, axis_upper):
		return Vector2(axis_lower - fallback_axis_span, axis_upper + fallback_axis_span)
	return Vector2(axis_lower, axis_upper)


#axis fitting
#how far a tick may sit from being a whole number of steps from zero before it is treated as off the step, so float error
#from a bound like 0.30000000000000004 does not cost the axis a tick
var axis_index_tolerance := 1e-9
var thousand_scale := 1000.0
var million_scale := 1000000.0
#the clear space a tick label needs before its neighbor may sit that close, and the narrowest the label column gets
var minimum_tick_label_gap := 18.0
var minimum_tick_width := 8.0

#an axis as it is drawn: its limits, the round gap between its ticks, the values and labels of the ticks themselves, the unit
#its labels are written in, and the widths of the widest of them and of the column they need
class AxisFit:
	var lower_bound : float
	var upper_bound : float
	var step : float
	var tick_values : PackedFloat64Array = PackedFloat64Array()
	var label_scale := 1.0
	var labels : Array[String] = []
	var widest_label_width := 0.0
	var tick_width := 0.0

#the ticks of one step that fall inside an axis, counted in whole steps from zero, so none of them is ever a step or two off
#the round figure it stands for
func ticks_within(lower_bound : float, upper_bound : float, step : float) -> PackedFloat64Array:
	var ticks := PackedFloat64Array()
	var first_tick := int(ceilf(lower_bound / step - axis_index_tolerance))
	var last_tick := int(floorf(upper_bound / step + axis_index_tolerance))
	for index : int in range(first_tick, last_tick + 1):
		ticks.append(index * step)
	
	return ticks

#where a value sits along an axis, from 0 at its lower bound to 1 at its upper
func axis_fraction(axis_fit : AxisFit, value : float) -> float:
	var span : float = axis_fit.upper_bound - axis_fit.lower_bound
	if is_zero_approx(span): return 0.0
	
	return (value - axis_fit.lower_bound) / span

#the axis for one count of divisions: its ticks are laid at round figures, 1, 2 or 5 times a power of ten apart, so every
#label on it is a round number whatever its limits are. an axis fitted to what its curves reach is widened to the figures that
#bracket it, so its first and last tick sit on its own ends; one given its limits shows the ticks that fall inside them
func build_axis_fit(lower_bound : float, upper_bound : float, divisions_count : int, stretch_to_tidy_steps : bool, step_hint : float = 0.0) -> AxisFit:
	var span : float = upper_bound - lower_bound
	#an axis with nothing on it to span is opened out around its value, so it is drawn like any other rather than as one tick
	if is_zero_approx(span):
		lower_bound -= fallback_axis_span
		upper_bound += fallback_axis_span
		span = upper_bound - lower_bound
	var step : float = step_hint
	if step <= 0.0: step = nearest_nice_step(span / float(maxi(divisions_count, 1))) if span > 0.0 else 1.0
	
	if stretch_to_tidy_steps and span > 0.0:
		lower_bound = floorf(lower_bound / step) * step
		upper_bound = ceilf(upper_bound / step) * step
	
	var tick_values := ticks_within(lower_bound, upper_bound, step)
	if tick_values.is_empty(): tick_values.append(lower_bound)
	
	#if the limits cannot be moved, the step is taken down until the axis shows more than one tick: a step as wide as the whole
	#range leaves a single figure at one end of it
	if not stretch_to_tidy_steps and span > 0.0:
		var guard := 0
		while tick_values.size() < 2 and guard < 24:
			var smaller_step := previous_nice_step(step)
			if smaller_step <= 0.0 or is_equal_approx(smaller_step, step): break
			step = smaller_step
			tick_values = ticks_within(lower_bound, upper_bound, step)
			guard += 1
	
	#the unit the whole axis is labeled in, chosen once so a small tick is never in thousands on a million scale
	var axis_limit := maxf(absf(lower_bound), absf(upper_bound))
	var label_scale := 1.0
	if axis_limit >= million_scale - 1.0: label_scale = million_scale
	elif axis_limit >= thousand_scale * 10.0 - 1.0: label_scale = thousand_scale
	
	var labels : Array[String] = []
	var widest_label_width := 0.0
	for value : float in tick_values:
		var label := format_tick_label(value, step, label_scale)
		labels.append(label)
		widest_label_width = maxf(widest_label_width, measure_text_width(label))
	
	var fit := AxisFit.new()
	fit.lower_bound = lower_bound
	fit.upper_bound = upper_bound
	fit.step = step
	fit.tick_values = tick_values
	fit.label_scale = label_scale
	fit.labels = labels
	fit.widest_label_width = widest_label_width
	fit.tick_width = maxf(spacing(minimum_tick_width), widest_label_width + spacing(tick_label_padding))
	return fit

#the axis as it is drawn: fitted to the divisions asked for, and opened out to a wider step when the labels would not sit
#apart in the plot. the step only ever grows, so the loop always ends, and the ticks stay round figures as it does
func calculate_axis_fit(lower_bound : float, upper_bound : float, divisions_count : int, stretch_to_tidy_steps : bool, plot_width : float = 0.0) -> AxisFit:
	var fit := build_axis_fit(lower_bound, upper_bound, divisions_count, stretch_to_tidy_steps)
	if plot_width <= 0.0: return fit
	
	while fit.tick_values.size() > 1:
		var widest_row : float = float(fit.tick_values.size() - 1) * (fit.widest_label_width + spacing(minimum_tick_label_gap))
		if widest_row <= plot_width: break
		
		var wider_step := next_nice_step(fit.step)
		if wider_step <= fit.step: break
		
		fit = build_axis_fit(lower_bound, upper_bound, divisions_count, stretch_to_tidy_steps, wider_step)
	
	return fit


#grid
#the grid lines are a tenth of white, which is about where a line reads clearly but text does not
var background_line_color := Color(1.0, 1.0, 1.0, 0.1)
#the gray a label takes when it is written inside the plot, a little stronger than a grid line
var tick_label_inside_color := Color(1.0, 1.0, 1.0, 0.35)

#the grid lines one axis steps across the plot: a line for every division of it, each running the other way to the one
#they are stepped along. `along` is the unit vector of the axis the lines are stepped along
func draw_grid_lines(axis_fit : AxisFit, plot : Rect2, along : Vector2) -> void:
	var across := Vector2.ONE - along
	for value : float in axis_fit.tick_values:
		var line_position : Vector2 = plot.position + plot.size * along * axis_fraction(axis_fit, value)
		draw_line(line_position, line_position + plot.size * across, background_line_color)

func draw_grid(plot : Rect2, axis_cross : Vector2, x_axis_fit : AxisFit, y_axis_fit : AxisFit) -> void:
	var ascent := font.get_ascent(font_size)
	
	draw_grid_lines(x_axis_fit, plot, Vector2.RIGHT)
	draw_grid_lines(y_axis_fit, plot, Vector2.DOWN)
	
	#the tick labels written inside the plot, along the zero lines, in the gray the grid reads by
	if x_tick_label_placement == Placement.ON_AXIS:
		for index : int in x_axis_fit.tick_values.size():
			var tick_label : String = x_axis_fit.labels[index]
			var label_width := measure_text_width(tick_label)
			#a label sits right of its own gridline and above the zero line, so no line crosses the text
			var inside_left := clampf(plot.position.x + plot.size.x * axis_fraction(x_axis_fit, x_axis_fit.tick_values[index]) + spacing(tick_label_padding), plot.position.x, plot.end.x - label_width)
			draw_string(font, Vector2(inside_left, axis_cross.y - spacing(tick_label_padding)), tick_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, tick_label_inside_color)
	
	if y_tick_label_placement == Placement.ON_AXIS:
		var tick_count := y_axis_fit.tick_values.size()
		for index : int in tick_count:
			#the labels run top down, so the highest value comes first
			var tick_index := tick_count - 1 - index
			var tick_label : String = y_axis_fit.labels[tick_index]
			#the x axis already writes the zero they share when it sits on its axis too
			if tick_label == "0" and x_tick_label_placement == Placement.ON_AXIS: continue
			#a label sits just above its own gridline, so the line doesn't cross the text. the top one drops below its
			#line instead, which is the only way it stays inside the plot
			var inside_baseline := plot.position.y + plot.size.y * (1.0 - axis_fraction(y_axis_fit, y_axis_fit.tick_values[tick_index])) - spacing(tick_label_padding)
			if index == 0: inside_baseline = plot.position.y + ascent
			draw_string(font, Vector2(axis_cross.x + spacing(tick_label_padding), inside_baseline), tick_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, tick_label_inside_color)
	
	#the zero lines go over the grid, and only while zero is inside the plot
	if show_zero_lines:
		if axis_cross.x > plot.position.x and axis_cross.x < plot.end.x:
			draw_line(Vector2(axis_cross.x, plot.position.y), Vector2(axis_cross.x, plot.end.y), zero_line_color, zero_line_width)
		if axis_cross.y > plot.position.y and axis_cross.y < plot.end.y:
			draw_line(Vector2(plot.position.x, axis_cross.y), Vector2(plot.end.x, axis_cross.y), zero_line_color, zero_line_width)


#the marked ranges and areas, drawn over the grid and under the curves so the data stays on top of them
func draw_regions(plot : Rect2, x_axis_fit : AxisFit, y_axis_fit : AxisFit) -> void:
	for area : Area in areas:
		var corner : Vector2 = map_value_to_plot(area.rect.position, plot, x_axis_fit, y_axis_fit, false, false)
		var opposite : Vector2 = map_value_to_plot(area.rect.end, plot, x_axis_fit, y_axis_fit, false, false)
		var pixel : Rect2 = Rect2(corner, opposite - corner).abs().intersection(plot)
		if is_zero_approx(pixel.size.x) or is_zero_approx(pixel.size.y): continue
		
		if area.fill: draw_rect(pixel, area.fill_color, true)
		draw_rect(pixel, area.color, false, span_line_width)
	
	for span : Span in spans:
		if span.axis == Axis.X:
			var left : float = clampf(map_value_to_plot(Vector2(span.from, 0.0), plot, x_axis_fit, y_axis_fit, false, false).x, plot.position.x, plot.end.x)
			var right : float = clampf(map_value_to_plot(Vector2(span.to, 0.0), plot, x_axis_fit, y_axis_fit, false, false).x, plot.position.x, plot.end.x)
			if is_zero_approx(right - left): continue
			
			if span.fill: draw_rect(Rect2(left, plot.position.y, right - left, plot.size.y), span.fill_color)
			draw_line(Vector2(left, plot.position.y), Vector2(left, plot.end.y), span.color, span_line_width)
			draw_line(Vector2(right, plot.position.y), Vector2(right, plot.end.y), span.color, span_line_width)
		else:
			var top : float = clampf(map_value_to_plot(Vector2(0.0, span.to), plot, x_axis_fit, y_axis_fit, false, false).y, plot.position.y, plot.end.y)
			var bottom : float = clampf(map_value_to_plot(Vector2(0.0, span.from), plot, x_axis_fit, y_axis_fit, false, false).y, plot.position.y, plot.end.y)
			if is_zero_approx(bottom - top): continue
			
			if span.fill: draw_rect(Rect2(plot.position.x, top, plot.size.x, bottom - top), span.fill_color)
			draw_line(Vector2(plot.position.x, top), Vector2(plot.end.x, top), span.color, span_line_width)
			draw_line(Vector2(plot.position.x, bottom), Vector2(plot.end.x, bottom), span.color, span_line_width)

#the rules down the plot, drawn under the curves so the data stays on top of them
func draw_rules(plot : Rect2, x_axis_fit : AxisFit) -> void:
	var span : float = x_axis_fit.upper_bound - x_axis_fit.lower_bound
	if is_zero_approx(span): return
	
	for rule : Dictionary in x_rules:
		var x : float = lerpf(plot.position.x, plot.end.x, (rule.value - x_axis_fit.lower_bound) / span)
		if x < plot.position.x or x > plot.end.x: continue
		
		draw_line(Vector2(x, plot.position.y), Vector2(x, plot.end.y), rule.color, rule.width)


#curves
func draw_curves(plot : Rect2, x_axis_fit : AxisFit, y_axis_fit : AxisFit) -> void:
	var drawing_rect := plot_drawing_rect(plot)
	for curve : CurveData in curves:
		if curve.points.size() < 2: continue
		
		var width : float = curve_width if curve.width <= 0.0 else curve.width
		var plot_points := map_curve_to_plot(curve.points, plot, x_axis_fit, y_axis_fit, curve.normalize_x, curve.normalize_y)
		#a curve is drawn as the runs of it that stay inside the plot, so one whose values leave the axis range is cut off at
		#it rather than running out over the tick labels and the axis names
		for run : PackedVector2Array in clip_polyline_to_rect(plot_points, drawing_rect):
			draw_polyline(run, curve.color, width, antialiased)

#the rect the plot draws inside, which is the plot and a pixel of slack, so a line running along the plot's edge is not
#clipped away for sitting exactly on it
func plot_drawing_rect(plot : Rect2) -> Rect2:
	return plot.grow(1.0)

#the runs of a polyline that stay inside the rect. a curve that leaves the rect and comes back is two runs
func clip_polyline_to_rect(points : PackedVector2Array, rect : Rect2) -> Array[PackedVector2Array]:
	var runs : Array[PackedVector2Array] = []
	var run := PackedVector2Array()
	for index : int in points.size() - 1:
		var segment := clip_segment_to_rect(points[index], points[index + 1], rect)
		
		#a segment that starts somewhere else than the last one ended leaves a gap, so the run ends here
		if segment.is_empty() or (not run.is_empty() and run[run.size() - 1] != segment[0]):
			if run.size() > 1: runs.append(run)
			run = PackedVector2Array()
		
		if segment.is_empty(): continue
		if run.is_empty(): run.append(segment[0])
		run.append(segment[1])
	
	if run.size() > 1: runs.append(run)
	return runs

#the stretch of one segment that lies inside the rect, as its two ends, or nothing when the segment never enters it
func clip_segment_to_rect(from : Vector2, to : Vector2, rect : Rect2) -> PackedVector2Array:
	var direction := to - from
	var enter := 0.0
	var leave := 1.0
	
	for axis : int in [0, 1]:
		var run : float = direction[axis]
		var position : float = from[axis]
		var lower : float = rect.position[axis]
		var upper : float = rect.end[axis]
		
		#the segment runs parallel to this pair of sides, so it stays between them or misses the rect entirely
		if run == 0.0:
			if position < lower or position > upper: return PackedVector2Array()
			continue
		
		#where the segment crosses each side of the pair, in whichever order it crosses them. the segment stays between
		#the two crossings, so the rect as a whole holds it from the latest entry to the earliest exit
		var lower_crossing : float = (lower - position) / run
		var upper_crossing : float = (upper - position) / run
		enter = maxf(enter, minf(lower_crossing, upper_crossing))
		leave = minf(leave, maxf(lower_crossing, upper_crossing))
	
	if enter >= leave: return PackedVector2Array()
	return PackedVector2Array([from + direction * enter, from + direction * leave])

#where a value lands on the plot, against the fit its axes are drawn from, or against 0..1 on an axis the curve is
#normalized on, which is what spans that axis edge to edge instead of following its scale
func map_value_to_plot(value : Vector2, plot : Rect2, x_axis_fit : AxisFit, y_axis_fit : AxisFit, normalized_x : bool, normalized_y : bool) -> Vector2:
	var x_lower : float = 0.0 if normalized_x else x_axis_fit.lower_bound
	var x_upper : float = 1.0 if normalized_x else x_axis_fit.upper_bound
	var y_lower : float = 0.0 if normalized_y else y_axis_fit.lower_bound
	var y_upper : float = 1.0 if normalized_y else y_axis_fit.upper_bound
	return Vector2(
		remap(value.x, x_lower, x_upper, plot.position.x, plot.end.x),
		remap(value.y, y_lower, y_upper, plot.end.y, plot.position.y)
	)

func map_curve_to_plot(points : PackedVector2Array, plot : Rect2, x_axis_fit : AxisFit, y_axis_fit : AxisFit, normalized_x : bool, normalized_y : bool) -> PackedVector2Array:
	var plot_points := PackedVector2Array()
	for point : Vector2 in points:
		plot_points.append(map_value_to_plot(point, plot, x_axis_fit, y_axis_fit, normalized_x, normalized_y))
	
	return plot_points

#the clear space a word written along a curve keeps from the line it names
var label_line_gap := 2.0
#how far a word written beside a point stops short of it
var label_point_gap := 6.0

#every word the plot was asked to write, mapped to where it lands and turned the way its run runs
func draw_labels(plot : Rect2, x_axis_fit : AxisFit, y_axis_fit : AxisFit) -> void:
	var drawing_rect := plot_drawing_rect(plot)
	
	for label : Dictionary in labels:
		var position := map_value_to_plot(label.position, plot, x_axis_fit, y_axis_fit, false, false)
		var ahead := map_value_to_plot(label.position + label.direction, plot, x_axis_fit, y_axis_fit, false, false)
		draw_label(label.text, position, (ahead - position).angle(), label.align, label.clear, drawing_rect)
	
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

#one word written in the plot, turned to follow a run and held clear of it by `clear`. one that would hang over the
#plot's edge is pulled inside
func draw_label(text : String, position : Vector2, angle : float, align : HorizontalAlignment, clear : float, drawing_rect : Rect2) -> void:
	var ascent := font.get_ascent(font_size)
	var descent := font.get_descent(font_size)
	var half_size := Vector2(measure_text_width(text), ascent + descent) * 0.5
	var along_axis := Vector2(cos(angle), sin(angle))
	var across_axis := Vector2(sin(angle), -cos(angle))
	
	#a word aligned beside its point rather than across it is pushed that far along the run
	var along := 0.0
	if align == HORIZONTAL_ALIGNMENT_LEFT: along = half_size.x + spacing(label_point_gap)
	elif align == HORIZONTAL_ALIGNMENT_RIGHT: along = -(half_size.x + spacing(label_point_gap))
	var middle := position + along_axis * along + across_axis * (half_size.y + spacing(label_line_gap) + spacing(clear))
	
	#the word is pulled inside the plot by the distance it reaches along each axis once turned
	var reach := Vector2(
		absf(along_axis.x) * half_size.x + absf(along_axis.y) * half_size.y,
		absf(along_axis.y) * half_size.x + absf(along_axis.x) * half_size.y,
	)
	middle = middle.clamp(drawing_rect.position + reach, (drawing_rect.end - reach).max(drawing_rect.position + reach))
	
	draw_set_transform(middle, angle, Vector2.ONE)
	draw_string(font, Vector2(-half_size.x, ascent - descent * 0.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)

#where a curve reaches a value on its own x axis, as the point to write at and the run to follow. the run is the segment the
#value falls on, or the one at the end it was asked for past, carried on out along it
func curve_label_anchor(curve : CurveData, position : float) -> Dictionary:
	var points := curve.points
	if points.size() < 2: return {}
	
	var index := -1
	for candidate : int in points.size() - 1:
		var span_start := points[candidate]
		var span_end := points[candidate + 1]
		if is_equal_approx(span_start.x, span_end.x): continue
		if position >= minf(span_start.x, span_end.x) and position <= maxf(span_start.x, span_end.x):
			index = candidate
			break
	if index < 0: index = 0 if position < points[0].x else points.size() - 2
	
	var start := points[index]
	var end := points[index + 1]
	if is_equal_approx(start.x, end.x): return {}
	
	var direction := end - start
	#text is never written upside down, so a curve running right to left is read the other way
	if direction.x < 0.0: direction = -direction
	return {"point": start.lerp(end, (position - start.x) / (end.x - start.x)), "direction": direction}


#plates
#the room a plate keeps around its rows, and how far they are pulled up into the line above them
var plate_padding := 3.0
var plate_row_trim := 4.0
#the swatch in front of a row: its length and its thickness, and the gap between it and the text
var legend_swatch_size := Vector2(12.0, 2.0)
var legend_swatch_gap := 4.0
#the gap between the entries of a plate that flows them along one line
var plate_entry_gap := 8.0

#the width of one row, swatch and text together
func plate_row_width(row_color : Color, row_text : String) -> float:
	var swatch : float = spacing(legend_swatch_size.x) + spacing(legend_swatch_gap) if row_color.a > 0.0 else 0.0
	return swatch + measure_text_width(row_text)

#how large a plate comes out for these rows, which is what lets the caller put one in a corner of the plot
func measure_plate(row_colors : Array[Color], row_texts : Array[String], horizontal : bool) -> Vector2:
	var widest_row := 0.0
	var lined_up_width := 0.0
	for row : int in row_texts.size():
		var row_width := plate_row_width(row_colors[row], row_texts[row])
		widest_row = maxf(widest_row, row_width)
		lined_up_width += row_width
	
	var plate_width := widest_row
	var plate_height := row_texts.size() * plate_row_height()
	if horizontal:
		plate_width = lined_up_width + spacing(plate_entry_gap) * maxf(0.0, row_texts.size() - 1.0)
		plate_height = plate_row_height()
	
	return Vector2(spacing(plate_padding) * 2.0 + plate_width, plate_height + spacing(plate_padding) * 2.0)

#the pitch of the rows on a plate, tighter than a whole line box
func plate_row_height() -> float:
	return font.get_ascent(font_size) + font.get_descent(font_size) - spacing(plate_row_trim)

#the baseline of one of those rows, with half the leading taken off the first so the padding stays even
func plate_row_baseline(plate_top : float, row : int) -> float:
	var line_height := font.get_ascent(font_size) + font.get_descent(font_size)
	var leading := (line_height - font_size) * 0.5
	return plate_top + spacing(plate_padding) + row * plate_row_height() + font.get_ascent(font_size) - leading * 0.5


#a heading names the rows under it, so it is written dimmer and carries no swatch
var plate_heading_alpha := 0.6

#a plate of rows backed by the theme's tooltip panel. a row with a second color has the right half of its swatch drawn
#over. given a rect to stay inside, the plate is nudged until it fits, and the rect it ended up in is returned
func draw_plate(plate : Rect2, row_colors : Array[Color], row_texts : Array[String], row_second_colors : Array[Color] = [], stay_inside : Rect2 = Rect2(), horizontal : bool = false) -> Rect2:
	var ascent := font.get_ascent(font_size)
	var descent := font.get_descent(font_size)
	
	if stay_inside.size.x > 0.0:
		plate.position = plate.position.clamp(stay_inside.position, stay_inside.end - plate.size)
	draw_style_box(get_theme_stylebox("panel", "TooltipPanel"), plate)
	
	var row_left := plate.position.x + spacing(plate_padding)
	for row : int in row_texts.size():
		var baseline := plate_row_baseline(plate.position.y, 0 if horizontal else row)
		
		if row_colors[row].a <= 0.0:
			var heading_color := Color(text_color, text_color.a * plate_heading_alpha)
			draw_string(font, Vector2(row_left, baseline), row_texts[row], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, heading_color)
		else:
			var swatch_y := baseline - (ascent - descent) * 0.5
			var swatch_end := row_left + spacing(legend_swatch_size.x)
			draw_line(Vector2(row_left, swatch_y), Vector2(swatch_end, swatch_y), row_colors[row], spacing(legend_swatch_size.y))
			var second_color : Color = row_second_colors[row] if row < row_second_colors.size() else Color(0.0, 0.0, 0.0, 0.0)
			if second_color.a > 0.0:
				draw_line(Vector2(row_left + spacing(legend_swatch_size.x) * 0.5, swatch_y), Vector2(swatch_end, swatch_y), second_color, spacing(legend_swatch_size.y))
			draw_string(font, Vector2(swatch_end + spacing(legend_swatch_gap), baseline), row_texts[row], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
		
		if horizontal:
			row_left += plate_row_width(row_colors[row], row_texts[row]) + spacing(plate_entry_gap)
	
	return plate

#the height of one of the bands a plate is given above the plot, which is one row of plate and the padding around it
func plate_band_height() -> float:
	return plate_row_height() + spacing(plate_padding) * 2.0

#whether the legend or the readout is placed in a band above the plot rather than in a corner of it
func legend_is_above() -> bool:
	if not show_legend or legend_placement != PlatePlacement.ABOVE: return false
	for curve : CurveData in curves:
		if curve.legend_name != "": return true
	return false

func readout_is_above() -> bool:
	return show_readout and readout_placement == PlatePlacement.ABOVE

#where a plate of this size ends up: its corner, or the first other corner clear of the cursor and the plates it must not
#cover, so a plate that dodges lands well away from the cursor instead of just off its edge
func plate_corner_position(placement : PlatePlacement, plate_size : Vector2, plot : Rect2, keep_clear : Array[Rect2] = []) -> Vector2:
	var on_right : bool = placement == PlatePlacement.TOP_RIGHT or placement == PlatePlacement.BOTTOM_RIGHT
	var on_bottom : bool = placement == PlatePlacement.BOTTOM_LEFT or placement == PlatePlacement.BOTTOM_RIGHT
	var position := corner_position(on_right, on_bottom, plate_size, plot)
	
	if plates_dodge_cursor and Rect2(position, plate_size).has_point(hover_position):
		var corners : Array[Vector2] = [
			corner_position(on_right, not on_bottom, plate_size, plot),
			corner_position(not on_right, on_bottom, plate_size, plot),
			corner_position(not on_right, not on_bottom, plate_size, plot),
		]
		#the first corner clear of both the cursor and the other plates, or the one opposite the cursor when none is
		position = corners[0]
		for candidate : Vector2 in corners:
			if Rect2(candidate, plate_size).has_point(hover_position) or covers_any(candidate, plate_size, keep_clear): continue
			position = candidate
			break
	
	#only a plate with no free corner left is stepped aside, which is the case when two plates share one
	for other : Rect2 in keep_clear:
		if other.size.x <= 0.0 or not Rect2(position, plate_size).intersects(other): continue
		position = plate_step_clear_of(position, plate_size, plot, other)
	
	return position.clamp(plot.position, (plot.end - plate_size).max(plot.position))

#the position a plate of this size takes in one corner of the plot
func corner_position(on_right : bool, on_bottom : bool, plate_size : Vector2, plot : Rect2) -> Vector2:
	return Vector2(
		plot.end.x - plate_size.x if on_right else plot.position.x,
		plot.end.y - plate_size.y if on_bottom else plot.position.y
	)

#whether a plate of this size would cover any of these rects
func covers_any(plate_position : Vector2, plate_size : Vector2, others : Array[Rect2]) -> bool:
	for other : Rect2 in others:
		if other.size.x > 0.0 and Rect2(plate_position, plate_size).intersects(other): return true
	return false

#the first place a plate can go to stop covering a rect: below it, above it, then to either side of it, each placement
#keeping the clearance the plates keep. a placement is only taken while the plate still fits inside the plot there
func plate_step_clear_of(plate_position : Vector2, plate_size : Vector2, plot : Rect2, avoid : Rect2) -> Vector2:
	var clearance := spacing(tick_label_padding)
	var placements : Array[Rect2] = [
		Rect2(Vector2(plate_position.x, avoid.end.y + clearance), plate_size),
		Rect2(Vector2(plate_position.x, avoid.position.y - clearance - plate_size.y), plate_size),
		Rect2(Vector2(avoid.end.x + clearance, plate_position.y), plate_size),
		Rect2(Vector2(avoid.position.x - clearance - plate_size.x, plate_position.y), plate_size),
	]
	for placement : Rect2 in placements:
		if plot.encloses(placement): return placement.position
	
	return plate_position


#markers
#the dots, and the values they are worked out from. finding them costs more than drawing the curves, and the cursor moving
#doesn't move them, so they are kept until something that does changes
var cached_markers : Array[Marker] = []
var cached_marker_key : Array = []
#where the marker readout ended up, which the readout keeps clear of
var marker_plate_rect := Rect2()

#which side of a value a sample sits on, with anything close enough to be on the line counted as on it
static func curve_side(sample : float, value : float) -> float:
	if is_equal_approx(sample, value): return 0.0
	return signf(sample - value)

#every place a curve meets the line at this value on the sweep axis, as (value on the other axis, parameter) pairs.
#passing_only keeps the places the curve passes through the line, which is what a dot wants: a curve that touches the
#line or runs along it does not cross it there
func find_curve_crossings(points : PackedVector2Array, curve_parameters : PackedFloat32Array, sweep_value : float, sweep_y : bool, passing_only : bool = false) -> Array[Vector2]:
	var crossings : Array[Vector2] = []
	for point_index : int in points.size() - 1:
		var start := points[point_index]
		var end := points[point_index + 1]
		var start_along := start.y if sweep_y else start.x
		var end_along := end.y if sweep_y else end.x
		var start_across := start.x if sweep_y else start.y
		var end_across := end.x if sweep_y else end.y
		#which side of the line each end sits on, with anything close enough to it counted as on it
		var start_side := curve_side(start_along, sweep_value)
		var end_side := curve_side(end_along, sweep_value)
		
		#a segment running from one side of the line to the other crosses it somewhere between its ends
		if start_side * end_side < 0.0:
			var along : float = (sweep_value - start_along) / (end_along - start_along)
			crossings.append(Vector2(lerpf(start_across, end_across, along), crossing_parameter(curve_parameters, points.size(), point_index, along)))
			continue
		
		#a sample sitting on the line only counts when the curve passes through it, so a curve that touches the line or
		#runs along it does not mark the sample. the segment before it is the one that reports it
		if passing_only:
			if start_side != 0.0 or end_side == 0.0 or point_index == 0: continue
			var before := points[point_index - 1]
			var before_along := before.y if sweep_y else before.x
			if curve_side(before_along, sweep_value) == -end_side:
				crossings.append(Vector2(start_across, crossing_parameter(curve_parameters, points.size(), point_index, 0.0)))
			continue
		
		#a segment holding the line without crossing it still reports where the curve touches it: the readout wants every
		#meeting, and a segment running along the line reports its own start
		if sweep_value < minf(start_along, end_along) or sweep_value > maxf(start_along, end_along): continue
		var along := 0.0
		if not is_equal_approx(start_along, end_along):
			along = (sweep_value - start_along) / (end_along - start_along)
		crossings.append(Vector2(lerpf(start_across, end_across, along), crossing_parameter(curve_parameters, points.size(), point_index, along)))
	
	return crossings

#a parameter only means anything when it lines up with the samples
func crossing_parameter(curve_parameters : PackedFloat32Array, sample_count : int, point_index : int, along : float) -> float:
	if curve_parameters.size() != sample_count: return NAN
	return lerpf(curve_parameters[point_index], curve_parameters[point_index + 1], along)

#the samples where a curve turns around, its peaks and troughs. a sample matching either neighbor hasn't really turned
func find_curve_extrema(points : PackedVector2Array) -> Array[Vector2]:
	var extrema : Array[Vector2] = []
	for point_index : int in range(1, points.size() - 1):
		var before := points[point_index - 1].y
		var here := points[point_index].y
		var after := points[point_index + 1].y
		if (here - before) * (after - here) >= 0.0: continue
		if is_equal_approx(here, before) or is_equal_approx(here, after): continue
		extrema.append(points[point_index])
	
	return extrema


#the curve is cut into this many cells across and up, which is fine enough that a segment shares a cell with only a
#handful of the others
var intersection_grid_columns := 64
var intersection_grid_rows := 64

#the segments of a curve bucketed by cell, so a segment only has to be tested against the ones sharing its cell
func build_segment_grid(points : PackedVector2Array) -> Dictionary:
	var lowest := points[0]
	var highest := points[0]
	for point : Vector2 in points:
		lowest = lowest.min(point)
		highest = highest.max(point)
	
	#a curve with no height, or no width, still needs a cell size to divide by
	var cell_size := Vector2(
		maxf((highest.x - lowest.x) / float(intersection_grid_columns), 1.0),
		maxf((highest.y - lowest.y) / float(intersection_grid_rows), 1.0),
	)
	
	var cells : Dictionary = {}
	for segment : int in points.size() - 1:
		for cell : Vector2i in segment_grid_cells(points[segment], points[segment + 1], lowest, cell_size):
			if not cells.has(cell): cells[cell] = []
			cells[cell].append(segment)
	
	return {"lowest": lowest, "cell_size": cell_size, "cells": cells}

#every cell a segment passes over, clamped to the grid, so a segment running off its side still lands somewhere
func segment_grid_cells(from : Vector2, to : Vector2, lowest : Vector2, cell_size : Vector2) -> Array[Vector2i]:
	var cells : Array[Vector2i] = []
	var first_cell := Vector2i(
		clampi(int((minf(from.x, to.x) - lowest.x) / cell_size.x), 0, intersection_grid_columns - 1),
		clampi(int((minf(from.y, to.y) - lowest.y) / cell_size.y), 0, intersection_grid_rows - 1),
	)
	var last_cell := Vector2i(
		clampi(int((maxf(from.x, to.x) - lowest.x) / cell_size.x), 0, intersection_grid_columns - 1),
		clampi(int((maxf(from.y, to.y) - lowest.y) / cell_size.y), 0, intersection_grid_rows - 1),
	)
	
	for column : int in range(first_cell.x, last_cell.x + 1):
		for row : int in range(first_cell.y, last_cell.y + 1):
			cells.append(Vector2i(column, row))
	
	return cells

#where two curves cross each other on the plot, in pixels. given the same curve twice it finds where the curve crosses
#itself, which is why the segments either side of a sample can be skipped
func find_curve_intersections(first_points : PackedVector2Array, second_points : PackedVector2Array, skip_neighboring_segments : bool = false) -> Array[Vector2]:
	var intersections : Array[Vector2] = []
	if first_points.size() < 2 or second_points.size() < 2: return intersections
	
	var grid := build_segment_grid(second_points)
	var lowest : Vector2 = grid.lowest
	var cell_size : Vector2 = grid.cell_size
	var cells : Dictionary = grid.cells
	#a segment sits in every cell it passes over, so it is stamped once it has been tested against the segment in hand
	var tested := PackedInt32Array()
	tested.resize(second_points.size())
	var stamp := 0
	
	for first_index : int in first_points.size() - 1:
		var first_start := first_points[first_index]
		var first_end := first_points[first_index + 1]
		var first_direction := first_end - first_start
		var first_second_index : int = first_index + 2 if skip_neighboring_segments else 0
		stamp += 1
		
		for cell : Vector2i in segment_grid_cells(first_start, first_end, lowest, cell_size):
			if not cells.has(cell): continue
			for second_index : int in cells[cell]:
				if tested[second_index] == stamp: continue
				tested[second_index] = stamp
				if second_index < first_second_index: continue
				
				var second_start := second_points[second_index]
				var second_direction := second_points[second_index + 1] - second_start
				
				var denominator := first_direction.x * second_direction.y - first_direction.y * second_direction.x
				if is_zero_approx(denominator): continue
				
				var offset := second_start - first_start
				var along_first := (offset.x * second_direction.y - offset.y * second_direction.x) / denominator
				var along_second := (offset.x * first_direction.y - offset.y * first_direction.x) / denominator
				if along_first < 0.0 or along_first > 1.0 or along_second < 0.0 or along_second > 1.0: continue
				
				intersections.append(first_start + first_direction * along_first)
	
	return intersections


#dots found this close together carrying the same value are drawn as one dot
var marker_merge_distance := 1.5

#one dot on the plot: where it lands, the color it is drawn in, and a second color for a dot that belongs to two curves.
#`text` is the value it stands for, `kind` is what it is, which is what the readout groups the dots under, and `crowded`
#is set when another dot sits on it
class Marker:
	var position : Vector2
	var color : Color
	var second_color := Color(0.0, 0.0, 0.0, 0.0)
	var text : String
	var kind : String
	var crowded := false

#every place a dot belongs: a crossing of either axis, a turn in a curve, or a meeting between curves
func collect_curve_markers(plot : Rect2, x_axis_fit : AxisFit, y_axis_fit : AxisFit) -> Array[Marker]:
	var markers : Array[Marker] = []
	#the curves as they are drawn, which is where intersections between them have to be measured
	var plot_curves : Dictionary[CurveData, PackedVector2Array] = {}
	
	for curve : CurveData in curves:
		if curve.points.is_empty(): continue
		
		if show_curve_intersections or show_curve_self_intersections:
			plot_curves[curve] = map_curve_to_plot(curve.points, plot, x_axis_fit, y_axis_fit, curve.normalize_x, curve.normalize_y)
		
		#a normalized curve spans 0..1, so the middle of its axis is its zero and not the plot's edge
		var y_axis_value : float = 0.5 if curve.normalize_y else 0.0
		var x_axis_value : float = 0.5 if curve.normalize_x else 0.0
		
		#the curve crossing the horizontal axis gives x values, and the curve crossing the vertical one gives y values. a crossing of
		#the horizontal axis is found by sweeping along y, and one of the vertical axis by sweeping along x, which is the other way
		#round from what the two readings look like
		if show_axis_crossings:
			for crossing : Vector2 in find_curve_crossings(curve.points, curve.parameters, y_axis_value, true, true):
				markers.append(curve_marker(curve, Vector2(crossing.x, y_axis_value), "Axis crossing", plot, x_axis_fit, y_axis_fit))
			
			for crossing : Vector2 in find_curve_crossings(curve.points, curve.parameters, x_axis_value, false, true):
				#a curve already sitting on the horizontal axis where it crosses the vertical one would put its dot on the
				#origin, where the two axes meet anyway, and on top of every other curve doing the same
				if is_equal_approx(crossing.x, y_axis_value): continue
				markers.append(curve_marker(curve, Vector2(x_axis_value, crossing.x), "Axis crossing", plot, x_axis_fit, y_axis_fit))
		
		if show_curve_extrema:
			for extremum : Vector2 in find_curve_extrema(curve.points):
				markers.append(curve_marker(curve, extremum, "Extremum", plot, x_axis_fit, y_axis_fit))
	
	#where curves meet each other, and where one of them meets itself. both are measured in pixels, because a
	#normalized curve crosses the others somewhere other than its own values suggest
	var meeting_pairs : Array = []
	if show_curve_intersections:
		var plotted : Array = plot_curves.keys()
		for first_index : int in plotted.size():
			for second_index : int in range(first_index + 1, plotted.size()):
				meeting_pairs.append([plotted[first_index], plotted[second_index], "Intersection"])
	if show_curve_self_intersections:
		for curve : CurveData in plot_curves:
			meeting_pairs.append([curve, curve, "Self intersection"])
	
	for pair : Array in meeting_pairs:
		var first : CurveData = pair[0]
		var second : CurveData = pair[1]
		#a curve meeting itself belongs to one curve, so both halves of its dot are its own color
		for meeting : Vector2 in find_curve_intersections(plot_curves[first], plot_curves[second], first == second):
			var marker := Marker.new()
			marker.position = meeting
			marker.color = first.color
			marker.second_color = second.color
			marker.text = describe_values(read_pixel_value(meeting, plot, x_axis_fit, y_axis_fit), x_axis_fit, y_axis_fit)
			marker.kind = pair[2]
			markers.append(marker)
	
	#the dots the caller asked for, which are given in the same values the curves are drawn at
	for marked : Dictionary in marked_points:
		var marker := Marker.new()
		marker.position = map_value_to_plot(marked.value, plot, x_axis_fit, y_axis_fit, false, false)
		marker.color = marked.color
		marker.text = marked.text
		marker.kind = marked.kind
		markers.append(marker)
	
	#a dot that lands on another dot carrying the same value is the same dot found twice, so only the first is kept. a dot
	#that lands on one carrying another value is marked as crowded, so a stack of values reads as more than one dot
	var merge_distance := spacing(marker_merge_distance)
	var crowding_distance := spacing(dot_radius) * 2.0
	var kept : Array[Marker] = []
	for marker : Marker in markers:
		var repeated := false
		var sharing_spot : Array[Marker] = []
		for kept_marker : Marker in kept:
			var distance := kept_marker.position.distance_to(marker.position)
			if kept_marker.kind == marker.kind and kept_marker.text == marker.text and distance <= merge_distance:
				repeated = true
				break
			if distance <= crowding_distance: sharing_spot.append(kept_marker)
		
		if repeated: continue
		
		marker.crowded = not sharing_spot.is_empty()
		for kept_marker : Marker in sharing_spot: kept_marker.crowded = true
		kept.append(marker)
	
	return kept

#a dot on a place along one curve: where it lands on the plot, the color it is drawn in, the value it was measured at,
#and the kind of dot it is
func curve_marker(curve : CurveData, value : Vector2, kind : String, plot : Rect2, x_axis_fit : AxisFit, y_axis_fit : AxisFit) -> Marker:
	var marker := Marker.new()
	marker.position = map_value_to_plot(value, plot, x_axis_fit, y_axis_fit, curve.normalize_x, curve.normalize_y)
	marker.color = curve.color
	marker.text = describe_values(value, x_axis_fit, y_axis_fit)
	marker.kind = kind
	return marker

#the values of an axis fit, which is what a marker cache key compares: each draw builds new fits whether they changed or
#whether they did not, so the fits have to go into the key by their values and not by which fit they are
func axis_fit_key(fit : AxisFit) -> Array:
	return [fit.lower_bound, fit.upper_bound, fit.step, fit.tick_values, fit.label_scale, fit.labels, fit.tick_width]

#everything a dot's place and its value are worked out from, so a change to any of it is noticed. the samples are hashed,
#so an edit made straight into a curve's points does not go unseen
func marker_cache_key(plot : Rect2, x_axis_fit : AxisFit, y_axis_fit : AxisFit) -> Array:
	var curve_key : Array = []
	for curve : CurveData in curves:
		curve_key.append(hash(curve.points))
		curve_key.append(curve.color)
		curve_key.append(curve.normalize_x)
		curve_key.append(curve.normalize_y)
	
	return [
		plot, axis_fit_key(x_axis_fit), axis_fit_key(y_axis_fit),
		show_axis_crossings, show_curve_extrema, show_curve_intersections, show_curve_self_intersections,
		spacing(dot_radius), spacing(marker_merge_distance), hover_step_fraction,
		curve_key, hash(marked_points),
	]


#how close the cursor must come to a marker for its value to be written out, and how much bigger a reported dot is drawn
var marker_hover_distance := 12.0
var marker_hover_growth := 2.5
var marker_label_gap := 6.0

#the dots, and the plate of values beside the cursor for the ones within reach of it
func draw_markers(plot : Rect2, x_axis_fit : AxisFit, y_axis_fit : AxisFit) -> void:
	marker_plate_rect = Rect2()
	if not show_axis_crossings and not show_curve_extrema and not show_curve_intersections and not show_curve_self_intersections and marked_points.is_empty(): return
	
	var marker_key := marker_cache_key(plot, x_axis_fit, y_axis_fit)
	if marker_key != cached_marker_key:
		cached_markers = collect_curve_markers(plot, x_axis_fit, y_axis_fit)
		cached_marker_key = marker_key
	
	var reachable : Array[Marker] = []
	var drawing_rect := plot_drawing_rect(plot)
	for marker : Marker in cached_markers:
		#a dot on a part of the curve that is outside the plot is outside it too
		if not drawing_rect.has_point(marker.position): continue
		
		var dot_size : float = spacing(dot_radius) + spacing(marker_hover_growth) * 0.5 if marker.crowded else spacing(dot_radius)
		draw_marker_dot(marker.position, dot_size, marker.color, marker.second_color)
		#every dot within reach is drawn larger, so the whole group the readout covers can be seen at once
		if marker.position.distance_to(hover_position) <= spacing(marker_hover_distance):
			reachable.append(marker)
			draw_marker_dot(marker.position, spacing(dot_radius) + spacing(marker_hover_growth), marker.color, marker.second_color)
	
	if reachable.is_empty(): return
	
	var rows := build_readout_rows(reachable)
	var offset := Vector2(spacing(dot_radius) + spacing(marker_label_gap), -spacing(dot_radius) - spacing(marker_label_gap))
	var plate_size := measure_plate(rows.colors, rows.texts, marker_readout_horizontal)
	marker_plate_rect = draw_plate(Rect2(hover_position + offset, plate_size), rows.colors, rows.texts, rows.second_colors, plot, marker_readout_horizontal)

#the rows for the dots within reach of the cursor, under one heading per kind. a heading is a row with no color
func build_readout_rows(reachable : Array[Marker]) -> Dictionary:
	var row_colors : Array[Color] = []
	var second_colors : Array[Color] = []
	var row_texts : Array[String] = []
	var kinds_listed : Array[String] = []
	
	for marker : Marker in reachable:
		if kinds_listed.has(marker.kind): continue
		
		kinds_listed.append(marker.kind)
		row_colors.append(Color(0.0, 0.0, 0.0, 0.0))
		second_colors.append(Color(0.0, 0.0, 0.0, 0.0))
		row_texts.append(marker.kind)
		
		for other : Marker in reachable:
			if other.kind != marker.kind: continue
			row_colors.append(other.color)
			second_colors.append(other.second_color)
			row_texts.append(other.text)
	
	return {"colors": row_colors, "second_colors": second_colors, "texts": row_texts}


#the dots the caller asked for, in the same values the curves are drawn at
var marked_points : Array[Dictionary] = []

#how many segments the second half of a two colored dot is cut into
var marker_half_segments := 10

#a dot in one color, or in two when the marker belongs to two curves. the second color is a wedge, because a circle can
#only be drawn in one
func draw_marker_dot(position : Vector2, radius : float, first_color : Color, second_color : Color) -> void:
	draw_circle(position, radius, first_color, true, -1.0, antialiased)
	if second_color.a <= 0.0: return
	
	var second_half := PackedVector2Array([position])
	for segment : int in marker_half_segments + 1:
		var angle : float = -PI * 0.5 + PI * segment / float(marker_half_segments)
		second_half.append(position + Vector2(cos(angle), sin(angle)) * radius)
	
	draw_colored_polygon(second_half, second_color)


#titles
#the axis names written on the axis itself, in the gray the tick labels take there
func draw_axis_names(plot : Rect2, axis_cross : Vector2) -> void:
	var ascent := font.get_ascent(font_size)
	var descent := font.get_descent(font_size)
	
	if x_label != "" and x_label_placement == Placement.ON_AXIS:
		draw_string(font, Vector2(plot.position.x, axis_cross.y + spacing(tick_label_padding) + ascent), x_label, HORIZONTAL_ALIGNMENT_RIGHT, plot.size.x, font_size, tick_label_inside_color)
	
	if y_label != "" and y_label_placement == Placement.ON_AXIS:
		var y_name_length := measure_text_width(y_label)
		#the glyphs hang off the baseline, so the origin moves in by an ascent like the x name hangs one under its line.
		#the origin and the baseline offset are snapped to whole pixels, otherwise the rotated glyphs get resampled half a
		#pixel off and look blurry
		var inside_origin := Vector2(roundf(axis_cross.x - spacing(tick_label_padding) - ascent), roundf(plot.position.y + spacing(tick_label_padding) + y_name_length * 0.5))
		draw_set_transform(inside_origin, -PI * 0.5, Vector2.ONE)
		draw_string(font, Vector2(roundf(-y_name_length * 0.5), roundf((ascent - descent) * 0.5)), y_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, tick_label_inside_color)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


#legend
#the legend plate: one swatch and name for every curve that carries one
func draw_legend(plot : Rect2, legend_band : Rect2) -> void:
	var legend_colors : Array[Color] = []
	var legend_names : Array[String] = []
	for curve : CurveData in curves:
		if curve.legend_name == "": continue
		
		legend_colors.append(curve.color)
		legend_names.append(curve.legend_name)
	
	if legend_colors.is_empty(): return
	
	if legend_placement == PlatePlacement.ABOVE:
		#the plate laid out in a band is one row tall, however the legend is set
		draw_plate(Rect2(legend_band.position, measure_plate(legend_colors, legend_names, true)), legend_colors, legend_names, [], legend_band, true)
		return
	
	var plate_size := measure_plate(legend_colors, legend_names, legend_horizontal)
	draw_plate(Rect2(plate_corner_position(legend_placement, plate_size, plot, [readout_plate_rect, marker_plate_rect]), plate_size), legend_colors, legend_names, [], plot, legend_horizontal)


#cursor
#where the cursor sits inside the graph, cleared when it leaves
var hover_position := Vector2(-1.0, -1.0):
	set(x):
		hover_position = x; queue_redraw()

#where the readout plate ended up, which the legend keeps clear of
var readout_plate_rect := Rect2()
#the cursor is allowed this little way outside the plot, so the ends of a curve at the plot's edge stay easy to hover
var hover_snap_distance := 12.0
#the readout resolves a value to this fraction of a gridline, and writes a parameter to this many decimals
var hover_step_fraction := 0.01
var hover_parameter_decimals := 1
#the crosshair, a light line that reads over the grid without competing with it
var hover_line_color := Color(1.0, 1.0, 1.0, 0.35)
#the clear space between the readout's columns
var readout_column_gap := 6.0

func cursor_reach(plot : Rect2) -> Rect2:
	return Rect2(plot.position - Vector2.ONE * spacing(hover_snap_distance), plot.size + Vector2.ONE * spacing(hover_snap_distance) * 2.0)

#the cursor is pinned to the middle of its pixel, where a line and a dot drawn at the same place both land
func cursor_pixel(plot : Rect2) -> Vector2:
	return Vector2(
		floorf(clampf(hover_position.x, plot.position.x, plot.end.x)) + 0.5,
		floorf(clampf(hover_position.y, plot.position.y, plot.end.y)) + 0.5,
	)

#one reading of a curve at the cursor: the curve it came from, the value found there, the parameter that value was taken
#at, and where it lands on the plot. `distance` is how far the cursor is from the point, which is what the nearest point
#readout sorts its readings by
class Reading:
	var color : Color
	##The curve's name, repeated on the first of its crossings and left empty on the rest.
	var name : String = ""
	var value : float
	##The value the sample was taken at, left as NAN when the curve carries none.
	var parameter := NAN
	var pixel : Vector2
	var distance := 0.0

#every place a curve crosses the cursor, which is what both the dot and the readout row are made from
func cursor_readings(plot : Rect2, x_axis_fit : AxisFit, y_axis_fit : AxisFit) -> Array[Reading]:
	var readings : Array[Reading] = []
	var sweep_y := readout_axis == ReadoutAxis.Y
	var sweep_fit : AxisFit = y_axis_fit if sweep_y else x_axis_fit
	var cursor := cursor_pixel(plot)
	
	for curve : CurveData in curves:
		if curve.points.is_empty(): continue
		
		#the cursor's position on the sweep axis, in the space this curve is drawn in
		var sweep_normalized := curve.normalize_y if sweep_y else curve.normalize_x
		var sweep_lower_bound : float = 0.0 if sweep_normalized else sweep_fit.lower_bound
		var sweep_upper_bound : float = 1.0 if sweep_normalized else sweep_fit.upper_bound
		var reading_at : float
		if sweep_y: reading_at = remap(cursor.y, plot.end.y, plot.position.y, sweep_lower_bound, sweep_upper_bound)
		else: reading_at = remap(cursor.x, plot.position.x, plot.end.x, sweep_lower_bound, sweep_upper_bound)
		
		#one value on the sweep axis is worth this many pixels, which is what the snap distance is measured against
		var pixels_per_value : float = (plot.size.y if sweep_y else plot.size.x) / (sweep_upper_bound - sweep_lower_bound)
		var crossings := find_curve_crossings(curve.points, curve.parameters, reading_at, sweep_y)
		
		#nothing crossed the cursor, but it can be sitting just past either end of the curve, in which case the reading
		#snaps onto the end point it is nearest
		if crossings.is_empty():
			var first_point := curve.points[0]
			var last_point := curve.points[curve.points.size() - 1]
			var first_along := first_point.y if sweep_y else first_point.x
			var last_along := last_point.y if sweep_y else last_point.x
			var nearest_end := first_along if absf(reading_at - first_along) < absf(reading_at - last_along) else last_along
			if absf(reading_at - nearest_end) * pixels_per_value <= spacing(hover_snap_distance):
				reading_at = nearest_end
				crossings = find_curve_crossings(curve.points, curve.parameters, reading_at, sweep_y)
		
		#the crossing is a place in value space: the sweep axis at the cursor, the across axis at the crossing, each
		#normalized the way the curve is on it
		var across_normalized := curve.normalize_x if sweep_y else curve.normalize_y
		var normalize_x : bool = across_normalized if sweep_y else sweep_normalized
		var normalize_y : bool = sweep_normalized if sweep_y else across_normalized
		
		for crossing_index : int in crossings.size():
			var crossing : Vector2 = crossings[crossing_index]
			var reading_value : Vector2 = Vector2(crossing.x, reading_at) if sweep_y else Vector2(reading_at, crossing.x)
			
			var reading := Reading.new()
			reading.color = curve.color
			#only the first crossing repeats the name, so a curve that doubles back reads as one group
			reading.name = curve.legend_name if crossing_index == 0 else ""
			reading.value = crossing.x
			reading.parameter = crossing.y
			reading.pixel = map_value_to_plot(reading_value, plot, x_axis_fit, y_axis_fit, normalize_x, normalize_y)
			readings.append(reading)
	
	return readings

#the points of the curves that pass within reach of the cursor, nearest first. the reading is the point on the curve the
#cursor is nearest, taken between the samples either side of it so it lands on the line
func nearest_curve_readings(plot : Rect2, x_axis_fit : AxisFit, y_axis_fit : AxisFit) -> Array[Reading]:
	var readings : Array[Reading] = []
	var sweep_y := readout_axis == ReadoutAxis.Y
	var reach : float = spacing(nearest_point_reach)
	
	for curve : CurveData in curves:
		if curve.points.size() < 2: continue
		
		var plot_points := map_curve_to_plot(curve.points, plot, x_axis_fit, y_axis_fit, curve.normalize_x, curve.normalize_y)
		var closest := closest_point_on_polyline(plot_points, hover_position)
		if closest.distance > reach: continue
		
		var index : int = closest.index
		var along : float = closest.along
		var across_start := curve.points[index].x if sweep_y else curve.points[index].y
		var across_end := curve.points[index + 1].x if sweep_y else curve.points[index + 1].y
		
		#a parameter only means anything when it lines up with the samples
		var parameter := NAN
		if curve.parameters.size() == curve.points.size():
			parameter = lerpf(curve.parameters[index], curve.parameters[index + 1], along)
		
		var reading := Reading.new()
		reading.color = curve.color
		reading.name = curve.legend_name
		reading.value = lerpf(across_start, across_end, along)
		reading.parameter = parameter
		reading.pixel = closest.pixel
		reading.distance = closest.distance
		readings.append(reading)
	
	readings.sort_custom(func(first : Reading, second : Reading) -> bool: return first.distance < second.distance)
	return readings

#where a polyline comes closest to a pixel: the point it lands on, the segment that point sits on and how far along it is
func closest_point_on_polyline(points : PackedVector2Array, pixel : Vector2) -> Dictionary:
	var closest := {"index": 0, "along": 0.0, "pixel": points[0], "distance": INF}
	for index : int in points.size() - 1:
		var start := points[index]
		var span := points[index + 1] - start
		var along := clampf((pixel - start).dot(span) / maxf(span.length_squared(), 0.000001), 0.0, 1.0)
		var point := start + span * along
		var distance := point.distance_to(pixel)
		if distance >= closest.distance: continue
		
		closest = {"index": index, "along": along, "pixel": point, "distance": distance}
	
	return closest

#the cursor's coordinates at the ends of its crosshair, inside the plot, pulled in so they never run off the edge or
#over each other
func draw_crosshair_values(plot : Rect2, x_axis_fit : AxisFit, y_axis_fit : AxisFit, cursor : Vector2) -> void:
	var ascent := font.get_ascent(font_size)
	var descent := font.get_descent(font_size)
	var line_height := ascent + descent
	var label_inset := spacing(tick_label_padding)
	var cursor_value := read_pixel_value(cursor, plot, x_axis_fit, y_axis_fit)
	
	#the baselines the x value is written on, one at the top of the plot and one at the bottom, and whether the plot is
	#tall enough to carry it at both ends
	var top_baseline := plot.position.y + label_inset + ascent
	var bottom_baseline := plot.end.y - label_inset - descent
	var x_value_at_both_ends : bool = plot.size.y > line_height * 2.0 + label_inset * 2.0
	
	#the x value, centered on the vertical line and pulled in so it never runs off the plot's edge
	var x_text := format_tick_label(cursor_value.x, x_axis_fit.step * hover_step_fraction, x_axis_fit.label_scale)
	var x_text_width := measure_text_width(x_text)
	var x_text_left := clampf(cursor.x - x_text_width * 0.5, plot.position.x + label_inset, plot.end.x - label_inset - x_text_width)
	draw_string(font, Vector2(x_text_left, top_baseline), x_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
	if x_value_at_both_ends:
		draw_string(font, Vector2(x_text_left, bottom_baseline), x_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
	
	#the y value, centered on the horizontal line and kept a line clear of the x value where that still leaves it room
	var y_text := format_tick_label(cursor_value.y, y_axis_fit.step * hover_step_fraction, y_axis_fit.label_scale)
	var y_text_width := measure_text_width(y_text)
	var clear_of_x_value := line_height if x_value_at_both_ends and bottom_baseline - top_baseline > line_height * 2.0 else 0.0
	var y_text_baseline := clampf(cursor.y + (ascent - descent) * 0.5, top_baseline + clear_of_x_value, bottom_baseline - clear_of_x_value)
	draw_string(font, Vector2(plot.position.x + label_inset, y_text_baseline), y_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
	if plot.size.x > y_text_width * 2.0 + label_inset * 2.0:
		draw_string(font, Vector2(plot.end.x - label_inset - y_text_width, y_text_baseline), y_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)

#the cursor: a crosshair through the plot, a dot on every reading under it, and the plate of values beside it
func draw_cursor(plot : Rect2, x_axis_fit : AxisFit, y_axis_fit : AxisFit, readout_band : Rect2) -> void:
	readout_plate_rect = Rect2()
	if not cursor_reach(plot).has_point(hover_position): return
	
	var cursor := cursor_pixel(plot)
	if show_crosshair:
		draw_line(Vector2(cursor.x, plot.position.y), Vector2(cursor.x, plot.end.y), hover_line_color)
		draw_line(Vector2(plot.position.x, cursor.y), Vector2(plot.end.x, cursor.y), hover_line_color)
	
	var readings : Array[Reading] = cursor_readings(plot, x_axis_fit, y_axis_fit) if readout_mode == ReadoutMode.CROSSHAIR else nearest_curve_readings(plot, x_axis_fit, y_axis_fit)
	var drawing_rect := plot_drawing_rect(plot)
	for reading : Reading in readings:
		#a reading whose value is off the axis has its dot off the plot as well, but is still reported
		if not drawing_rect.has_point(reading.pixel): continue
		draw_circle(reading.pixel, spacing(dot_radius), reading.color, true, -1.0, antialiased)
	
	if show_crosshair_values:
		draw_crosshair_values(plot, x_axis_fit, y_axis_fit, cursor)
	
	#the readout is about where the cursor is, or about the point it found on the nearest curve
	var readout_pixel := cursor
	if readout_mode == ReadoutMode.NEAREST_POINT and not readings.is_empty(): readout_pixel = readings[0].pixel
	if show_readout: draw_readout(plot, x_axis_fit, y_axis_fit, readings, readout_pixel, readout_band)

#the plate of values beside the cursor: the position being read on the swept axis, then a row for every curve found
#there
func draw_readout(plot : Rect2, x_axis_fit : AxisFit, y_axis_fit : AxisFit, readings : Array[Reading], pixel : Vector2, readout_band : Rect2) -> void:
	var sweep_y := readout_axis == ReadoutAxis.Y
	var sweep_fit : AxisFit = y_axis_fit if sweep_y else x_axis_fit
	var across_fit : AxisFit = x_axis_fit if sweep_y else y_axis_fit
	var sweep_label := y_label if sweep_y else x_label
	var cursor_value := read_pixel_value(pixel, plot, x_axis_fit, y_axis_fit)
	var sweep_value : float = cursor_value.y if sweep_y else cursor_value.x
	
	#the cursor's row carries no color, and every row under it carries the color of the curve it reports
	var row_names : Array[String] = [sweep_label if sweep_label != "" else ("y" if sweep_y else "x")]
	var row_values : Array[String] = [format_tick_label(sweep_value, sweep_fit.step * hover_step_fraction, sweep_fit.label_scale)]
	var row_parameters : Array[String] = [parameter_label]
	var row_colors : Array[Color] = [Color(0.0, 0.0, 0.0, 0.0)]
	for reading : Reading in readings:
		row_names.append(reading.name)
		row_values.append(format_tick_label(reading.value, across_fit.step * hover_step_fraction, across_fit.label_scale) + readout_value_suffix)
		row_parameters.append("" if is_nan(reading.parameter) else String.num(reading.parameter, hover_parameter_decimals))
		row_colors.append(reading.color)
	
	#a readout in the band above the plot is laid out in a line, because its band is one row tall
	var in_band := readout_is_above()
	var in_a_row := readout_horizontal or in_band
	var column_gap := spacing(readout_column_gap)
	#the swatch column is reserved whether a row carries one or not
	var swatch_width := spacing(legend_swatch_size.x) + spacing(legend_swatch_gap)
	var value_column_width := widest_value_width(x_axis_fit, y_axis_fit)
	var parameter_column_width := widest_parameter_width()
	var has_parameters := parameter_column_width > 0.0
	
	#the columns are sized from what they can hold at all, not from what they hold right now, so the numbers changing
	#under the cursor don't make the plate flicker. an entry is a name, its value and the parameter it was taken at
	var row_name_widths : Array[float] = []
	var entry_widths : Array[float] = []
	var widest_name_width := 0.0
	var widest_entry_width := 0.0
	var lined_up_width := 0.0
	for row : int in row_names.size():
		var row_name_width := measure_text_width(row_names[row])
		var entry_width := swatch_width + row_name_width + column_gap + value_column_width
		if has_parameters: entry_width += column_gap + parameter_column_width
		
		row_name_widths.append(row_name_width)
		entry_widths.append(entry_width)
		widest_name_width = maxf(widest_name_width, row_name_width)
		widest_entry_width = maxf(widest_entry_width, entry_width)
		lined_up_width += entry_width
	
	#stacked, the entries share the widest set of columns; laid out along a line, each is only as wide as its own name
	var plate_width := widest_entry_width
	var plate_height := plate_row_height()
	if in_a_row: plate_width = lined_up_width + spacing(plate_entry_gap) * maxf(0.0, row_names.size() - 1.0)
	else: plate_height *= row_names.size()
	
	var plate_size := Vector2(plate_width + spacing(plate_padding) * 2.0, plate_height + spacing(plate_padding) * 2.0)
	var keep_clear : Array[Rect2] = []
	if readout_dodges_markers: keep_clear.append(marker_plate_rect)
	
	#a readout with a band of its own sits at the right end of it, where it covers nothing of the plot
	var plate : Rect2
	if in_band:
		plate = Rect2(Vector2(maxf(readout_band.position.x, readout_band.end.x - plate_size.x), readout_band.position.y), plate_size)
	else:
		plate = Rect2(plate_corner_position(readout_placement, plate_size, plot, keep_clear), plate_size)
	readout_plate_rect = plate
	draw_style_box(get_theme_stylebox("panel", "TooltipPanel"), plate)
	
	#each row takes its turn along the plate: one under the last when stacked, one beside the last when lined up
	var row_left := plate.position.x + spacing(plate_padding)
	for row : int in row_names.size():
		var baseline := plate_row_baseline(plate.position.y, 0 if in_a_row else row)
		var name_width : float = row_name_widths[row] if in_a_row else widest_name_width
		var name_left := row_left + swatch_width
		if row_colors[row].a > 0.0:
			var swatch_y := baseline - (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
			draw_line(Vector2(row_left, swatch_y), Vector2(row_left + spacing(legend_swatch_size.x), swatch_y), row_colors[row], spacing(legend_swatch_size.y))
		var value_left := name_left + name_width + column_gap
		
		draw_string(font, Vector2(name_left, baseline), row_names[row], HORIZONTAL_ALIGNMENT_LEFT, name_width, font_size, text_color)
		draw_string(font, Vector2(value_left, baseline), row_values[row], HORIZONTAL_ALIGNMENT_RIGHT, value_column_width, font_size, text_color)
		if has_parameters:
			draw_string(font, Vector2(value_left + value_column_width + column_gap, baseline), row_parameters[row], HORIZONTAL_ALIGNMENT_RIGHT, parameter_column_width, font_size, text_color)
		if in_a_row: row_left += entry_widths[row] + spacing(plate_entry_gap)

#written after every value the readout reports for a curve, which is where the unit of those values goes
var readout_value_suffix := ""

#the width the widest value the readout can report comes to
func widest_value_width(x_axis_fit : AxisFit, y_axis_fit : AxisFit) -> float:
	var widest_x : float = maxf(absf(x_axis_fit.lower_bound), absf(x_axis_fit.upper_bound))
	var widest_y : float = maxf(absf(y_axis_fit.lower_bound), absf(y_axis_fit.upper_bound))
	return maxf(
		measure_text_width(format_tick_label(-widest_x, x_axis_fit.step * hover_step_fraction, x_axis_fit.label_scale, true) + readout_value_suffix),
		measure_text_width(format_tick_label(-widest_y, y_axis_fit.step * hover_step_fraction, y_axis_fit.label_scale, true) + readout_value_suffix),
	)

#the width of the widest parameter any curve could report. a number is only wider for having more digits, so the lowest and
#the highest of the range are all there is to measure
func widest_parameter_width() -> float:
	var lowest_parameter := INF
	var highest_parameter := -INF
	for curve : CurveData in curves:
		for curve_parameter : float in curve.parameters:
			lowest_parameter = minf(lowest_parameter, curve_parameter)
			highest_parameter = maxf(highest_parameter, curve_parameter)
	
	#a graph with no parameters anywhere gets no column, and no room is reserved for one
	if is_inf(lowest_parameter): return 0.0
	
	return maxf(
		measure_text_width(parameter_label),
		maxf(
			measure_text_width(String.num(lowest_parameter, hover_parameter_decimals)),
			measure_text_width(String.num(highest_parameter, hover_parameter_decimals)),
		),
	)













#utils
#both come from https://github.com/addmix/godot_utils (globals/math_utils.gd)
static func log_with_base(value : float, base : float) -> float:
	return log(value) / log(base)







#utils that have no home in godot_utils yet
#the size every spacing setting was measured at, which spacing() brings each one from
var reference_font_size := 16.0

#a spacing given in pixels at the reference size, brought to the size the text is actually drawn at
func spacing(pixels : float) -> float:
	return pixels * float(font_size) / reference_font_size

#draw_string advances a whole pixel per glyph when subpixel positioning is off, so the measured width is up to half a
#pixel per character narrower than what actually gets drawn
func measure_text_width(text : String) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + text.length() * 0.5

#the points of a curve in the packed form the drawing works from. anything that is not a point is dropped, so a mixed
#array does not throw
static func to_packed_points(points : Variant) -> PackedVector2Array:
	var packed := PackedVector2Array()
	match typeof(points):
		TYPE_PACKED_VECTOR2_ARRAY:
			packed = points
		TYPE_ARRAY:
			var plain : Array = points
			for point : Variant in plain:
				if point is Vector2 or point is Vector2i: packed.append(Vector2(point))
	return packed


#a tick step is written with no more decimals than this, however fine it has to be
var max_tick_decimals := 6

#the text under a tick, or, with the decimals kept, the widest a value on that axis can be measured as
func format_tick_label(value : float, tick_step : float, label_scale : float, pad_decimals : bool = false) -> String:
	var scaled_value : float = value / label_scale
	var scaled_step : float = tick_step / label_scale
	#a tick that is nothing is written as such, without a sign or a unit, but one that is only small is still its own number
	if absf(scaled_value) <= absf(scaled_step) * 1e-6: return "0"
	
	#as many decimals as it takes to write the step exactly, so neighboring labels never round into the same text
	var decimals := maxi(0, int(ceilf(-log_with_base(scaled_step, 10.0))))
	scaled_step *= pow(10.0, decimals)
	while decimals < max_tick_decimals and not is_zero_approx(scaled_step - roundf(scaled_step)):
		scaled_step *= 10.0
		decimals += 1
	
	var number_text := String.num(scaled_value, decimals)
	if pad_decimals: number_text = number_text.pad_decimals(decimals)
	
	var suffix := ""
	if label_scale == million_scale: suffix = "M"
	elif label_scale == thousand_scale: suffix = "k"
	
	return number_text + suffix

#both values of a dot, for its row in the readout, written out in full so close dots can be told apart
func describe_values(marker_value : Vector2, x_axis_fit : AxisFit, y_axis_fit : AxisFit) -> String:
	return "x %s  y %s" % [
		format_tick_label(marker_value.x, x_axis_fit.step * hover_step_fraction, x_axis_fit.label_scale),
		format_tick_label(marker_value.y, y_axis_fit.step * hover_step_fraction, y_axis_fit.label_scale),
	]

#the values a pixel on the plot stands for, the inverse of map_value_to_plot. a dot drawn at a pixel, like an
#intersection, is read back through it
func read_pixel_value(pixel : Vector2, plot : Rect2, x_axis_fit : AxisFit, y_axis_fit : AxisFit) -> Vector2:
	return Vector2(
		remap(pixel.x, plot.position.x, plot.end.x, x_axis_fit.lower_bound, x_axis_fit.upper_bound),
		remap(pixel.y, plot.end.y, plot.position.y, y_axis_fit.lower_bound, y_axis_fit.upper_bound),
	)

#the power of ten a step is measured in, with a step that is exactly one of them read as the power itself rather than the one
#below it: log10 of a power of ten can come back a hair under it, which would leave 1000000 read as ten hundred thousand
static func step_magnitude(step : float) -> float:
	return pow(10.0, floorf(log_with_base(step, 10.0) + 1e-9))

#the round step nearest the one asked for, 1, 2 or 5 times a power of ten, which is what makes every tick label on an axis
#a round number
static func nearest_nice_step(raw_step : float) -> float:
	if raw_step <= 0.0: return 1.0
	
	var magnitude := step_magnitude(raw_step)
	var best := magnitude
	for candidate : float in [magnitude, magnitude * 2.0, magnitude * 5.0, magnitude * 10.0]:
		if absf(candidate - raw_step) < absf(best - raw_step): best = candidate
	
	return best

#the round step after this one, 1 to 2 to 5 to 10, which is how an axis is given fewer ticks
static func next_nice_step(step : float) -> float:
	var magnitude := step_magnitude(step)
	var normalized_step := step / magnitude
	if normalized_step < 1.5: return magnitude * 2.0
	if normalized_step < 3.5: return magnitude * 5.0
	
	return magnitude * 10.0

#the round step before this one, 10 to 5 to 2 to 1, which is how an axis is given more ticks
static func previous_nice_step(step : float) -> float:
	var magnitude := step_magnitude(step)
	var normalized_step := step / magnitude
	if normalized_step > 5.5: return magnitude * 5.0
	if normalized_step > 2.5: return magnitude * 2.0
	if normalized_step > 1.5: return magnitude
	
	return magnitude * 0.5
