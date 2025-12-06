@tool
extends AeroAtmosphere3D
class_name AeroWaterAtmosphere3D

func _init() -> void:
	super._init()
	#this will be reenabled even if the user disables the setting in the inspector
	#find a fix eventually
	per_influencer_positioning = true
	override_density = true
	density = 1000.0
	override_wind = true

#this should be overridden to match a wave displacement shader
func get_surface_height(_position : Vector3) -> float:
	return 0.0

#when under the surface, the result will be negative.
#when above the surface, the result will be positive.
#direction should be a negative gravity direction, but it's unused for now.
func get_distance_to_surface(_position : Vector3, direction : Vector3 = Vector3(0, 1, 0)) -> float:
	return _position.y - global_position.y - get_surface_height(_position)

func get_density_at_position(_position : Vector3) -> float:
	#under surface
	#this density logic should probably be done on the AeroInfluencer instead, as the aeroinfluencer
	#may have a size that causes partial submersion.
	if get_distance_to_surface(_position) <= 0.0:
		return density
	#above surface
	else:
		return 1.225
