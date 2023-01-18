@tool
extends Node3D
class_name AeroSurface3D

enum {Pitch, Yaw, Roll, Flap}

@export var wing_config : AeroSurfaceConfig = AeroSurfaceConfig.new():
	set(value):
		wing_config = value
		if wing_config == null:
			return
		if not wing_config.is_connected("changed", update_gizmos):
			wing_config.changed.connect(update_gizmos)
			update_gizmos()

@export_group("")
@export var flap_angle : float = 0.0:
	set(value):
		flap_angle = clamp(value, deg_to_rad(-50), deg_to_rad(50))

var world_air_velocity := Vector3.ZERO
var air_density := 0.0
var air_pressure := 0.0
var relative_position := Vector3.ZERO
var altitude := 0.0

#Calculating air velocity relative to the surface's coordinate system.
var air_velocity := Vector3.ZERO
var sweep_angle := 0.0
var drag_direction := Vector3.ZERO
var lift_direction := Vector3.ZERO

var mach : float = 0.0
var dynamic_pressure : float = 0.0
var angle_of_attack : float = 0.0
var area : float = wing_config.chord * wing_config.span
var projected_wing_area : float = 0.0

var _current_lift : Vector3
var _current_drag : Vector3
var _current_torque : Vector3

func _process(delta: float) -> void:
	#do wing debug vectors
	pass

func _enter_tree() -> void:
	#initialize signal connections from resources
	if wing_config != null:
		if not wing_config.is_connected("changed", update_gizmos):
			wing_config.changed.connect(update_gizmos)
			update_gizmos()

#They found that with increase in Mach number the coefficient of lift increases but
#coefficient of drag remains constant. In the current study the effects of air velocity
#and angle of attack on aerodynamic parameters across NACA6415 airfoil are investigated.


func calculate_forces(_world_air_velocity : Vector3, _air_density : float, _air_pressure : float, _relative_position : Vector3, _altitude : float) -> PackedVector3Array:
	world_air_velocity = _world_air_velocity
	air_density = _air_density
	air_pressure = _air_pressure
	relative_position = _relative_position
	altitude = _altitude
	calculate_properties()

	return PackedVector3Array([Vector3.ZERO, Vector3.ZERO])

func calculate_properties() -> void:
	#Calculating air velocity relative to the surface's coordinate system.
	air_velocity = global_transform.basis.inverse() * world_air_velocity
	sweep_angle =  atan2(air_velocity.z, air_velocity.x) / PI - 0.5
	drag_direction = global_transform.basis * (air_velocity.normalized())
	lift_direction = drag_direction.cross(-global_transform.basis.x)

	mach = AeroUnits.speed_to_mach_at_altitude(air_velocity.length(), altitude)
	dynamic_pressure = (mach * mach) * 0.5 * AeroUnits.ratio_of_specific_heat * AeroUnits.get_pressure_at_altitude(altitude)
	angle_of_attack = atan2(air_velocity.y, air_velocity.z)
	area = wing_config.chord * wing_config.span
	projected_wing_area = wing_config.span * wing_config.chord * sin(angle_of_attack)

func update_debug_vectors() -> void:
	pass
