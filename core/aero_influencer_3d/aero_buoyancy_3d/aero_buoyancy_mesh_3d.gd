@tool
extends AeroBuoyancy3D
class_name AeroBuoyancyMesh3D

@export_tool_button("Recalculate mesh data") var action = calculate_vertex_areas
@export var buoyancy_mesh : Mesh:
	set(x):
		buoyancy_mesh = x
		calculate_vertex_areas()
		if buoyancy_mesh_debug:
			buoyancy_mesh_debug.mesh = buoyancy_mesh
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
	debug_material.albedo_color.a = 0.2
	buoyancy_mesh_debug.material_override = debug_material
	buoyancy_mesh_debug.visible = false

func _ready() -> void:
	super._ready()
	
	add_child(buoyancy_mesh_debug, INTERNAL_MODE_FRONT)

func update_debug_visibility(_show_debug : bool = false) -> void:
	super.update_debug_visibility(_show_debug)
	
	buoyancy_mesh_debug.visible = show_debug and show_buoyancy_mesh_debug

func calculate_vertex_areas() -> void:
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
	
	var vertex_areas : PackedFloat64Array = []
	var vertex_normals : PackedVector3Array = []
	var _vertex_positions : PackedVector3Array = []
	var _vertex_sizes : PackedFloat64Array = []
	for vertex_index : int in vertex_triangle_affiliation_index_array.keys():
		var vertex_position : Vector3 = sanitized_vertices[vertex_index]
		
		var area_sum : float = 0.0
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
			
			var triangle_area : float = 0.5 * abs(side_ab.dot(side_ac)) / 3.0
			area_sum += triangle_area
			#normal sum should be biased using triangle area, where smaller triangles contribute less to the normal's direction.
			var triangle_normal : Vector3 = side_ac.cross(side_ab).normalized()
			#if the cross product isn't normalized, would the length of the result be something like twice the triangle's area?
			normal_sum += triangle_normal * triangle_area # area can be encoded into normal length.
			#the vertex position needs to be adjusted so that it is at the barycenter of the average triangles.
			
			var triangle_center : Vector3 = (vert_a + vert_b + vert_c) / 3.0
			position_sum += triangle_center
			
			distance_sum += vertex_position.distance_to(triangle_center)
			#maybe also calculate the average distance/offset of triangles?
		
		
		vertex_areas.append(area_sum)
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
		
	
	
	#print(vertex_areas)
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
	
	print(force_sum)
	print(torque_sum)
	
	
	vertex_positions = _vertex_positions#sanitized_vertices
	vertex_buoyancy_coefficients = vertex_normals
	
	vertex_sizes = _vertex_sizes


func calculate_buoyancy() -> void:
	var force_sum : Vector3 = Vector3.ZERO
	var torque_sum : Vector3 = Vector3.ZERO
	var force_position_sum : Vector3 = Vector3.ZERO
	for vertex_index : int in vertex_positions.size():
		var vertex_position : Vector3 = global_basis * vertex_positions[vertex_index]
		var global_vertex_position : Vector3 = aero_body.global_position + relative_position + vertex_position
		var vertex_buoyancy_factor : Vector3 = global_basis * vertex_buoyancy_coefficients[vertex_index]
		var vertex_radius : float = vertex_sizes[vertex_index]
		
		var vertex_density : float = aero_body.air_density 
		
		var vertex_velocity = world_air_velocity + -angular_velocity.cross(vertex_position) #this has to be negative because it's air velocity, not linear velocity
		var vertex_airspeed : float = vertex_velocity.length()
		var vertex_drag_direction : Vector3 = vertex_velocity.normalized()
		
		for atmosphere : AeroAtmosphere3D in aero_body.atmosphere_areas:
			if not atmosphere.per_influencer_positioning:
				# use precomputed center of pressure? yes, use precomputed center of pressure.
				continue
			
			var distance_to_surface : float = atmosphere.get_distance_to_surface(global_vertex_position)
			#this remap should be limited by the dot product of the vertex normal and the surface normal
			vertex_density = clamp(remap(distance_to_surface, -vertex_radius, vertex_radius, atmosphere.density, aero_body.air_density), aero_body.air_density, atmosphere.density)
			
			var vertex_dynamic_pressure : float = 0.5 * vertex_density * vertex_airspeed * vertex_airspeed
			
			#this V3(0, 1, 0) term needs to be removed eventually, for proper buoyancy effects.
			var force : Vector3 = vertex_density * aero_body.current_gravity.length() * min(distance_to_surface, 0.0) * vertex_buoyancy_factor# * Vector3(0, 1, 0)
			#something in this drag calc causes a weird nose-up thing
			
			var lift_and_drag = vertex_buoyancy_factor.normalized() * vertex_dynamic_pressure * (vertex_drag_direction.dot(vertex_buoyancy_factor))
			
			force = force + lift_and_drag
			
			force_sum += force
			#torque_sum += vertex_position.cross(force)
			force_position_sum += vertex_position * force.length()
	
	force_position_sum /= force_sum.length()
	if is_equal_approx(force_sum.length(), 0.0):
		force_position_sum = Vector3.ZERO
	
	buoyancy_force = force_sum
	center_of_pressure = force_position_sum
