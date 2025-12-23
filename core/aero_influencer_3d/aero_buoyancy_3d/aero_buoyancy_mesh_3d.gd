@tool
extends AeroBuoyancy3D
class_name AeroBuoyancyMesh3D

@export_tool_button("Recalculate mesh data") var action = calculate_mesh_data
@export var buoyancy_mesh : Mesh:
	set(x):
		buoyancy_mesh = x
		calculate_mesh_data()
		if buoyancy_mesh_debug:
			buoyancy_mesh_debug.mesh = buoyancy_mesh

@export var skin_friction : float = 0.02
@export var aero_force_multiplier : float = 1.0

@export var show_buoyancy_mesh_debug : bool = true
var buoyancy_mesh_debug : MeshInstance3D

#vertex buoyancy coefficients are the vertex normals, and the length is the "area" of the vertex.
var vertex_positions : PackedVector3Array
var vertex_buoyancy_coefficients : PackedVector3Array
var vertex_sizes : PackedFloat64Array

func _init() -> void:
	super._init()
	
	buoyancy_mesh_debug = MeshInstance3D.new()
	if buoyancy_mesh:
		buoyancy_mesh_debug.mesh = buoyancy_mesh
	
	var debug_material := StandardMaterial3D.new()
	debug_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	debug_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	debug_material.albedo_color.a = 0.1
	buoyancy_mesh_debug.material_override = debug_material
	buoyancy_mesh_debug.visible = false

func _ready() -> void:
	super._ready()
	
	add_child(buoyancy_mesh_debug, INTERNAL_MODE_FRONT)

func update_debug_visibility(_show_debug : bool = false) -> void:
	super.update_debug_visibility(_show_debug)
	
	buoyancy_mesh_debug.visible = show_debug and show_buoyancy_mesh_debug

