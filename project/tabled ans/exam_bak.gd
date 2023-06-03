@tool
extends MeshInstance3D

enum { Air, Dirt, Grass, Stone, Void_grass, Crystal_blue, Error=-1}
enum Neighbour { Left=1, Right=1<<1, Down=1<<2, Up=1<<3, Forward=1<<4, Back=1<<5 }

var dimension := Vector3i(16, 16, 16)
var row := dimension.x
var col := dimension.y
var cll := dimension.z # cells
var dimension_sum := row * col * cll


@export_range(0, 1 << 20, 3) var num_to_show := 0
var prev_num := 0
func _physics_process(delta: float) -> void:
	if prev_num == num_to_show: return
	else: prev_num = num_to_show

	if num_to_show < 3:
		mesh = null
		return

	var blk_id_arr := _generate_block_id(position)
	var neighbours_arr := _generate_neighbours_arr(blk_id_arr)

	var face_vert := PackedVector3Array()
	var face_index := PackedInt32Array()

	var LEFT_FACE    := PackedVector3Array([Vector3(0,0,1),Vector3(0,0,0),Vector3(0,1,1),Vector3(0,1,0)])
	var RIGHT_FACE   := PackedVector3Array([LEFT_FACE[1],LEFT_FACE[0],LEFT_FACE[3],LEFT_FACE[2]])
	RIGHT_FACE = vectorized_add_v3([Vector3.RIGHT,Vector3.RIGHT,Vector3.RIGHT,Vector3.RIGHT], RIGHT_FACE)
	var DOWN_FACE    := PackedVector3Array([Vector3(1,0,1),Vector3(1,0,0),Vector3(0,0,1),Vector3(0,0,0)])
	var UP_FACE      := PackedVector3Array([DOWN_FACE[1],DOWN_FACE[0],DOWN_FACE[3],DOWN_FACE[2]])
	UP_FACE    = vectorized_add_v3([Vector3.UP,Vector3.UP,Vector3.UP,Vector3.UP], UP_FACE)
	var FORWARD_FACE := PackedVector3Array([Vector3(0,0,0),Vector3(1,0,0),Vector3(0,1,0),Vector3(1,1,0)])
	var BACK_FACE    := PackedVector3Array([FORWARD_FACE[1],FORWARD_FACE[0],FORWARD_FACE[3],FORWARD_FACE[2]])
	BACK_FACE  = vectorized_add_v3([Vector3.BACK,Vector3.BACK,Vector3.BACK,Vector3.BACK], BACK_FACE)

#	for x in row:
#		for y in col:
#			for z in cll:
#				var i := flat_3d_to_1d(x, y, z)
#				var switches := neighbours_arr[i]
##				switches = 0
#				if not x and not y and not z:
#					print(neighbours_arr[row] & 1)
#					print(neighbours_arr[row] & 2)
#					print(neighbours_arr[row] & 4)
#					print(neighbours_arr[row] & 8)
#					print(neighbours_arr[row] & 16)
#					print(neighbours_arr[row] & 32)
#					print(neighbours_arr[row] & 64)
#				var tmp_vert := PackedVector3Array([Vector3(x,y,z),Vector3(x,y,z),Vector3(x,y,z),Vector3(x,y,z)])
##				if switches >= 0b111111: continue
#				if not switches & Neighbour.Left:    face_vert.append_array(vectorized_add_v3(tmp_vert, LEFT_FACE))
#				if not switches & Neighbour.Right:   face_vert.append_array(vectorized_add_v3(tmp_vert, RIGHT_FACE))
#				if not switches & Neighbour.Down:    face_vert.append_array(vectorized_add_v3(tmp_vert, DOWN_FACE))
#				if not switches & Neighbour.Up:      face_vert.append_array(vectorized_add_v3(tmp_vert, UP_FACE))
#				if not switches & Neighbour.Forward: face_vert.append_array(vectorized_add_v3(tmp_vert, FORWARD_FACE))
#				if not switches & Neighbour.Back:    face_vert.append_array(vectorized_add_v3(tmp_vert, BACK_FACE))

	for x in row:
		for y in col:
			for z in cll:
				var i := flat_3d_to_1d(x, y, z)
				var tmp_vert := PackedVector3Array([Vector3(x,y,z),Vector3(x,y,z),Vector3(x,y,z),Vector3(x,y,z)])
#				if x-1 > 0 and not blk_id_arr[flat_3d_to_1d(x-1, y, z)]:
#					face_vert.append_array(vectorized_add_v3(tmp_vert, LEFT_FACE))
#				if x+1 < row and not blk_id_arr[flat_3d_to_1d(x+1, y, z)]:
#					face_vert.append_array(vectorized_add_v3(tmp_vert, RIGHT_FACE))
#				if y-1 > 0 and not blk_id_arr[flat_3d_to_1d(x, y-1, z)]:
#					face_vert.append_array(vectorized_add_v3(tmp_vert, DOWN_FACE))
#				if y+1 < col and not blk_id_arr[flat_3d_to_1d(x, y+1, z)]:
#					face_vert.append_array(vectorized_add_v3(tmp_vert, UP_FACE))
#				if z-1 > 0 and not blk_id_arr[flat_3d_to_1d(x, y, z-1)]:
#					face_vert.append_array(vectorized_add_v3(tmp_vert, FORWARD_FACE))
#				if z+1 < cll and not blk_id_arr[flat_3d_to_1d(x, y, z+1)]:
#					face_vert.append_array(vectorized_add_v3(tmp_vert, BACK_FACE))
				if blk_id_arr[i] != Air:
					if i-1 > 0 and blk_id_arr[i-1] == Air:
						face_vert.append_array(vectorized_add_v3(tmp_vert, LEFT_FACE))
					if i+1 < dimension_sum and blk_id_arr[i+1] == Air:
						face_vert.append_array(vectorized_add_v3(tmp_vert, RIGHT_FACE))
					if i-row > 0 and blk_id_arr[i-row] == Air:
						face_vert.append_array(vectorized_add_v3(tmp_vert, DOWN_FACE))
					if i+row < dimension_sum and blk_id_arr[i+row] == Air:
						face_vert.append_array(vectorized_add_v3(tmp_vert, UP_FACE))
					if i-(row*col) > 0 and blk_id_arr[i-(row*col)] == Air:
						face_vert.append_array(vectorized_add_v3(tmp_vert, FORWARD_FACE))
					if i+(row*col) < dimension_sum and blk_id_arr[i+(row*col)] == Air:
						face_vert.append_array(vectorized_add_v3(tmp_vert, BACK_FACE))
