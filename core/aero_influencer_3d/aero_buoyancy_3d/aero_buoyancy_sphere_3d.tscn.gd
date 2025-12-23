@tool
extends AeroBuoyancy3D
class_name AeroBuoyancySphere3D

@export var radius : float = 1.0


func calculate_buoyancy() -> void:
	center_of_pressure = Vector3.ZERO
	buoyancy_force = Vector3.ZERO
	
	for atmosphere : AeroAtmosphere3D in aero_body.atmosphere_areas:
			if not atmosphere.per_influencer_positioning:
				# use precomputed center of pressure?
				continue
			
			var submerged_height : float = min(atmosphere.get_distance_to_surface(global_position) - radius, 0.0) #incomplete
			#calculate submerged volume of sphere
			var submerged_volume : float = ((PI * submerged_height * submerged_height) / 3.0) * (3.0 * radius - submerged_height)
			
			var force : Vector3 = atmosphere.density * -aero_body.current_gravity * submerged_volume
			buoyancy_force += force