func calculate_mesh_data() -> void:
	vertex_positions = []
	vertex_buoyancy_coefficients = []
	
	if not buoyancy_mesh:
		return
	
	var arrays : Array = buoyancy_mesh.surface_get_arrays(0)
	
	#print("Vertex:\n", arrays[Mesh.ARRAY_VERTEX], "\n")
	#print("Normal:\n", arrays[Mesh.ARRAY_NORMAL], "\n")
	#print("Index:\n", arrays[Mesh.ARRAY_INDEX], "\n\n\n\n")
	
	#Vertex/index deduplication
	var sanitized_vertices : PackedVector3Array = []
	var sanitized_indices : PackedInt32Array = arrays[Mesh.ARRAY_INDEX].duplicate()
	
	for index : int in arrays[Mesh.ARRAY_VERTEX].size():
		var vertex : Vector3 = arrays[Mesh.ARRAY_VERTEX][index]
		#search for the given vertex position in the array
		var found_index : int = sanitized_vertices.find(vertex)
		if found_index == -1: #vertex doesn't have a match in the sanitized array (isn't a duplicate yet)
			sanitized_vertices.append(vertex)
			found_index = sanitized_vertices.size() - 1
		
		#Indices must be modified to point to the new, deduplicated vertex positions index in the sanitized array.
		var number_of_index_references : int = sanitized_indices.count(index)
		var last_index_used : int = 0
		for duplicate_index_iteration : int in number_of_index_references:
			var index_reference_found_at : int = sanitized_indices.find(index, last_index_used)
			sanitized_indices[index_reference_found_at] = found_index
			last_index_used = index_reference_found_at + 1
	
	#schema: key is the vertex index from the sanitized vertices array
	#value is an array of index offsets to define which triangles the given vertex is a component of.
	var vertex_triangle_affiliation_index_array : Dictionary[int, PackedInt32Array] = {}
	
	for vertex_index : int in sanitized_vertices.size():
		var triangle_index_offset_array : PackedInt32Array = []
		
		var number_of_triangles_using_this_vertex : int = sanitized_indices.count(vertex_index)
		var last_used_triangle_index : int = 0
		for triangle_index_iteration : int in number_of_triangles_using_this_vertex:
			var vertex_reference_found_at : int = sanitized_indices.find(vertex_index, last_used_triangle_index)
			
			triangle_index_offset_array.append((vertex_reference_found_at - (vertex_reference_found_at % 3)) / 3)
			last_used_triangle_index = vertex_reference_found_at + 1
		
		vertex_triangle_affiliation_index_array[vertex_index] = triangle_index_offset_array
		#print(triangle_index_offset_array)
	

	#print(sanitized_vertices)
	#print(sanitized_vertices.size())
	#
	#print(sanitized_indices)
	#print(sanitized_indices.size())
	#print(sanitized_indices.size() / 3)
	#
	#print(vertex_triangle_affiliation_index_array)
	
	var vertex_normals : PackedVector3Array = []
	var _vertex_positions : PackedVector3Array = []
	var _vertex_sizes : PackedFloat64Array = []
	for vertex_index : int in vertex_triangle_affiliation_index_array.keys():
		var vertex_position : Vector3 = sanitized_vertices[vertex_index]
		
		var normal_sum : Vector3 = Vector3.ZERO
		var position_sum : Vector3 = Vector3.ZERO
		var distance_sum : float = 0.0
		for triangle_index : int in vertex_triangle_affiliation_index_array[vertex_index]:
			var triangle_index_offset : int = triangle_index * 3
			#for semi-decent results, this area sum needs to be biased for triangle aspect ratio (obtuse/isosceles triangles)
			
			#need to adjust this so that vert_a is always the current vertex
			var vert_a : Vector3 = sanitized_vertices[sanitized_indices[triangle_index_offset + 0]]
			var vert_b : Vector3 = sanitized_vertices[sanitized_indices[triangle_index_offset + 1]]
			var vert_c : Vector3 = sanitized_vertices[sanitized_indices[triangle_index_offset + 2]]
			
			var side_ab : Vector3 = vert_b - vert_a
			var side_ac : Vector3 = vert_c - vert_a
			
			var triangle_normal : Vector3 = 0.5 * side_ac.cross(side_ab)
			#normal sum should be biased using triangle area, where smaller triangles contribute less to the normal's direction.
			
			normal_sum += triangle_normal / 3.0 # area is encoded into the length of the triangle normal. It's divided by 3.0 because
			#the area of the triangle must be shared between 3 vertices
			#the vertex position needs to be adjusted so that it is at the barycenter of the average triangles.
			
			var triangle_center : Vector3 = (vert_a + vert_b + vert_c) / 3.0
			position_sum += triangle_center
			
			distance_sum += vertex_position.distance_to(triangle_center)
			#maybe also calculate the average distance/offset of triangles?
		
		
		vertex_normals.append(normal_sum)
		#print(normal_sum)
		position_sum /= vertex_triangle_affiliation_index_array[vertex_index].size()
		_vertex_positions.append(position_sum)
		#to visualize computed positions
		#var mesh := CSGSphere3D.new()
		#mesh.radius = 0.01
		#mesh.position = position_sum
		#add_child(mesh)
		
		#print(position_sum)
		
		distance_sum /= vertex_triangle_affiliation_index_array[vertex_index].size()
		_vertex_sizes.append(distance_sum)
		#print(distance_sum)
		
	
	#print(vertex_normals)
	
	#for normal in vertex_normals:
		#print(normal.length())
	
	
	#test for phantom force/torque
	#sum of all forces/torque at the same pressure should be 0
	var force_sum : Vector3 = Vector3.ZERO
	var torque_sum : Vector3 = Vector3.ZERO
	for vertex_index : int in sanitized_vertices.size():
		var vertex_position : Vector3 = _vertex_positions[vertex_index]
		var vertex_buoyancy_factor : Vector3 = vertex_normals[vertex_index]
		
		force_sum += vertex_buoyancy_factor
		torque_sum += vertex_position.cross(vertex_buoyancy_factor)
	
	#print(force_sum)
	#print(torque_sum)
	
	vertex_positions = _vertex_positions#sanitized_vertices
	vertex_buoyancy_coefficients = vertex_normals
	
	vertex_sizes = _vertex_sizes

#var cached_buoyancy_force : Vector3 = Vector3.ZERO
#var cached_buoyancy_torque : Vector3 = Vector3.ZERO