#				if blk_id_arr[i] == Air:
#					if i-1 > 0 and blk_id_arr[i-1] != Air:
#						face_vert.append_array(vectorized_add_v3(tmp_vert, LEFT_FACE))
#					if i+1 < dimension_sum and blk_id_arr[i+1] != Air:
#						face_vert.append_array(vectorized_add_v3(tmp_vert, RIGHT_FACE))
#					if i-row > 0 and blk_id_arr[i-row] != Air:
#						face_vert.append_array(vectorized_add_v3(tmp_vert, DOWN_FACE))
#					if i+row < dimension_sum and blk_id_arr[i+row] != Air:
#						face_vert.append_array(vectorized_add_v3(tmp_vert, UP_FACE))
#					if i-(row*col) > 0 and blk_id_arr[i-(row*col)] != Air:
#						face_vert.append_array(vectorized_add_v3(tmp_vert, FORWARD_FACE))
#					if i+(row*col) < dimension_sum and blk_id_arr[i+(row*col)] != Air:
#						face_vert.append_array(vectorized_add_v3(tmp_vert, BACK_FACE))


	for iv in range(0, face_vert.size(), 4):
		face_index.append_array([0+iv, 1+iv, 2+iv, 2+iv, 1+iv, 3+iv])

	for x in row:
		for y in col:
			for z in cll:
				var i := flat_3d_to_1d(x, y, z)
				printraw(blk_id_arr[i])

#	print(face_vert)
#	print(face_index)
#	print(neighbours_arr)
#	print(neighbours_arr[0])
#	print(face_vert.size())
#	print(face_index.size())

	if num_to_show >= 0 and num_to_show <= face_index.size():
		face_index.resize(num_to_show)

	var mesh_data := []
	mesh_data.resize(ArrayMesh.ARRAY_MAX)
	mesh_data[ArrayMesh.ARRAY_VERTEX] = face_vert
	mesh_data[ArrayMesh.ARRAY_INDEX] = face_index

	var arr_mesh := ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)

	mesh = arr_mesh


func flat_3d_to_1d(x: int, y: int, z: int) -> int: return x + (y * row) + (z * row * col)

# Avoid using this, as it cost more than flat_3d_to_1d
func expand_1d_to_3d(i: int) -> Vector3i: return Vector3i(i % row, i / row, i / (row * col))

func vectorized_add_v3(a: PackedVector3Array, b: PackedVector3Array) -> PackedVector3Array:
	if a.size() != b.size():
		push_error("both PackedVector3Array in vectorized_add_v3() are not the same size,",
				"will be trimmed to size of first argument")
	var ret := PackedVector3Array()
	ret.resize(a.size())
	for i in a.size(): ret[i] = a[i] + b[i]
	return ret

func _generate_block_id(pos: Vector3 = position) -> PackedByteArray:
	var ret := PackedByteArray()
	ret.resize(dimension_sum)
	ret.fill(Error)

	var noi := FastNoiseLite.new()
	noi.set_offset(pos)
	noi.set_frequency(0.03)

	var rng := RandomNumberGenerator.new()
	rng.set_seed(1023)

	for x in row:
		for y in col:
			for z in cll:
				var val := noi.get_noise_3d(x, y, z)
				var rnd_deep := rng.randi()
#				var density := -0.5 + (pos.y + y / 200.0)

				var blk_id := Air
				if val > -0.3:
					if y > col - 3:
						blk_id = Grass
					elif y > (rnd_deep & 1) + col - 7:
						blk_id = Dirt
					elif y > 0:
						blk_id = Stone

				ret[flat_3d_to_1d(x, y, z)] = blk_id

	if ret.find(Error) != -1: push_error("Found unused in the block id array ", ret.find(Error))
	return ret

func _generate_neighbours_arr(blk_id_arr: PackedByteArray) -> PackedByteArray:
	var ret := PackedByteArray()
	ret.resize(dimension_sum)

	for x in row:
		for y in col:
			for z in cll:
				var i := flat_3d_to_1d(x, y, z)
				var left    := Neighbour.Left    if x-1 > 0   and blk_id_arr[i - 1] else 0
				var right   := Neighbour.Right   if x+1 < row and blk_id_arr[i + 1] else 0
				var down    := Neighbour.Down    if y-1 > 0   and blk_id_arr[i - row] else 0
				var up      := Neighbour.Up      if y+1 < col and blk_id_arr[i + row] else 0
				var forward := Neighbour.Forward if z-1 > 0   and blk_id_arr[i - (row * col)] else 0
				var back    := Neighbour.Back    if z+1 < cll and blk_id_arr[i + (row * col)] else 0
				ret[i] = left | right | down | up | forward | back

	return ret
