@tool
extends MeshInstance3D
const ANY_UNSIGNED_INT_MAX = -1
# "-1" means 255 in PackedByteArray. Because it's maximum of 1 byte number, it's 255
enum BlockID { Air, Dirt, Grass, Stone, Void_grass, Crystal_blue, Error=ANY_UNSIGNED_INT_MAX }

# Dimensions of the chunk
# Should be 32 cubed for able to keep load CPU loaded and not too slow to generate. Keep it close to 150ms
# If that doesn't work, use SMT as band-aid solution
# No! Don't do that! It hogs people's computer! Instead, try to reduce cache miss
var dimension := Vector3i(32, 32, 32)
var row := dimension.x
var col := dimension.y
var cel := dimension.z # number of cells
var dimension_sum := row * col * cel # total number of cells

# Number of vertices to show in the mesh to show triangle rendering order
const TRIANGLE_STEP := 3
@export_range(0, 1 << 18, TRIANGLE_STEP) var vertices_to_show := 0
var prev_num := 0
# Built-in function. Updates the mesh based on the number of vertices to show
func _physics_process(_delta: float) -> void:
#	var start := Time.get_ticks_usec()
	# Only update the mesh if the number of vertices to show has changed
	if prev_num == vertices_to_show:
		return
	else:
		prev_num = vertices_to_show

	# If there are fewer than 3 vertices to show, clear the mesh and return
	if vertices_to_show < 3:
		mesh = null
		return

	# Generate block IDs for each cell in the chunk
	var block_ids := _generate_block_id(position)

	# Arrays to store face vertices and indices
	var face_vertices := PackedVector3Array()

	# Define face/quad vertices for each direction. Vector3(Right, Up, Back)
	var LF_VERTS  := PackedVector3Array([Vector3(0,0,1),Vector3(0,0,0),Vector3(0,1,1),Vector3(0,1,0)])
	var RT_VERTS  := PackedVector3Array([LF_VERTS[1],LF_VERTS[0],LF_VERTS[3],LF_VERTS[2]])
	RT_VERTS = vectorized_add_v3([Vector3.RIGHT,Vector3.RIGHT,Vector3.RIGHT,Vector3.RIGHT], RT_VERTS)
	var DN_VERTS  := PackedVector3Array([Vector3(1,0,1),Vector3(1,0,0),Vector3(0,0,1),Vector3(0,0,0)])
	var UP_VERTS  := PackedVector3Array([DN_VERTS[1],DN_VERTS[0],DN_VERTS[3],DN_VERTS[2]])
	UP_VERTS = vectorized_add_v3([Vector3.UP,Vector3.UP,Vector3.UP,Vector3.UP], UP_VERTS)
	var FWD_VERTS := PackedVector3Array([Vector3(0,0,0),Vector3(1,0,0),Vector3(0,1,0),Vector3(1,1,0)])
	var BK_VERTS  := PackedVector3Array([FWD_VERTS[1],FWD_VERTS[0],FWD_VERTS[3],FWD_VERTS[2]])
	BK_VERTS = vectorized_add_v3([Vector3.BACK,Vector3.BACK,Vector3.BACK,Vector3.BACK], BK_VERTS)

	# Iterate over each cell in the chunk
	for x in row:
		for y in col:
			for z in cel:
				var cell_index := flat_3d_to_1d(x, y, z)
				var cell_position := Vector3(x, y, z)
				var tmp_vert := PackedVector3Array([cell_position,cell_position,cell_position,cell_position])

				# Add face vertices based on neighboring blocks
				if block_ids[cell_index] != BlockID.Air:
					if x-1 < 0 or block_ids[cell_index-1] == BlockID.Air:
						face_vertices.append_array(vectorized_add_v3(tmp_vert, LF_VERTS))
					if x+1 >= row or block_ids[cell_index+1] == BlockID.Air:
						face_vertices.append_array(vectorized_add_v3(tmp_vert, RT_VERTS))
					if y-1 < 0 or block_ids[cell_index-row] == BlockID.Air:
						face_vertices.append_array(vectorized_add_v3(tmp_vert, DN_VERTS))
					if y+1 >= col or block_ids[cell_index+row] == BlockID.Air:
						face_vertices.append_array(vectorized_add_v3(tmp_vert, UP_VERTS))
					if z-1 < 0 or block_ids[cell_index-(row*col)] == BlockID.Air:
						face_vertices.append_array(vectorized_add_v3(tmp_vert, FWD_VERTS))
					if z+1 >= cel or block_ids[cell_index+(row*col)] == BlockID.Air:
						face_vertices.append_array(vectorized_add_v3(tmp_vert, BK_VERTS))

	# Generate face indices
	var face_indices := PackedInt32Array()
	@warning_ignore("narrowing_conversion")
	face_indices.resize(face_vertices.size() * 1.5)
	for iv in range(0, face_vertices.size(), 4):
		var index_offset := iv * 1.5
		face_indices[index_offset + 0] = 0 + iv
		face_indices[index_offset + 1] = 1 + iv
		face_indices[index_offset + 2] = 2 + iv
		face_indices[index_offset + 3] = 2 + iv
		face_indices[index_offset + 4] = 1 + iv
		face_indices[index_offset + 5] = 3 + iv

	# Generate face uv
	var face_uv := PackedVector2Array()
	var texture_atlas_size := Vector2i(5, 3)
	var trow: float = texture_atlas_size.x
	var init_uv := PackedVector2Array([
			Vector2.ZERO, Vector2.DOWN / texture_atlas_size.y,
			Vector2.RIGHT / texture_atlas_size.x, Vector2.ONE / Vector2(texture_atlas_size)
	])

	for x in row:
		for y in col:
			for z in cel:
				var cell_index := flat_3d_to_1d(x, y, z)
				var shift_uv := Vector2(
					int(block_ids[cell_index] - 1) % int(trow) / float(trow),
					int((block_ids[cell_index] - 1) / float(trow)) / float(trow)
				)
				var pos_uv := PackedVector2Array([
					init_uv[0] + shift_uv, init_uv[1] + shift_uv,
					init_uv[2] + shift_uv, init_uv[3] + shift_uv
				])
				if block_ids[cell_index] != BlockID.Air:
					if x-1 < 0 or block_ids[cell_index-1] == BlockID.Air: face_uv.append_array(pos_uv)
					if x+1 >= row or block_ids[cell_index+1] == BlockID.Air: face_uv.append_array(pos_uv)
					if y-1 < 0 or block_ids[cell_index-row] == BlockID.Air: face_uv.append_array(pos_uv)
					if y+1 >= col or block_ids[cell_index+row] == BlockID.Air: face_uv.append_array(pos_uv)
					if z-1 < 0 or block_ids[cell_index-(row*col)] == BlockID.Air: face_uv.append_array(pos_uv)
					if z+1 >= cel or block_ids[cell_index+(row*col)] == BlockID.Air: face_uv.append_array(pos_uv)

	# Resize the face indexes if necessary
	if vertices_to_show >= 0 and vertices_to_show <= face_indices.size(): face_indices.resize(vertices_to_show)

	# Create the mesh using the generated vertices and indices
	var mesh_data := []
	mesh_data.resize(ArrayMesh.ARRAY_MAX)
	mesh_data[ArrayMesh.ARRAY_VERTEX]= face_vertices
	mesh_data[ArrayMesh.ARRAY_INDEX] = face_indices
	mesh_data[ArrayMesh.ARRAY_TEX_UV] = face_uv

	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)
	mesh = array_mesh

	mesh.surface_set_material(0, preload("res://image/mat_chunk.tres"))

