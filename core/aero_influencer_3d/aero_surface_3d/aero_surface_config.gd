@tool
extends Resource
class_name AeroSurfaceConfig

@export_group("Wing profile")
##Represents the length of the AeroSurface3D on the Z axis.
@export var chord : float = 1.0:
	set(value):
		chord = max(value, 0.001)
		if auto_aspect_ratio:
			aspect_ratio = span / chord
		emit_changed()
##Represents the width of the AeroSurface3D on the X axis.
@export var span : float = 2.0:
	set(value):
		span = value
		if auto_aspect_ratio:
			aspect_ratio = span / chord
		emit_changed()
##If disabled, span or chord will be modified to maintain the given aspect ratio.
@export var auto_aspect_ratio : bool = true:
	set(value):
		auto_aspect_ratio = value
		if auto_aspect_ratio:
			aspect_ratio = span / chord
		emit_changed()
##Aspect ratio of the AeroSurface. This is the ratio of span and chord.
@export var aspect_ratio : float = 2.0:
	set(value):
		aspect_ratio = value
		if !auto_aspect_ratio:
			#keep area
			var current_area : float = span * chord
		emit_changed()
@export_group("")

func _init(_chord : float = 1.0, _span : float = 2.0, _auto_aspect_ratio : bool = true, _aspect_ratio : float = 2.0) -> void:
	chord = _chord
	span = _span
	auto_aspect_ratio = _auto_aspect_ratio
	aspect_ratio = _aspect_ratio
