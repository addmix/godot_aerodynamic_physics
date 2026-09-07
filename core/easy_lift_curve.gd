@tool
extends Curve
class_name LiftCurve

@export_tool_button("Recalculate") var action := recalculate
@export_range(0.0, 2.0, 0.01, "or_greater", "exp") var lift_coefficient : float = 1.2 :
	set(x):
		lift_coefficient = x
		recalculate()
@export_range(0.0, 30.0, 0.5, "or_greater") var lift_slope : float = 15.0 : 
	set(x):
		lift_slope = x
		recalculate()
@export_range(0.0, 1.0, 0.05, "exp") var camber : float = 0.0 :
	set(x):
		camber = x
		recalculate()
@export_range(0.0, 20.0, 0.5) var stall_region_size : float = 10.0 : 
	set(x):
		stall_region_size = x
		recalculate()
#@export_range(0.0, 1.0, 0.01) var stall_lift : float = 0.8 : 
	#set(x):
		#stall_lift = x
		#recalculate()
@export_range(0.0, 1.0, 0.01) var post_stall_lift : float = 0.6 : 
	set(x):
		post_stall_lift = x
		recalculate()
@export_range(0.0, 1.0, 0.01) var reverse_lift_penalty : float = 0.3 : 
	set(x):
		reverse_lift_penalty = x
		recalculate()

func _init() -> void:
	recalculate()

func recalculate() -> void:
	min_domain = -180
	max_domain = 180
	min_value = -20
	max_value = 20
	
	clear_points()
	
	#this math is so that the -180/180 (left and right ends of curve) wrap correctly
	var size = lift_slope - -lift_slope
	var offset = lift_slope + -lift_slope
	var crossover_height : float = remap(offset, -lift_slope, lift_slope, 1, -1)
	var slope = Vector2(0.5 * size, lift_coefficient)
	
	#lift slope
	add_point(Vector2(min_domain, crossover_height), 0, 0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	add_point(Vector2(min_domain + lift_slope, lift_coefficient) - (slope * camber) - (slope * reverse_lift_penalty), 0, 0, Curve.TANGENT_LINEAR)
	#full stall
	#add_point(Vector2(min_domain + lift_slope + stall_region_size, stall_lift))
	add_point(Vector2(min_domain + 45, post_stall_lift))
	add_point(Vector2(-45, -post_stall_lift))
	#add_point(Vector2(-lift_slope - stall_region_size, -stall_lift))
	#lift slope
	add_point(Vector2(-lift_slope, -lift_coefficient) + (slope * camber), 0, 0, Curve.TANGENT_FREE, Curve.TANGENT_LINEAR)
	add_point(Vector2(lift_slope, lift_coefficient) + (slope * camber), 0, 0, Curve.TANGENT_LINEAR, Curve.TANGENT_FREE,)
	#full stall
	#add_point(Vector2(lift_slope + stall_region_size, stall_lift))
	add_point(Vector2(45, post_stall_lift))
	add_point(Vector2(max_domain - 45, -post_stall_lift))
	#add_point(Vector2(max_domain + -lift_slope - stall_region_size, -stall_lift))
	#lift slope
	add_point(Vector2(max_domain + -lift_slope, -lift_coefficient) - (slope * camber) + (slope * reverse_lift_penalty), 0, 0, Curve.TANGENT_FREE, Curve.TANGENT_LINEAR)
	add_point(Vector2(max_domain, crossover_height), 0, 0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	
	var abs_max_value := 0.0
	for point in point_count:
		var value := get_point_position(point).y
		abs_max_value = max(abs_max_value, abs(value))
		
	
	min_value = -abs_max_value
	max_value = abs_max_value