#	print_debug((Time.get_ticks_usec() - start) / 1000.0)

# Convert 3D coordinates to a 1D index
# There's no easy way to make 3D array without making it confusing to use
# So I'll keep using 1D array to store the blocks
func flat_3d_to_1d(x: int, y: int, z: int) -> int: return x + (y * row) + (z * row * col)

# Convert 1D index to a 3D coordinates. Avoid using this, as it cost more than flat_3d_to_1d
# Division and modulo always cost way more performance than multiplication
# If the compiler failed to convert the division to constant or modulo to bitwise AND
@warning_ignore("integer_division")
func expand_1d_to_3d(i: int) -> Vector3i: return Vector3i(i % row, i / row, i / (row * col))

func vectorized_add_v3(a: PackedVector3Array, b: PackedVector3Array) -> PackedVector3Array:
	if a.size() != b.size():
		push_error("both PackedVector3Array in vectorized_add_v3() are not the same size,",
				"will be trimmed to size of first argument")
	var ret := PackedVector3Array()
	ret.resize(a.size())
	for i in a.size(): ret[i] = a[i] + b[i]
	return ret

# Generate block IDs based on noise and position
func _generate_block_id(pos: Vector3 = position) -> PackedByteArray:
	var block_ids := PackedByteArray()
	block_ids.resize(dimension_sum)
	block_ids.fill(BlockID.Error)

	var noi := FastNoiseLite.new()
	noi.set_offset(pos)
	noi.set_frequency(0.03)

	var rng := RandomNumberGenerator.new()
	rng.set_seed(1023)

	for x in row:
		for y in col:
			for z in cel:
				var val := noi.get_noise_3d(x, y, z)
				var rnd_deep := rng.randi()
#				var density := -0.5 + (pos.y + y / 200.0)

				var blk_id := BlockID.Air
				if val > -0.3:
					if pos.y + y < (rnd_deep & 1) + 58:
						blk_id = BlockID.Stone
					elif pos.y + y < 62:
						blk_id = BlockID.Grass
					elif pos.y + y < 64:
						blk_id = BlockID.Dirt
				block_ids[flat_3d_to_1d(x, y, z)] = blk_id

	if block_ids.has(BlockID.Error):
		push_error("Found unused in the block id array ", block_ids.find(BlockID.Error))

	return block_ids
