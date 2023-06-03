#@tool
extends MeshInstance3D


var dimension := Vector3i(64, 64, 64)
var row := dimension.x
var col := dimension.y
var cll := dimension.z # cells
var dimension_sum := row * col * cll
func _ready():
	# https://www.paridebroggi.com/blogpost/2015/06/16/optimized-cube-opengl-triangle-strip/
	var face_vert := PackedVector3Array([
		Vector3(1, 1, 1), # 0 One
		Vector3(0, 1, 1), # 1 Up, Back
		Vector3(1, 1, 0), # 2 Up, Right
		Vector3(0, 1, 0), # 3 Up
		Vector3(1, 0, 1), # 4 Back, Right
		Vector3(0, 0, 1), # 5 Back
		Vector3(0, 0, 0), # 6 Zero
		Vector3(1, 0, 0)  # 7 Right 
	])
	var face_index := PackedInt32Array([
		# It's flipped from the tutorial, I need to flip it back
		# It use previous 2 indexes, so it's pretty hard to follow
#		3, 2, 6, 7, 4, 2, 0,
#		3, 1, 6, 5, 4, 1, 0
#		2, 3, 7, 6, 5, 3, 1,
#		0, 5, 4, 7, 0, 2, 3
		0, 1, 2, 3, 6, 7
	])
#	var face_uv := PackedVector2Array()

	var mesh_data := []
	mesh_data.resize(ArrayMesh.ARRAY_MAX)
	mesh_data[ArrayMesh.ARRAY_VERTEX] = face_vert
	mesh_data[ArrayMesh.ARRAY_INDEX] = face_index
#	mesh_data[ArrayMesh.ARRAY_TEX_UV] = face_uv

	var arr_mesh := ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, mesh_data)

	mesh = arr_mesh

func flat_3d_to_1d(x: int, y: int, z: int) -> int:
	return x + (y * row) + (z * row * col);

func expand_1d_to_3d(i: int) -> Vector3i:
	return Vector3i(i % row, i / row, i / (row * col))

func _on_tree_exiting():
	mesh = null
