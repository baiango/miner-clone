@tool
extends MeshInstance3D

enum PerformanceInfo { None, Time, Info, Verbose }
var dbg := PerformanceInfo.Time

const Air := -1
enum { Grass, Dirt, Stone, Void_grass, Crystal_blue }

const TOP_FACE    := [Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3.ONE     , Vector3(0, 1, 1)]
const BOTTOM_FACE := [Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 0, 0), Vector3.ZERO    ]
const LEFT_FACE   := [Vector3(0, 0, 1), Vector3.ZERO    , Vector3(0, 1, 0), Vector3(0, 1, 1)]
const RIGHT_FACE  := [Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3.ONE     , Vector3(1, 1, 0)]
const FRONT_FACE  := [Vector3(1, 0, 1), Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3.ONE     ]
const BACK_FACE   := [Vector3.ZERO    , Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(0, 1, 0)]
const ALL_FACE    := [
		Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3.ONE     , Vector3(0, 1, 1),
		Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 0, 0), Vector3.ZERO    ,
		Vector3(0, 0, 1), Vector3.ZERO    , Vector3(0, 1, 0), Vector3(0, 1, 1),
		Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3.ONE     , Vector3(1, 1, 0),
		Vector3(1, 0, 1), Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3.ONE     ,
		Vector3.ZERO    , Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(0, 1, 0),
]


const FACE_INDEX  := [0, 1, 2, 0, 2, 3]

const FACE_UV     := [Vector2.ZERO, Vector2.DOWN, Vector2.ONE, Vector2.RIGHT]
const TEXTURE_ATLAS_TILE_SIZE = Vector2(8,8)


func cbrt(num: float) -> float: return pow(num, 1.0/3.0)


func prt_perf_stat(func_name: String, regenerating_time: float, bps: int) -> void:
	var bps_cubed = snappedf(cbrt(bps), 0.1)
	var bps_cb_str = "".join(["(", "x".join([bps_cubed, bps_cubed, bps_cubed]), ")"])
	
	print(func_name, " stats:\n\t",
			"Regenerating time: ", regenerating_time, " ms or ", bps, bps_cb_str, " blocks/s")


func _join_array(ARRAYS: Array) -> Array:
	var result := []
	for i in ARRAYS.size(): result.append_array(ARRAYS[i])
	return result


func _add_face_index(MULTIPLIER: int) -> Array:
	var VERTICES_SIZE := 4
	var result := []
	for i in MULTIPLIER:
		for j in FACE_INDEX.size():
			result.append(FACE_INDEX[j] + i * VERTICES_SIZE)
	return result


func _get_face_uv(BLOCK_ID: int) -> PackedVector2Array:
	var row := TEXTURE_ATLAS_TILE_SIZE.x
	var col := TEXTURE_ATLAS_TILE_SIZE.y
	var pointer := Vector2(
			BLOCK_ID % int(row) / row,
			floor(BLOCK_ID / row)
	)

	var result := PackedVector2Array()
	result.append(pointer)
	result.append(pointer + Vector2(1.0 / row, 0.0))
	result.append(pointer + Vector2(1.0 / row, 1.0 / col))
	result.append(pointer + Vector2(0.0, 1.0 / col))
	return result


enum { Left, Right, Top, Bottom, Back, Front, All }
func _generate_face(i: int, x: int, y: int, z: int) -> PackedVector3Array:
	var Faces := [LEFT_FACE, RIGHT_FACE, TOP_FACE, BOTTOM_FACE, BACK_FACE, FRONT_FACE, ALL_FACE]
	return [	Faces[i][0] + Vector3(x, y, z),
				Faces[i][1] + Vector3(x, y, z),
				Faces[i][2] + Vector3(x, y, z),
				Faces[i][3] + Vector3(x, y, z) ]


