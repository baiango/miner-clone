extends Node


enum UnitTest { None, Light, Brute_force } # Brute_force will freeze Godot for at least 10 seconds
var err_dbg := UnitTest.Light

var dimension := Glob.dimension
var row := dimension.x
var col := dimension.y
var cll := dimension.z # cells


func _ready() -> void:
	if err_dbg >= UnitTest.Light:
		unit_test()


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("lmb"):
		if not (kira as Kira).anim_locked:
			($BreakBlock as Timer).start()


@onready var kira := Glob.KIRA as Kira
@onready var hit := $"../Skeleton3D/pipe/pipe/hit" as AudioStreamPlayer3D
@onready var hit_miss := $"../Skeleton3D/pipe/pipe/hit/hit_miss" as AudioStreamPlayer3D
@onready var blks: Chunk = null
func _on_break_block_timeout() -> void:
	var hit_pos := Vector3i(hit.get_global_position().floor())
	var chunk_pos := Vector3i(
		floorf(float(hit_pos.x) / row) * row,
		floorf(float(hit_pos.y) / col) * col,
		floorf(float(hit_pos.z) / cll) * cll,
	)

#	hit_pos.y += col
	# hit_pos.x = (hit_pos.x + row) % row
	# hit_pos.y = (hit_pos.y + col) % col
	# hit_pos.z = (hit_pos.z + cll) % cll

	($BreakPos as Node3D).position = Vector3(hit_pos) + Vector3(chunk_pos)
	($BreakPos as Node3D).position.y += col

	var chunks := Glob.CHUNKS.get_children()
	blks = null
	for c in chunks:
		if (c as Chunk).get_position() == Vector3(chunk_pos):
			blks = c as Chunk
			break

	if blks:
		if blks.get_cell_item(hit_pos) == GridMap.INVALID_CELL_ITEM:
			print("down!")

			chunk_pos = Vector3i(
				floorf(float(hit_pos.x) / row) * row,
				floorf(float(hit_pos.y) / col) * col,
				floorf(float(hit_pos.z) / cll) * cll,
			)

			blks = null
			for c in chunks:
				if (c as Chunk).get_position() == Vector3(chunk_pos):
					blks = c as Chunk
					break

			print("hit_pos: ", hit_pos)
			print("chunk_pos: ", chunk_pos)
			print("hit unmod pos: ", Vector3i(hit.get_global_position().floor()))
			print(blks)
	else:
		print("down!")

		chunk_pos = Vector3i(
			floorf(float(hit_pos.x) / row) * row,
			floorf(float(hit_pos.y) / col) * col,
			floorf(float(hit_pos.z) / cll) * cll,
		)

		blks = null
		for c in chunks:
			if (c as Chunk).get_position() == Vector3(chunk_pos):
				blks = c as Chunk
				break

		print("hit_pos: ", hit_pos)
		print("chunk_pos: ", chunk_pos)
		print("hit unmod pos: ", Vector3i(hit.get_global_position().floor()))
		print(blks)

	if blks:
		print("checking")
		if blks.get_cell_item(hit_pos) != GridMap.INVALID_CELL_ITEM:
			print("destory!")
			destory_block(hit_pos)
		else:
			hit_miss.play()

	# for i in 3:
	# 	if blks:
	# 		if blks.get_cell_item(hit_pos) == GridMap.INVALID_CELL_ITEM:
	# 			down.call()
	# 		elif blks.get_cell_item(hit_pos) != GridMap.INVALID_CELL_ITEM:
	# 			destory_block(hit_pos)
	# 			hit.play()
	# 		else:
	# 			hit_miss.play()
	# 	else:
	# 		down.call()

	# print(chunk_pos)
	# print(hit_pos)
	($BreakPos as Node3D).position = Vector3(hit_pos) + Vector3(chunk_pos)
#	($BreakPos as Node3D).position.y += col
	print("BreakPos: ", ($BreakPos as Node3D).position)


func destory_block(pos: Vector3i) -> void:
	var x := pos.x; var y := pos.y; var z := pos.z

#	if minimum([x, y, z]) < 0: return
#	if x >= row or y >= col or z >= cll: return # Found the bug by unit_test() and fixed the bug!

	blks.blk_id_arr[x + (y*row) + (z*row*col)] = blks.Air
	blks.set_cell_item(Vector3i(x, y, z), GridMap.INVALID_CELL_ITEM)


#	var LEFT_BLOCK: int = blks.Air; var DOWN_BLOCK: int = blks.Air; var FORWARD_BLOCK: int = blks.Air; var RIGHT_BLOCK: int = blks.Air; var UP_BLOCK: int = blks.Air; var BACK_BLOCK: int = blks.Air
#	if x-1 > 0:
#		LEFT_BLOCK = blks.blk_id_arr[x-1 + (y*row) + (z*row*col)]
#		if LEFT_BLOCK != blks.Air: blks.set_cell_item(pos + Vector3i.LEFT, LEFT_BLOCK)
#	if y-1 > 0:
#		DOWN_BLOCK = blks.blk_id_arr[x + ((y-1)*row) + (z*row*col)]
#		if DOWN_BLOCK != blks.Air: blks.set_cell_item(pos + Vector3i.DOWN, DOWN_BLOCK)
#	if z-1 > 0:
#		FORWARD_BLOCK = blks.blk_id_arr[x + (y*row) + ((z-1)*row*col)]
#		if FORWARD_BLOCK != blks.Air: blks.set_cell_item(pos + Vector3i.FORWARD, FORWARD_BLOCK)
#	if x+1 < row:
#		RIGHT_BLOCK = blks.blk_id_arr[x+1 + (y*row) + (z*row*col)]
#		if RIGHT_BLOCK != blks.Air: blks.set_cell_item(pos + Vector3i.RIGHT, RIGHT_BLOCK)
#	if y+1 < col:
#		UP_BLOCK = blks.blk_id_arr[x + ((y+1)*row) + (z*row*col)]
#		if UP_BLOCK != blks.Air: blks.set_cell_item(pos + Vector3i.UP, UP_BLOCK)
#	if z+1 < cll:
#		BACK_BLOCK = blks.blk_id_arr[x + (y*row) + ((z+1)*row*col)]
#		if BACK_BLOCK != blks.Air: blks.set_cell_item(pos + Vector3i.BACK, BACK_BLOCK)

func unit_test() -> void:
	var start: float = Time.get_ticks_usec()
	if err_dbg >= UnitTest.Brute_force:
		for x in range(-row, row * 2):
			for y in range(-col, col * 2):
				for z in range(-cll, cll * 2):
					destory_block(Vector3i(x, y, z))
	print("unit_test() completed in ", (Time.get_ticks_usec() - start) / 1000.0," ms")

func minimum(nums: PackedInt64Array) -> int:
	var ret := 2 ** 63 - 1
	for n in nums: ret = mini(ret, n)
	return ret
