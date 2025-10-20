@tool
extends Resource
class_name AeroSurfaceConfig

@export_group("Wing profile")
##Represents the length of the AeroSurface3D on the Z axis.
@export_range(0.0, 100.0, 0.001, "or_greater", "exp", "suffix:m") var chord : float = 1.0:
	set(value):
		chord = abs(value)
		emit_changed()

##Represents the width of the AeroSurface3D on the X axis.
@export_range(0.0, 100.0, 0.001, "or_greater", "exp", "suffix:m") var span : float = 2.0:
	set(value):
		span = abs(value)
		emit_changed()
##Aspect ratio of the AeroSurface. This is the ratio of span and chord.
@export_range(0.0, 1000.0, 0.01, "or_greater", "exp", "suffix:m^2") var area : float = 2.0:
	set = set_area, get = get_area
func get_area() -> float:
	return span * chord
func set_area(_area : float) -> void:
	var _aspect_ratio := aspect_ratio
	
	var _span = _aspect_ratio * chord / sqrt(area) * sqrt(_area)
	var _chord = span / _aspect_ratio / sqrt(area) * sqrt(_area)
	
	if is_equal_approx(_span, 0.0) or is_equal_approx(_chord, 0.0):
		return
	
	span = _span
	chord = _chord
@export_range(0.0, 100.0, 0.001, "or_greater", "exp", "suffix:%") var aspect_ratio : float = 2.0:
	set = set_aspect_ratio, get = get_aspect_ratio
func set_aspect_ratio(_aspect_ratio : float) -> void:
	var _area := area
	
	var _span = sqrt(_aspect_ratio * _area)
	var _chord = sqrt(_area) / sqrt(_aspect_ratio)
	
	if is_equal_approx(_span, 0.0) or is_equal_approx(_chord, 0.0):
		return
	
	span = _span
	chord = _chord
func get_aspect_ratio() -> float:
	return span / chord
@export_group("")

func _init(_chord : float = 1.0, _span : float = 2.0) -> void:
	chord = _chord
	span = _span