"""
# from ans.gd
_regenerate() stats:
	Clean up time: 0.224 ms
	Regenerating time: 316.456 ms or 828371(93.9x93.9x93.9) blocks/s

# Cull non-edge blocks only.
_ready() stats:
	Regenerating time: 71.132 ms or 460664(77.2x77.2x77.2) blocks/s

# It speed up by x4.44.
# But it reduced the efficiency by 44%.
"""
func _ready() -> void:
	var start := Time.get_ticks_usec()
	# Step 1, generate block id.
	var dimension := Vector3i(32, 32, 32)

	var noi = FastNoiseLite.new()
	noi.set_frequency(0.03)

	var rng = RandomNumberGenerator.new()
	rng.set_seed(1023)

	var blk_id_arr := []
	blk_id_arr.resize(dimension.x)
	for x in dimension.x:
		blk_id_arr[x] = []
		blk_id_arr[x].resize(dimension.y)
		for y in dimension.y:
			blk_id_arr[x][y] = []
			blk_id_arr[x][y].resize(dimension.z)

	for x in dimension.x:
		for y in dimension.y:
			for z in dimension.z:
				var val = noi.get_noise_3d(x, y, z)
				var rnd_deep := rng.randi()

				# since modulo "%" use "a-(a//b)*b" which is slow. I use bitwise AND "&".
				# bitwise AND "&" only work for numbers that are in power of 2 minus 1. (2**n - 1)
				var blk_id := -1
				if val > -0.3:
					if y >= (rnd_deep & 1) + 5:
						blk_id = Stone
					elif y >= (rnd_deep & 1) + 1:
						blk_id = Dirt
					elif y >= 0:
						blk_id = Grass
				blk_id_arr[x][y][z] = blk_id

	# Step 2, generate meshes.
	var arr_mesh := ArrayMesh.new()
	var face_arr := []
	var face_index := []
	var face_uv := []

	# Non-edge
	var face_count := 0
	for x in range(1, dimension.x - 1):
		for y in range(1, dimension.y - 1):
			for z in range(1, dimension.z - 1):
				var in_place := blk_id_arr[x][y][z] as int
				if in_place == Air:
					continue

				var left_block := blk_id_arr[x-1][y][z] as int
				var right_block := blk_id_arr[x+1][y][z] as int
				var top_block := blk_id_arr[x][y-1][z] as int
				var bottom_block := blk_id_arr[x][y+1][z] as int
				var back_block := blk_id_arr[x][y][z-1] as int
				var front_block := blk_id_arr[x][y][z+1] as int

				if left_block == Air:
					face_arr.append_array(_generate_face(Left, x, ~y, z))
					face_uv.append_array(_get_face_uv(blk_id_arr[x][y][z]))
					face_count += 1
				if right_block == Air:
					face_arr.append_array(_generate_face(Right, x, ~y, z))
					face_uv.append_array(_get_face_uv(blk_id_arr[x][y][z]))
				if top_block == Air:
					face_arr.append_array(_generate_face(Top, x, ~y, z))
					face_uv.append_array(_get_face_uv(blk_id_arr[x][y][z]))
					face_count += 1
				if bottom_block == Air:
					face_arr.append_array(_generate_face(Bottom, x, ~y, z))
					face_uv.append_array(_get_face_uv(blk_id_arr[x][y][z]))
					face_count += 1
				if back_block == Air:
					face_arr.append_array(_generate_face(Back, x, ~y, z))
					face_uv.append_array(_get_face_uv(blk_id_arr[x][y][z]))
					face_count += 1
				if front_block == Air:
					face_arr.append_array(_generate_face(Front, x, ~y, z))
					face_uv.append_array(_get_face_uv(blk_id_arr[x][y][z]))
					face_count += 1

	# Edge only
	$"../../GridMap".clear()
	# x or left direction
	for x in [0, dimension.x - 1]:
		for y in dimension.y:
			for z in dimension.z:
				# Stupid meshlib!
				var id := blk_id_arr[x][y][z] as int
				if id == 0:
					id = Dirt
				elif id == 1:
					id = Grass
				$"../../GridMap".set_cell_item(Vector3i(x, ~y, z), id)

	# y or down direction
	for x in range(1, dimension.x - 1):
		for y in [0, dimension.y - 1]:
			for z in range(1, dimension.z - 1):
				var id := blk_id_arr[x][y][z] as int
				if id == 0:
					id = Dirt
				elif id == 1:
					id = Grass
				$"../../GridMap".set_cell_item(Vector3i(x, ~y, z), id)

	# z or front direction or where kira is facing in.
	for x in range(1, dimension.x - 1):
		for y in range(0, dimension.y - 1):
			for z in [0, dimension.z - 1]:
				var id := blk_id_arr[x][y][z] as int
				if id == 0:
					id = Dirt
				elif id == 1:
					id = Grass
				$"../../GridMap".set_cell_item(Vector3i(x, ~y, z), id)


	face_index = _add_face_index(face_count)

	var mesh_data := []
	mesh_data.resize(ArrayMesh.ARRAY_MAX)
	mesh_data[ArrayMesh.ARRAY_VERTEX] = PackedVector3Array(face_arr)
	mesh_data[ArrayMesh.ARRAY_INDEX]  = PackedInt32Array(face_index)
	mesh_data[ArrayMesh.ARRAY_TEX_UV] = PackedVector2Array(face_uv)
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)
	mesh = arr_mesh

	if dbg >= PerformanceInfo.Time:
		var block_sum := dimension.x * dimension.y * dimension.z
		var regenerating_time := (Time.get_ticks_usec() - start) / 1000.0
		var bps := floori(block_sum / ((Time.get_ticks_usec() - start) / 1_000_000.0))
		prt_perf_stat("_ready()", regenerating_time, bps)


func _on_tree_exiting():
	set_mesh(null)
