@tool
extends MultiMeshInstance3D

var dimension := Vector3i(64, 64, 64)
var row := dimension.x
var col := dimension.y
var cll := dimension.z # cells
var dimension_sum := row * col * cll
func _ready():
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = dimension_sum

	multimesh.set_mesh(BoxMesh.new())

	# Set the transform of the instances.
	var start := Time.get_ticks_usec()
	for x in row:
		for y in col:
			for z in cll:
				multimesh.set_instance_transform(x + (y * row) + (z * row * col), Transform3D(Basis(), Vector3(x, y, z)))
	var set_mesh_time := (Time.get_ticks_usec() - start) / 1000.0
	print_debug(set_mesh_time)


func flat_3d_to_1d(x: int, y: int, z: int) -> int:
	return x + (y * row) + (z * row * col);

func expand_1d_to_3d(i: int) -> Vector3i:
	return Vector3i(i % row, i / row, i / (row * col))
