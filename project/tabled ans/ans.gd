@tool
extends GridMap

enum PerformanceInfo { None, Time, Info, Verbose }
var dbg := PerformanceInfo.Time

enum { Dirt, Grass, Stone, Void_grass, Crystal_blue, Air=254, Reset=255 }


func cbrt(num: float) -> float: return pow(num, 1.0/3.0)


func get_hash() -> int:
	var used_cells := get_used_cells()
	used_cells.sort()
	return hash(used_cells)


func clean() -> float:
	var start := Time.get_ticks_usec()
	clear()
	return (Time.get_ticks_usec() - start) / 1000.0


func reset() -> void:
	_regenerate(dimension)
	save(str(blk_id_arr))


func save(content: String) -> void:
	var file = FileAccess.open("user://save_game.dat", FileAccess.WRITE)
	file.store_string(content)


func prt_perf_stat(func_name: String, clean_time: float, regenerating_time: float, bps: int) -> void:
	var bps_cubed = snappedf(cbrt(bps), 0.1)
	var bps_cb_str = "".join(["(", "x".join([bps_cubed, bps_cubed, bps_cubed]), ")"])
	
	print(func_name, " stats:\n\t",
			"Clean up time: ", clean_time, " ms\n\t",
			"Regenerating time: ", regenerating_time, " ms or ", bps, bps_cb_str, " blocks/s")


