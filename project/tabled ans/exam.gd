@tool
extends MeshInstance3D
const ANY_UNSIGNED_INT_MAX = -1
# "-1" means 255 in PackedByteArray. Because it's maximum of 1 byte number, it's 255.
enum BlockType { Air, Dirt, Grass, Stone, Void_grass, Crystal_blue, Error=ANY_UNSIGNED_INT_MAX }

# Dimensions of the chunk
# Should be 32 cubed for able to keep load CPU loaded and not too slow to generate
var dimension := Vector3i(32, 32, 32)
var row := dimension.x
var col := dimension.y
var cel := dimension.z # number of cells
var dimension_sum := row * col * cel # total number of cells

# Number of vertices to show in the mesh to show triangle rendering order
const TRIANGLE_STEP := 3
@export_range(0, 1 << 17, TRIANGLE_STEP) var vertices_to_show := 0
var prev_num := 0
# Built-in function. Updates the mesh based on the number of vertices to show
func _physics_process(_delta: float) -> void:
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
	var face_indices := PackedInt32Array()

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
				if block_ids[cell_index] != BlockType.Air:
					face_vertices.append_array(vectorized_add_v3(tmp_vert, LF_VERTS)) if x-1 < 0 or block_ids[cell_index-1] == 0 else null
					face_vertices.append_array(vectorized_add_v3(tmp_vert, RT_VERTS)) if x+1 >= row or block_ids[cell_index+1] == 0 else null
					face_vertices.append_array(vectorized_add_v3(tmp_vert, DN_VERTS)) if y-1 < 0 or block_ids[cell_index-row] == 0 else null
					face_vertices.append_array(vectorized_add_v3(tmp_vert, UP_VERTS)) if y+1 >= col or block_ids[cell_index+row] == 0 else null
					face_vertices.append_array(vectorized_add_v3(tmp_vert, FWD_VERTS)) if z-1 < 0 or block_ids[cell_index-(row*col)] == 0 else null
					face_vertices.append_array(vectorized_add_v3(tmp_vert, BK_VERTS)) if z+1 >= cel or block_ids[cell_index+(row*col)] == 0 else null

	# Generate face indices
	for iv in range(0, face_vertices.size(), 4):
		face_indices.append_array([0+iv, 1+iv, 2+iv, 2+iv, 1+iv, 3+iv])

	# Resize the face indexes if necessary
	if vertices_to_show >= 0 and vertices_to_show <= face_indices.size(): face_indices.resize(vertices_to_show)

	# Create the mesh using the generated vertices and indices
	var mesh_data := []
	mesh_data.resize(ArrayMesh.ARRAY_MAX)
	mesh_data[ArrayMesh.ARRAY_VERTEX]= face_vertices
	mesh_data[ArrayMesh.ARRAY_INDEX] = face_indices

	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)
	mesh = array_mesh

# Convert 3D coordinates to a 1D index
# There's no easy way to make 3D array without making it confusing to use. So I'll keep using 1D array to store the blocks
func flat_3d_to_1d(x: int, y: int, z: int) -> int: return x + (y * row) + (z * row * col)

# Convert 1D index to a 3D coordinates. Avoid using this, as it cost more than flat_3d_to_1d
# Division and modulo always cost way more performance than multiplication
# If the compiler failed to convert the division to constant or modulo to bitwise AND
@warning_ignore("integer_division")
func expand_1d_to_3d(i: int) -> Vector3i: return Vector3i(i % row, i / row, i / (row * col))

# Perform addition of two PackedVector3Arrays
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
	block_ids.fill(BlockType.Error)

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

				var blk_id := BlockType.Air
				if val > -0.3:
					if pos.y > col - 3:
						blk_id = BlockType.Grass
					elif pos.y > (rnd_deep & 1) + col - 7:
						blk_id = BlockType.Dirt
					elif pos.y >= 0:
						blk_id = BlockType.Stone
				block_ids[flat_3d_to_1d(x, y, z)] = blk_id

	if block_ids.has(BlockType.Error): push_error("Found unused in the block id array ", block_ids.find(BlockType.Error))

	return block_ids
