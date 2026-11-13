@tool
extends PanelContainer
class_name AeroGraph

@export_tool_button("Recalc") var generate_action = generate

func generate():
	queue_redraw()

@export var title : String = ""
@export var data : Dictionary[Color, PackedVector2Array] = {}

@export var lower_bound := Vector2(-180, -180)
@export var upper_bound := Vector2(180, 180)
@export var margin : int = 4

@export var horizontal_lines : int = 12
@export var vertical_lines : int = 12
@export var background_line_color := Color(1.0, 1.0, 1.0, 0.1)
@export var font : Font = make_default_font()
func make_default_font() -> Font:
	var _font = SystemFont.new()
	_font.font_names.append("Monospace")
	return _font


func _draw() -> void:
	var _upper_bound := upper_bound * Vector2(1, -1)
	var _lower_bound := lower_bound * Vector2(1, -1)
	
	#scale y axis to fit all data
	var max_magnitude : float = 0.0
	for dataset : PackedVector2Array in data.values():
		for datapoint : Vector2 in dataset:
			#print(datapoint)
			max_magnitude = max(abs(datapoint.y), max_magnitude)
	
	_upper_bound.y = min(_upper_bound.y, -max_magnitude)
	_lower_bound.y = max(_lower_bound.y, max_magnitude)
	
	var domain = _upper_bound - _lower_bound
	var center = (_upper_bound + _lower_bound) / 2.0
	var coord = domain - center
	
	var label_size := Vector2(36, 16)
	var left_label_offset := Vector2(-label_size.x - margin, label_size.y * 0.5)
	var bottom_label_offset := Vector2(-label_size.x * 0.5, label_size.y)
	
	var _margin := Vector2.ONE * margin
	var grid_start := Vector2(label_size.x, label_size.y * 0.5) + _margin
	var grid_end := get_rect().size - _margin - Vector2(label_size.x * 0.5, label_size.y + margin)
	var grid_size := grid_end - grid_start
	
	#draw grid
	for x in vertical_lines + 1:
		var x_coord := x / float(horizontal_lines)
		var top := grid_start + Vector2(x_coord, 0) * grid_size
		var bottom := grid_start + Vector2(x_coord, 1) * grid_size
		draw_line(top, bottom, background_line_color)
		draw_string(font, bottom + bottom_label_offset, String.num(remap(x_coord, 0, 1, _lower_bound.x, _upper_bound.x), 0), HORIZONTAL_ALIGNMENT_CENTER, label_size.x)
	for y in horizontal_lines + 1:
		var y_coord := y / float(vertical_lines)
		var left := grid_start + Vector2(0, y / float(vertical_lines)) * grid_size
		var right := grid_start + Vector2(1, y / float(vertical_lines)) * grid_size
		draw_line(left, right, background_line_color)
		draw_string(font, left + left_label_offset, String.num(remap(y_coord, 0, 1, _lower_bound.y, _upper_bound.y), 0), HORIZONTAL_ALIGNMENT_RIGHT, label_size.x)
	
	for data_color : Color in data.keys():
		var dataset : PackedVector2Array = data[data_color]
		#process data to fit in bounds
		var processed_data := PackedVector2Array()
		for point : Vector2 in dataset:
			processed_data.append(
				Vector2(
					remap(point.x, _lower_bound.x, _upper_bound.x, grid_start.x, grid_end.x),
					remap(point.y, _lower_bound.y, _upper_bound.y, grid_start.y, grid_end.y)
				)
			)
		draw_polyline(processed_data, data_color)
	
	#draw title
	draw_string(font, grid_start + Vector2(0, label_size.y) + _margin, title)
