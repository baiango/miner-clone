#@tool
extends MeshInstance3D


const TOP_FACE    := [Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3.ONE     , Vector3(0, 1, 1), ]
const BOTTOM_FACE := [Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 0, 0), Vector3.ZERO    , ]
const LEFT_FACE   := [Vector3(0, 0, 1), Vector3.ZERO    , Vector3(0, 1, 0), Vector3(0, 1, 1), ]
const RIGHT_FACE  := [Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3.ONE     , Vector3(1, 1, 0), ]
const FRONT_FACE  := [Vector3(1, 0, 1), Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3.ONE     , ]
const BACK_FACE   := [Vector3.ZERO    , Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(0, 1, 0), ]
const FACE_INDEX  := [0, 1, 2, 0, 2, 3]

#const FACE_UV     := [Vector2.ONE, Vector2.DOWN, Vector2.ZERO, Vector2.RIGHT]
const FACE_UV     := [Vector2(0.125, 0.125), Vector2(0, 0.125), Vector2(0, 0), Vector2(0.125, 0)]
#const FACE_UV    := [Vector2(0.123, 0.123), Vector2(0.002, 0.123), Vector2(0.002, 0.002), Vector2(0.123, 0.002)]

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


func _add_face_uv(MULTIPLIER: int) -> Array:
	var result := []
	for __ in MULTIPLIER: result.append_array(FACE_UV)
	return result


func _shift_block_face(faces: PackedVector3Array, VECTOR_OFFSET: Vector3) -> PackedVector3Array: # core function
	for i in faces.size(): faces[i] += VECTOR_OFFSET
	return faces


func _process(DELTA: float) -> void:
#	return
	if Engine.get_process_frames() & 63: return
	
	var arr_mesh := ArrayMesh.new()
	var mesh_data := []
	var face_arr := _join_array([
			TOP_FACE,
			_shift_block_face(RIGHT_FACE, Vector3.LEFT),
	])
	var face_index := _add_face_index(2)
	var face_uv := _add_face_uv(2)

	# Buggy as hell!
	# [(-1, 1, 0), (0, 1, 0), (0, 1, 1), (-1, 1, 1)]
	# [(-2, 1, 0), (-1, 1, 0), (-1, 1, 1), (-2, 1, 1)]
	# [(-3, 1, 0), (-2, 1, 0), (-2, 1, 1), (-3, 1, 1)]
	# [(-4, 1, 0), (-3, 1, 0), (-3, 1, 1), (-4, 1, 1)]
	# [(-5, 1, 0), (-4, 1, 0), (-4, 1, 1), (-5, 1, 1)]
	# [(-6, 1, 0), (-5, 1, 0), (-5, 1, 1), (-6, 1, 1)]
	# [(-7, 1, 0), (-6, 1, 0), (-6, 1, 1), (-7, 1, 1)]
	var x = _shift_block_face(
#		[Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3.ONE     , Vector3(0, 1, 1), ],
		TOP_FACE,
#		aaa,
		Vector3.LEFT
	)
	
	print(x)

	mesh_data.resize(ArrayMesh.ARRAY_MAX)
	mesh_data[ArrayMesh.ARRAY_VERTEX] = PackedVector3Array(face_arr)
	mesh_data[ArrayMesh.ARRAY_INDEX]  = PackedInt32Array(face_index)
	mesh_data[ArrayMesh.ARRAY_TEX_UV] = PackedVector2Array(face_uv)
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)
	mesh = arr_mesh
