extends AeroInfluencer3D
class_name AeroBuoyancy3D

var center_of_pressure : Vector3
var buoyancy_force : Vector3

var cached_force : Vector3 = Vector3.ZERO
var cached_torque : Vector3 = Vector3.ZERO
func _calculate_forces(substep_delta : float = 0.0) -> PackedVector3Array:
	var force_and_torque : PackedVector3Array = super._calculate_forces(substep_delta)
	
	if aero_body.current_substep == 0:
		#there is no benefit to calculating buoyancy every substep, as transforms and areas only update every physics step
		calculate_buoyancy()
		
		cached_force = buoyancy_force
		cached_torque = (relative_position + center_of_pressure).cross(buoyancy_force)
		
		_current_force = cached_force
		_current_torque = cached_torque
		
		return PackedVector3Array([force_and_torque[0] + cached_force, force_and_torque[1] + cached_torque])
	
	return PackedVector3Array([force_and_torque[0] + cached_force, force_and_torque[1] + cached_torque])

#This function should be overridden to compute center_of_pressure and buoyant_force
func calculate_buoyancy() -> void:
	pass
