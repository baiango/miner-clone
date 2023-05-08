@tool
extends MeshInstance3D

const Vec3_ZERO = Vector3.ZERO
const Vec3_ONE = Vector3.ONE
const Vec3_RIGHT = Vector3.RIGHT
const Vec3_RIGHT_BACK = Vector3.RIGHT + Vector3.BACK
const Vec3_UP = Vector3.UP
const Vec3_UP_RIGHT = Vector3.UP + Vector3.RIGHT
const Vec3_UP_BACK = Vector3.UP + Vector3.BACK
const Vec3_BACK = Vector3.BACK

enum PerformanceInfo { None, Time, Info, Verbose }
var dbg := PerformanceInfo.Time

const Air := -1
enum { Grass, Dirt, Stone, Void_grass, Crystal_blue }

const TOP_FACE    := [Vec3_UP        , Vec3_UP_RIGHT  , Vec3_ONE     , Vec3_UP_BACK ]
const BOTTOM_FACE := [Vec3_BACK      , Vec3_RIGHT_BACK, Vec3_RIGHT   , Vec3_ZERO    ]
const LEFT_FACE   := [Vec3_BACK      , Vec3_ZERO      , Vec3_UP      , Vec3_UP_BACK ]
const RIGHT_FACE  := [Vec3_RIGHT     , Vec3_RIGHT_BACK, Vec3_ONE     , Vec3_UP_RIGHT]
const FRONT_FACE  := [Vec3_RIGHT_BACK, Vec3_BACK      , Vec3_UP_BACK , Vec3_ONE     ]
const BACK_FACE   := [Vec3_ZERO      , Vec3_RIGHT     , Vec3_UP_RIGHT, Vec3_UP      ]


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


enum { Left, Right, Top, Bottom, Back, Front }
func _generate_face(i: int, x: int, y: int, z: int) -> PackedVector3Array:
	var Faces := [LEFT_FACE, RIGHT_FACE, TOP_FACE, BOTTOM_FACE, BACK_FACE, FRONT_FACE]
	return [	Faces[i][0] + Vector3(x, y, z),
				Faces[i][1] + Vector3(x, y, z),
				Faces[i][2] + Vector3(x, y, z),
				Faces[i][3] + Vector3(x, y, z) ]


"""
Test size: 64 cubed
# from ans.gd
_regenerate() stats:
	Clean up time: 1.738 ms
	Regenerating time: 317.534 ms or 825559(93.8x93.8x93.8) blocks/s

# Full Culling single sided
_ready() stats:
	Regenerating time: 826.482 ms or 317180(68.2x68.2x68.2) blocks/s

# It slowed down by x2.6.
"""
func _ready() -> void:
#	return
	var start := Time.get_ticks_usec()
	# Step 1, generate block id.
	var dimension := Vector3i(32, 32, 32)

	var noi = FastNoiseLite.new()
	noi.set_frequency(0.03)

	var rng = RandomNumberGenerator.new()
	rng.set_seed(1023)

	var padding = 1
	var padded_dimension = dimension + Vector3i.ONE * padding * 2
	var blk_id_arr := []
	blk_id_arr.resize(padded_dimension.x)
	for x in padded_dimension.x:
		blk_id_arr[x] = []
		blk_id_arr[x].resize(padded_dimension.y)
		for y in padded_dimension.y:
			blk_id_arr[x][y] = []
			blk_id_arr[x][y].resize(padded_dimension.z)

	for x in padded_dimension.x:
		for y in padded_dimension.y:
			for z in padded_dimension.z:
				blk_id_arr[x][y][z] = Air

	for x in range(padding, dimension.x + 1):
		for y in range(padding, dimension.y + 1):
			for z in range(padding, dimension.z + 1):
				var val = noi.get_noise_3d(x - padding, y - padding, z - padding)
				var rnd_deep := rng.randi()

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
	var face_arr := PackedVector3Array()
	var face_index := PackedInt32Array()
	var face_uv := PackedVector2Array()

	var face_count := 0
	for ix in range(padding, dimension.x + 1):
		for iy in range(padding, dimension.y + 1):
			for iz in range(padding, dimension.z + 1):
				var in_place := blk_id_arr[ix][iy][iz] as int
				if in_place == Air:
					continue

				var dbg_do_all_face := false
#				dbg_do_all_face = not dbg_do_all_face

				var left_block := blk_id_arr[ix-1][iy][iz] as int
				var right_block := blk_id_arr[ix+1][iy][iz] as int
				var top_block := blk_id_arr[ix][iy-1][iz] as int
				var bottom_block := blk_id_arr[ix][iy+1][iz] as int
				var back_block := blk_id_arr[ix][iy][iz-1] as int
				var front_block := blk_id_arr[ix][iy][iz+1] as int

				var x := ix - padding as int
				var y := iy - padding as int
				var z := iz - padding as int

				if left_block == Air or dbg_do_all_face:
					face_arr.append_array(_generate_face(Left, x, ~y, z))
					face_uv.append_array(_get_face_uv(blk_id_arr[ix][iy][iz]))
					face_count += 1
				if right_block == Air or dbg_do_all_face:
					face_arr.append_array(_generate_face(Right, x, ~y, z))
					face_uv.append_array(_get_face_uv(blk_id_arr[ix][iy][iz]))
					face_count += 1
				if top_block == Air or dbg_do_all_face:
					face_arr.append_array(_generate_face(Top, x, ~y, z))
					face_uv.append_array(_get_face_uv(blk_id_arr[ix][iy][iz]))
					face_count += 1
				if bottom_block == Air or dbg_do_all_face:
					face_arr.append_array(_generate_face(Bottom, x, ~y, z))
					face_uv.append_array(_get_face_uv(blk_id_arr[ix][iy][iz]))
					face_count += 1
				if back_block == Air or dbg_do_all_face:
					face_arr.append_array(_generate_face(Back, x, ~y, z))
					face_uv.append_array(_get_face_uv(blk_id_arr[ix][iy][iz]))
					face_count += 1
				if front_block == Air or dbg_do_all_face:
					face_arr.append_array(_generate_face(Front, x, ~y, z))
					face_uv.append_array(_get_face_uv(blk_id_arr[ix][iy][iz]))
					face_count += 1

	face_index = _add_face_index(face_count)

	var mesh_data := []
	mesh_data.resize(ArrayMesh.ARRAY_MAX)
	mesh_data[ArrayMesh.ARRAY_VERTEX] = face_arr
	mesh_data[ArrayMesh.ARRAY_INDEX] = face_index
	mesh_data[ArrayMesh.ARRAY_TEX_UV] = face_uv

	var arr_mesh := ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)
	mesh = arr_mesh

	if dbg >= PerformanceInfo.Time:
		var block_sum := dimension.x * dimension.y * dimension.z
		var regenerating_time := (Time.get_ticks_usec() - start) / 1000.0
		var bps := floori(block_sum / ((Time.get_ticks_usec() - start) / 1_000_000.0))
		prt_perf_stat("_ready()", regenerating_time, bps)


func _on_tree_exiting():
	set_mesh(null)