"""
Cube cull 32 cubed:
_regenerate() stats:
	Clean up time: 2.036 ms
	Regenerating time: 37.796 ms or 866970(95.4x95.4x95.4) blocks/s
_regenerate() stats:
	Clean up time: 2.002 ms
	Regenerating time: 37.446 ms or 875073(95.6x95.6x95.6) blocks/s
_regenerate() stats:
	Clean up time: 2.566 ms
	Regenerating time: 37.675 ms or 869754(95.5x95.5x95.5) blocks/s

No cull 32 cubed:
_regenerate() stats:
	Clean up time: 0.397 ms
	Regenerating time: 49.121 ms or 667087(87.4x87.4x87.4) blocks/s
_regenerate() stats:
	Clean up time: 0.357 ms
	Regenerating time: 49.379 ms or 663601(87.2x87.2x87.2) blocks/s
_regenerate() stats:
	Clean up time: 0.645 ms
	Regenerating time: 62.373 ms or 525355(80.7x80.7x80.7) blocks/s

Cube cull 128 cubed:
_regenerate() stats:
	Clean up time: 56.33 ms
	Regenerating time: 2298.808 ms or 912278(97x97x97) blocks/s
_regenerate() stats:
	Clean up time: 52.069 ms
	Regenerating time: 2307.138 ms or 908984(96.9x96.9x96.9) blocks/s
_regenerate() stats:
	Clean up time: 52.194 ms
	Regenerating time: 2356.036 ms or 890118(96.2x96.2x96.2) blocks/s

No cull 128 cubed:
_regenerate() stats:
	Clean up time: 50.843 ms
	Regenerating time: 3226.474 ms or 649982(86.6x86.6x86.6) blocks/s
_regenerate() stats:
	Clean up time: 51.441 ms
	Regenerating time: 3209.465 ms or 653427(86.8x86.8x86.8) blocks/s
_regenerate() stats:
	Clean up time: 51.621 ms
	Regenerating time: 3224.221 ms or 650436(86.6x86.6x86.6) blocks/s

that's 32% performance boost for 32 cubed.
36% boost for 128 cubed.
"""
func _regenerate(dimension: Vector3i) -> void:
	var clean_time := clean()

	var start := Time.get_ticks_usec()

	var noi := FastNoiseLite.new()
	noi.set_frequency(0.03)

	var rng := RandomNumberGenerator.new()
	rng.set_seed(1023)

	var padding := 1
	var padded_dimension := dimension + Vector3i.ONE * padding * 2

	for x in range(padding, dimension.x + 1):
		for y in range(padding, dimension.y + 1):
			for z in range(padding, dimension.z + 1):
				var val := noi.get_noise_3d(x, y, z)
				var rnd_deep := rng.randi()

				var blk_id := Air
				if val > -0.3:
					if y > (rnd_deep & 3) + 5:
						blk_id = Stone
					elif y > (rnd_deep & 1) + 1:
						blk_id = Dirt
					elif y > 0:
						blk_id = Grass
				blk_id_arr[x][y][z] = blk_id

	var air_count := 0
	for ix in range(padding, dimension.x + padding):
		for iy in range(padding, dimension.y + padding):
			air_count += blk_id_arr[ix][iy].count(Air)

	# Block cull
	for ix in range(padding, dimension.x + padding):
		for iy in range(padding, dimension.y + padding):
			for iz in range(padding, dimension.z + padding):
				var in_place := blk_id_arr[ix][iy][iz] as int
				if in_place != Air:
					continue

				var left_block := blk_id_arr[ix-1][iy][iz] as int
				var right_block := blk_id_arr[ix+1][iy][iz] as int
				var top_block := blk_id_arr[ix][iy-1][iz] as int
				var bottom_block := blk_id_arr[ix][iy+1][iz] as int
				var back_block := blk_id_arr[ix][iy][iz-1] as int
				var front_block := blk_id_arr[ix][iy][iz+1] as int

				var x := ix - padding as int
				var y := iy - padding as int
				var z := iz - padding as int

				set_cell_item(Vector3i(x-1, ~y, z), left_block)
				set_cell_item(Vector3i(x+1, ~y, z), right_block)
				set_cell_item(Vector3i(x, ~(y-1), z), top_block)
				set_cell_item(Vector3i(x, ~(y+1), z), bottom_block)
				set_cell_item(Vector3i(x, ~y, z-1), back_block)
				set_cell_item(Vector3i(x, ~y, z+1), front_block)

	for ix in [padding, dimension.x]:
		for iy in range(padding, dimension.y + padding):
			for iz in range(padding, dimension.z + padding):
				var x := ix - padding as int
				var y := iy - padding as int
				var z := iz - padding as int

				if blk_id_arr[ix][iy][iz] == Air:
					continue
				elif blk_id_arr[ix][iy][iz] == Reset:
					clean()
					print_debug("Reset!")
					break

				set_cell_item(Vector3i(x, ~y, z), blk_id_arr[ix][iy][iz])

	for ix in range(padding, dimension.x + padding):
		for iy in [padding, dimension.y]:
			for iz in range(padding, dimension.z + padding):
				var x := ix - padding as int
				var y := iy - padding as int
				var z := iz - padding as int

				if blk_id_arr[ix][iy][iz] == Air:
					continue
				elif blk_id_arr[ix][iy][iz] == Reset:
					clean()
					print_debug("Reset!")
					break

				set_cell_item(Vector3i(x, ~y, z), blk_id_arr[ix][iy][iz])

	for ix in range(padding, dimension.x + padding):
		for iy in range(padding, dimension.y + padding):
			for iz in [padding, dimension.z]:
				var x := ix - padding as int
				var y := iy - padding as int
				var z := iz - padding as int

				if blk_id_arr[ix][iy][iz] == Air:
					continue
				elif blk_id_arr[ix][iy][iz] == Reset:
					clean()
					print_debug("Reset!")
					break

				set_cell_item(Vector3i(x, ~y, z), blk_id_arr[ix][iy][iz])

	# No cull
#	for ix in range(padding, dimension.x + padding):
#		for iy in range(padding, dimension.y + padding):
#			for iz in range(padding, dimension.z + padding):
#				var x := ix - padding as int
#				var y := iy - padding as int
#				var z := iz - padding as int
#
#				if blk_id_arr[ix][iy][iz] == Air:
#					continue
#				elif blk_id_arr[ix][iy][iz] == Reset:
#					clean()
#					print_debug("Reset!")
#					break
#
#				set_cell_item(Vector3i(x, ~y, z), blk_id_arr[ix][iy][iz])

	if dbg >= PerformanceInfo.Time:
		var block_sum := dimension.x * dimension.y * dimension.z
		var regenerating_time := (Time.get_ticks_usec() - start) / 1000.0
		var bps := floori(block_sum / ((Time.get_ticks_usec() - start) / 1_000_000.0))
		prt_perf_stat("_regenerate()", clean_time, regenerating_time, bps)


