@tool
extends MeshInstance3D

const Air := -1
enum { Grass, Dirt, Stone, Void_grass, Crystal_blue }

const TOP_FACE    := [Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3.ONE     , Vector3(0, 1, 1), ]
const BOTTOM_FACE := [Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 0, 0), Vector3.ZERO    , ]
const LEFT_FACE   := [Vector3(0, 0, 1), Vector3.ZERO    , Vector3(0, 1, 0), Vector3(0, 1, 1), ]
const RIGHT_FACE  := [Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3.ONE     , Vector3(1, 1, 0), ]
const FRONT_FACE  := [Vector3(1, 0, 1), Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3.ONE     , ]
const BACK_FACE   := [Vector3.ZERO    , Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(0, 1, 0), ]
const FACE_INDEX  := [0, 1, 2, 0, 2, 3]

const FACE_UV     := [Vector2.ZERO, Vector2.DOWN, Vector2.ONE, Vector2.RIGHT]
const TEXTURE_ATLAS_TILE_SIZE = Vector2(8,8)


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


func _get_face_uv(BLOCK_ID: int) -> PackedVector2Array: # core function
	var row := TEXTURE_ATLAS_TILE_SIZE.x
	var col := TEXTURE_ATLAS_TILE_SIZE.y
	var pointer := Vector2(BLOCK_ID % int(row) / row,
			floor(BLOCK_ID / row))

	var result := PackedVector2Array()
	result.append(pointer)
	result.append(pointer + Vector2(1.0 / row, 0.0))
	result.append(pointer + Vector2(1.0 / row, 1.0 / col))
	result.append(pointer + Vector2(0.0, 1.0 / col))
	return result


func _ready() -> void:
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

	var arr_mesh := ArrayMesh.new()
	var mesh_data := []
#	var face_arr := _join_array([TOP_FACE, _shift_block_face(TOP_FACE, Vector3.RIGHT)])
#	var face_index := _add_face_index(2)
#	var face_uv := _join_array([_get_face_uv(blk_id_arr[0][0][0]), _get_face_uv(blk_id_arr[0][0][0])])

	var face_arr := []
	var face_index := []
	var face_uv := []

#	blk_id_arr = [
#	[	[Grass,Grass,Grass,Grass],
#		[Dirt,Dirt,Dirt,Dirt],
#		[Air,Air,Air,Air],
#		[Stone,Stone,Stone,Stone], ],
#
#	[	[Grass,Grass,Grass,Grass],
#		[Dirt,Dirt,Dirt,Dirt],
#		[Air,Air,Air,Air],
#		[Stone,Stone,Stone,Stone], ],
#
#	[	[Grass,Grass,Grass,Grass],
#		[Dirt,Dirt,Dirt,Dirt],
#		[Air,Air,Air,Air],
#		[Stone,Stone,Stone,Stone], ],
#
#	[	[Grass,Grass,Grass,Grass],
#		[Dirt,Dirt,Dirt,Dirt],
#		[Air,Air,Air,Air],
#		[Stone,Stone,Stone,Stone], ],
#	]

	var dimension_sum := dimension.x * dimension.y * dimension.z
	face_index = _add_face_index(dimension_sum * 6)
	for x in range(1, dimension.x - 1):
		for y in range(1, dimension.y - 1):
			for z in range(1, dimension.z - 1):
#	for x in dimension.x:
#		for y in dimension.y:
#			for z in dimension.z:
				if blk_id_arr[x][y][z] == Air: continue
				if blk_id_arr[x][y-1][z] == Air:
					face_uv.append_array(_get_face_uv(blk_id_arr[x][y][z]))
					face_arr.append_array([
							TOP_FACE[0] + Vector3(x, ~y, z),
							TOP_FACE[1] + Vector3(x, ~y, z),
							TOP_FACE[2] + Vector3(x, ~y, z),
							TOP_FACE[3] + Vector3(x, ~y, z)
					])

				if blk_id_arr[x][y+1][z] == Air:
					face_uv.append_array(_get_face_uv(blk_id_arr[x][y][z]))
					face_arr.append_array([
							BOTTOM_FACE[0] + Vector3(x, ~y, z),
							BOTTOM_FACE[1] + Vector3(x, ~y, z),
							BOTTOM_FACE[2] + Vector3(x, ~y, z),
							BOTTOM_FACE[3] + Vector3(x, ~y, z)
					])

				if blk_id_arr[x-1][y][z] == Air:
					face_uv.append_array(_get_face_uv(blk_id_arr[x][y][z]))
					face_arr.append_array([
							LEFT_FACE[0] + Vector3(x, ~y, z),
							LEFT_FACE[1] + Vector3(x, ~y, z),
							LEFT_FACE[2] + Vector3(x, ~y, z),
							LEFT_FACE[3] + Vector3(x, ~y, z)
					])

				if blk_id_arr[x+1][y][z] == Air:
					face_uv.append_array(_get_face_uv(blk_id_arr[x][y][z]))
					face_arr.append_array([
							RIGHT_FACE[0] + Vector3(x, ~y, z),
							RIGHT_FACE[1] + Vector3(x, ~y, z),
							RIGHT_FACE[2] + Vector3(x, ~y, z),
							RIGHT_FACE[3] + Vector3(x, ~y, z)
					])

				if blk_id_arr[x][y][z-1] == Air:
					face_uv.append_array(_get_face_uv(blk_id_arr[x][y][z]))
					face_arr.append_array([
							BACK_FACE[0] + Vector3(x, ~y, z),
							BACK_FACE[1] + Vector3(x, ~y, z),
							BACK_FACE[2] + Vector3(x, ~y, z),
							BACK_FACE[3] + Vector3(x, ~y, z)
					])

				if blk_id_arr[x][y][z+1] == Air:
					face_uv.append_array(_get_face_uv(blk_id_arr[x][y][z]))
					face_arr.append_array([
							FRONT_FACE[0] + Vector3(x, ~y, z),
							FRONT_FACE[1] + Vector3(x, ~y, z),
							FRONT_FACE[2] + Vector3(x, ~y, z),
							FRONT_FACE[3] + Vector3(x, ~y, z)
					])

	mesh_data.resize(ArrayMesh.ARRAY_MAX)
	mesh_data[ArrayMesh.ARRAY_VERTEX] = PackedVector3Array(face_arr)
	mesh_data[ArrayMesh.ARRAY_INDEX]  = PackedInt32Array(face_index)
	mesh_data[ArrayMesh.ARRAY_TEX_UV] = PackedVector2Array(face_uv)
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)
	mesh = arr_mesh


func _on_tree_exiting():
	set_mesh(null)