func _calculate_forces(substep_delta : float = 0.0) -> PackedVector3Array:
	var force_and_torque : PackedVector3Array = super._calculate_forces(substep_delta)
	
	var force_sum : Vector3 = Vector3.ZERO
	var torque_sum : Vector3 = Vector3.ZERO
	var force_position_sum : Vector3 = Vector3.ZERO
	
	
	for vertex_index : int in vertex_positions.size():
		var vertex_position : Vector3 =  relative_position + global_basis * vertex_positions[vertex_index]
		var global_vertex_position : Vector3 = global_position + global_basis * vertex_positions[vertex_index]
		var vertex_buoyancy_factor : Vector3 = global_basis * vertex_buoyancy_coefficients[vertex_index]
		var vertex_radius : float = vertex_sizes[vertex_index]
		
		var vertex_density : float = aero_body.air_density 
		var vertex_velocity = -get_linear_velocity() + -angular_velocity.cross(vertex_position) #this has to be negative because it's air velocity, not linear velocity
		
		var ambient_lift_drag_force : PackedVector3Array = calculate_mesh_lift_drag(vertex_position, vertex_velocity, vertex_buoyancy_factor, vertex_density)
		
		force_sum += ambient_lift_drag_force[0]
		torque_sum += ambient_lift_drag_force[1]
		
		for atmosphere : AeroAtmosphere3D in aero_body.atmosphere_areas:
			if not atmosphere.per_influencer_positioning:
				#use some precomputed center of pressure/buoyancy factor
				continue
			
			var distance_to_surface : float = atmosphere.get_distance_to_surface(global_vertex_position)
			var surface_normal : Vector3 = atmosphere.get_surface_normal(global_vertex_position)
			
			var surface_contact_depth : float = vertex_radius * (1.0 - abs(surface_normal.dot(vertex_buoyancy_factor.normalized())))
			#we subtract the aerobody's density because buoyancy is relative to the difference in pressure between the inside and outside.
			vertex_density = clamp(remap(distance_to_surface, -surface_contact_depth, surface_contact_depth, atmosphere.density - aero_body.air_density, 0.0), 0.0, atmosphere.density - aero_body.air_density)
			var buoyancy_force_and_torque : PackedVector3Array = calculate_mesh_buoyancy(vertex_position, vertex_buoyancy_factor, vertex_density, distance_to_surface)
			var lift_drag_force_and_torque : PackedVector3Array = calculate_mesh_lift_drag(vertex_position, vertex_velocity, vertex_buoyancy_factor, vertex_density)
			
			force_sum += buoyancy_force_and_torque[0] + lift_drag_force_and_torque[0]
			torque_sum += buoyancy_force_and_torque[1] + lift_drag_force_and_torque[1]
	
	
	#force_position_sum /= force_sum.length()
	#if is_equal_approx(force_sum.length(), 0.0):
		#force_position_sum = Vector3.ZERO
	
	#buoyancy_force = force_sum
	#center_of_pressure = force_position_sum
	
	_current_force = force_sum
	_current_torque = torque_sum#(relative_position + force_position_sum).cross(force_sum)
	
	return PackedVector3Array([force_and_torque[0] + _current_force, force_and_torque[1] + _current_torque])

func calculate_mesh_buoyancy(vertex_position : Vector3, vertex_buoyancy_factor : Vector3, vertex_density : float, distance_to_surface : float) -> PackedVector3Array:
	#early return when density == 0.0. Because there will be no buoyant force.
	if vertex_density == 0.0:
		return PackedVector3Array([Vector3.ZERO, Vector3.ZERO])
	
	var force : Vector3 = vertex_density * aero_body.current_gravity.length() * min(distance_to_surface, 0.0) * vertex_buoyancy_factor# * Vector3(0, 1, 0)
	return PackedVector3Array([force, vertex_position.cross(force)])

func calculate_mesh_lift_drag(vertex_position : Vector3, vertex_velocity : Vector3, vertex_buoyancy_factor : Vector3, vertex_density : float) -> PackedVector3Array:
	#early return when density == 0.0. Because there will be no force.
	if vertex_density == 0.0:
		return PackedVector3Array([Vector3.ZERO, Vector3.ZERO])
	
	var vertex_drag_direction : Vector3 = vertex_velocity.normalized()
	var vertex_airspeed : float = vertex_velocity.length()
	var vertex_dynamic_pressure : float = 0.5 * vertex_density * vertex_airspeed * vertex_airspeed
	
	#area * normal * dynamic pressure * normal angle (limited to 0) * force multiplier
	var force : Vector3 = vertex_buoyancy_factor * vertex_dynamic_pressure * (min(vertex_drag_direction.dot(vertex_buoyancy_factor.normalized()), 0.0)) * aero_force_multiplier
	#drag direction * area * dynamic pressure * skin friction coefficient
	force += vertex_drag_direction * vertex_buoyancy_factor.length() * vertex_dynamic_pressure * skin_friction
	return PackedVector3Array([force, vertex_position.cross(force)])
