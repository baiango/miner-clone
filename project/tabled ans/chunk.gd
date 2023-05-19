@tool
extends GridMap


enum PerformanceInfo { None, Time, Info, Verbose }
var dbg := PerformanceInfo.Time

enum { Dirt, Grass, Stone, Void_grass, Crystal_blue, Air=254, Reset=255 }

# func blk(y): # Used for precomputing.
# 	var blk_id = Air
# 	var col = dimension.y
# 	var rng := RandomNumberGenerator.new()
# 	rng.set_seed(1023)
# 	var rnd_deep := rng.randi()

# 	if y > col - 3:
# 		blk_id = Grass
# 	elif y > (rnd_deep & 1) + col - 7:
# 		blk_id = Dirt
# 	elif y > 0:
# 		blk_id = Stone
# 	return blk_id

''' _regenerate() stats:
		Clean up time: 1.968 ms
		Regenerating time: 23.776 ms or 1378196(111.3x111.3x111.3) blocks/s
		block_id_time: 14.254 ms
		set_cell_time: 9.355 ms '''
var dimension := Vector3i(32, 32, 32)
func _ready():
	var clean_time := clean()
	var start: float = Time.get_ticks_usec()

	var noi := FastNoiseLite.new()
	noi.set_frequency(0.03)

	var rng := RandomNumberGenerator.new()
	rng.set_seed(1023)

	var cosmic := Cosmic.new()

	var row := dimension.x
	var col := dimension.y
	var blk_id_arr := PackedByteArray()
	blk_id_arr.resize(row * col * dimension.z)

	# Precomputation
	# var blk_precomputed := PackedByteArray()
	# for y in col:
	# 	blk_precomputed.append(blk(y))
	# print(blk_precomputed)

	var block_id_time: float = Time.get_ticks_usec()
	for x in row:
		for y in col:
			for z in dimension.z:
				var val := noi.get_noise_3d(x, y, z)
				var rnd_deep := rng.randi()

				var blk_id := Air
				if val > -0.3:
					if y > col - 3:
						blk_id = Grass
					elif y > (rnd_deep & 1) + col - 7:
						blk_id = Dirt
					elif y > 0:
						blk_id = Stone

				blk_id_arr[x + (y*row) + (z*row*col)] = blk_id

# 13.017 ms
# 				if val > -0.3:
# 					if y > col - 3:
# 						blk_id = Grass
# 					elif y > col - 7:
# 						blk_id = Dirt
# 					elif y > 0:
# 						blk_id = Stone
# 11.69 ms
# 				if val > -0.3:
# 					blk_id = blk_precomputed[y]
# 13.839 ms
# 				if val > -0.3:
# 					blk_id = blk_precomputed[y]
# 					if y > (rnd_deep & 1) + col - 7:
# 						blk_id = Dirt
# 14.102 ms
# 				if val > -0.3:
# 					if y > col - 3:
# 						blk_id = Grass
# 					elif y > (rnd_deep & 1) + col - 7:
# 						blk_id = Dirt
# 					elif y > 0:
# 						blk_id = Stone

				# There's no way to precompute this thing.

	# 3d: 11.322 ms, 11.001 ms, 10.521 ms
#	for x in row:
#		for y in col:
#			for z in dimension.z:
#				var val := noi.get_noise_3d(x, y, z)
#				blk_id_arr[x + (y*row) + (z*row*col)] = Air

	# 1d with bitwise AND: 10.924 ms, 11.202 ms, 10.097 ms
#	for i in row*col*dimension.z:
#		var val := noi.get_noise_3d(i & 31, i >> 5, i >> 10)
#		#var val := noi.get_noise_3d(i % row, i / row % col, i / row / col)
#		blk_id_arr[i] = Air

	# Probably going to use the 3d one, as it's much easier to read.

	block_id_time = (Time.get_ticks_usec() - block_id_time) / 1000.0

	var set_cell_time: float = Time.get_ticks_usec()
	# 3d with multiply: 9.036 ms, 9.299 ms, 9.037 ms
	for x in row:
		for y in col:
			for z in dimension.z:
				set_cell_item(Vector3i(x, y, z), blk_id_arr[x + (y*row) + (z*row*col)])
				# Doesn't make any faster.
#				set_cell_item(Vector3i(x, y, z), blk_id_arr[x + (y<<5) + (z<<10)])

	# 1d with modulo: 11.96 ms, 12.719 ms, 11.969 ms
#	for i in row*col*dimension.z:
#		set_cell_item(Vector3i(i % row, i / row % col, i / row / col), blk_id_arr[i])

	# 1d with bitwise AND: 10.983 ms, 10.759 ms, 11.093 ms
#	for i in row*col*dimension.z:
#		set_cell_item(Vector3i(i & 31, (i / row) & 31, i / row / col), blk_id_arr[i])

#	# 1d with modulo and loop blocking: 12.831 ms, 12.36 ms, 12.648 ms
#	var block_size = 16**3
#	var max = row*col*dimension.z
#	for ii in range(0, max, block_size):
#		for i in range(ii, ii + block_size):
#			set_cell_item(Vector3i(i % row, i / row % col, i / row / col), blk_id_arr[i])

	# 3d with bitwise and loop baked: 9.036 ms, 9.299 ms, 9.037 ms
#	for x in range(row):
#		for y in range(row, row << 5, row):
#			for z in range(row << 5, row << 10, row << 5):
#				set_cell_item(Vector3i(x, y >> 5, z >> 10), blk_id_arr[x+y+z])

	# 3d while loop: 9.822 ms, 10.449 ms, 10.299 ms
#	var x := 0
#	while x < row:
#		var y := 0
#		while y < col:
#			var z := 0
#			while z < dimension.z:
#				set_cell_item(Vector3i(x, y, z), blk_id_arr[x + (y * row) + (z * row * col)])
#				z += 1
#			y += 1
#		x += 1

	# Tried all of it. The end of the story. Stick with the first one.

	set_cell_time = (Time.get_ticks_usec() - set_cell_time) / 1000.0

	if dbg >= PerformanceInfo.Time:
		var block_sum: int = dimension.x * dimension.y * dimension.z
		var regenerating_time: float = (Time.get_ticks_usec() - start) / 1000.0
		var bps: int = floori(block_sum / ((Time.get_ticks_usec() - start) / 1_000_000.0))
		prt_perf_stat("_regenerate()", clean_time, regenerating_time, bps, block_id_time, set_cell_time)

# Non-important function are spaced 1 newline instead of 2.
func cbrt(num: float) -> float: return pow(num, 1.0/3.0)

func destory_block(pos: Vector3i) -> void:
	set_cell_item(pos, Air)

func clean() -> float:
	var start: float = Time.get_ticks_usec()
	clear()
	return (Time.get_ticks_usec() - start) / 1000.0

func prt_perf_stat(func_name: String, clean_time: float, regenerating_time: float, bps: int, block_id_time: float, set_cell_time: float) -> void:
	var bps_cubed = snappedf(cbrt(bps), 0.1)
	var bps_cb_str = "".join(["(", "x".join([bps_cubed, bps_cubed, bps_cubed]), ")"])

	print(func_name, " stats:")
	print("\tClean up time: ", clean_time, " ms")
	print("\tRegenerating time: ", regenerating_time, " ms or ", bps, bps_cb_str, " blocks/s")
	print("\tblock_id_time: ", block_id_time, " ms")
	print("\tset_cell_time: ", set_cell_time, " ms")


func _on_tree_exiting():
	clear()
