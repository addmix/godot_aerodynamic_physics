@tool
extends VBoxContainer


func _on_editor_scene_changed(scene_root : Node) -> void:
	if not is_visible_in_tree(): return
	
	if scene_root is AeroBody3D:
		aerobody = scene_root

var aerobody : AeroBody3D = null:
	set(x):
		if aerobody == x: return
		
		aerobody = x
		
		if aerobody:
			recalculate()

func recalculate() -> void:
	%AircraftName.text = aerobody.name
	
	var angles_to_simulate : int = 256
	
	var pitch_moment_x := PackedVector2Array()
	var pitch_moment_y := PackedVector2Array()
	var pitch_moment_z := PackedVector2Array()
	for simulation : int in range(angles_to_simulate + 1):
		var angle = remap(simulation, 0, angles_to_simulate, -180, 180)
		var transform := Transform3D(Basis.from_euler(Vector3(deg_to_rad(angle), 0, 0)), Vector3.ZERO)
		var force_and_torque = aerobody.calculate_forces_manual(transform, Vector3(0, 0, -250), Vector3.ZERO)
		
		pitch_moment_x.append(Vector2(angle, force_and_torque[1].x))
		pitch_moment_y.append(Vector2(angle, force_and_torque[1].y))
		pitch_moment_z.append(Vector2(angle, force_and_torque[1].z))
	
	%PitchMomentsGraph.data[Color("Red")] = pitch_moment_x
	%PitchMomentsGraph.data[Color("Green")] = pitch_moment_y
	%PitchMomentsGraph.data[Color("Blue")] = pitch_moment_z
	%PitchMomentsGraph.queue_redraw()
	
	var sideslip_moment_x := PackedVector2Array()
	var sideslip_moment_y := PackedVector2Array()
	var sideslip_moment_z := PackedVector2Array()
	for simulation : int in range(angles_to_simulate + 1):
		var angle = remap(simulation, 0, angles_to_simulate, -180, 180)
		var transform := Transform3D(Basis.from_euler(Vector3(0, deg_to_rad(angle), 0)), Vector3.ZERO)
		var force_and_torque = aerobody.calculate_forces_manual(transform, Vector3(0, 0, -250), Vector3.ZERO)
		
		sideslip_moment_x.append(Vector2(angle, force_and_torque[1].x))
		sideslip_moment_y.append(Vector2(angle, force_and_torque[1].y))
		sideslip_moment_z.append(Vector2(angle, force_and_torque[1].z))
	
	%SideslipMomentsGraph.data[Color("Red")] = sideslip_moment_x
	%SideslipMomentsGraph.data[Color("Green")] = sideslip_moment_y
	%SideslipMomentsGraph.data[Color("Blue")] = sideslip_moment_z
	%SideslipMomentsGraph.queue_redraw()


func _on_recalculate_button_pressed() -> void:
	recalculate()