func destory_block(pos: Vector3i) -> void:
	set_cell_item(pos, INVALID_CELL_ITEM)
	var ipos := pos + (Vector3i.ONE * padding * padding)
	blk_id_arr[ipos.x][ipos.y][ipos.z] = Air
#	blk_id_arr[ipos.x-1][ipos.y][ipos.z] = Air
#	blk_id_arr[ipos.x+1][ipos.y][ipos.z] = Air
#	blk_id_arr[ipos.x][ipos.y-1][ipos.z] = Air
#	blk_id_arr[ipos.x][ipos.y+1][ipos.z] = Air
#	blk_id_arr[ipos.x][ipos.y][ipos.z-1] = Air
#	blk_id_arr[ipos.x][ipos.y][ipos.z+1] = Air

	var left_block := blk_id_arr[ipos.x-1][ipos.y][ipos.z] as int
	var right_block := blk_id_arr[ipos.x+1][ipos.y][ipos.z] as int
	var top_block := blk_id_arr[ipos.x][ipos.y-1][ipos.z] as int
	var bottom_block := blk_id_arr[ipos.x][ipos.y+1][ipos.z] as int
	var back_block := blk_id_arr[ipos.x][ipos.y][ipos.z-1] as int
	var front_block := blk_id_arr[ipos.x][ipos.y][ipos.z+1] as int
	set_cell_item(Vector3i(pos.x-1, ~pos.y  , pos.z), left_block)
	set_cell_item(Vector3i(pos.x+1, pos.y  , pos.z), right_block)
	set_cell_item(Vector3i(pos.x  , pos.y-1, pos.z), top_block)
	set_cell_item(Vector3i(pos.x  , pos.y+1, pos.z), bottom_block)
	set_cell_item(Vector3i(pos.x  , pos.y  , pos.z-1), back_block)
	set_cell_item(Vector3i(pos.x  , pos.y  , pos.z+1), front_block)


var dimension := Vector3i(32, 32, 32)
var blk_id_arr := []
var lightmap := []
var padding := 1
var padded_dimension := dimension + Vector3i.ONE * padding * 2
func _init() -> void:
	blk_id_arr.resize(padded_dimension.x)
	for x in padded_dimension.x:
		blk_id_arr[x] = []
		blk_id_arr[x].resize(padded_dimension.y)
		for y in padded_dimension.y:
			blk_id_arr[x][y] = PackedByteArray()
			blk_id_arr[x][y].resize(padded_dimension.z)

	for x in padded_dimension.x:
		for y in padded_dimension.y:
			for z in padded_dimension.z:
				blk_id_arr[x][y][z] = Air

	# Air block cull, it will be light cull soon.
	lightmap.resize(padded_dimension.x)
	for x in padded_dimension.x:
		lightmap[x] = []
		lightmap[x].resize(padded_dimension.y)
		for y in padded_dimension.y:
			lightmap[x][y] = PackedByteArray()
			lightmap[x][y].resize(padded_dimension.z)


func _ready() -> void: # "Scene -> Reload Saved Scene" to see the changes!
#	return
	reset()
	var c = Cosmic.new()

	print_debug(c.rng64(32))
	print_debug(c.rng64(32))
	print_debug(c.rng64(32))
	print_debug(c.rng64(32))
	print_debug(c.rng64())
	print_debug(c.rng64())
	print_debug(c.rng64(1))
	print_debug(c.rng64(1))
	print_debug(c.rng64(1))

	print_debug(c.rng_array(5))

func _on_tree_exiting():
	clear()
