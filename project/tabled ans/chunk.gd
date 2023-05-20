@tool
extends GridMap


enum PerformanceInfo { None, Time, Info, Verbose }
var dbg := PerformanceInfo.Time

enum { Dirt, Grass, Stone, Void_grass, Crystal_blue, Air=254, Reset=255 }

'''
Previous commit:
_regenerate() stats:
	Clean up time: 1.968 ms
	Regenerating time: 23.776 ms or 1378196(111.3x111.3x111.3) blocks/s
	block_id_time: 14.254 ms
	set_cell_time: 9.355 ms
New: Improved by 9.8% blocks/s. set_cell_time improved by 30%.
_regenerate() stats:
	Clean up time: 0.425 ms
	Regenerating time: 21.653 ms or 1513323(114.8x114.8x114.8) blocks/s
	block_id_time: 14.327 ms
	set_cell_time: 7.181 ms
'''
var dimension := Vector3i(32, 32, 32)
var row := dimension.x
var col := dimension.y
var blk_id_arr := PackedByteArray()
func _init() -> void:
	position.y = -col
	blk_id_arr.resize(row * col * dimension.z)


func _ready() -> void:
	_regenerate()


func _regenerate() -> void:
	var clean_time := clean()
	var start: float = Time.get_ticks_usec()

	var noi := FastNoiseLite.new()
	noi.set_frequency(0.03)

	var rng := RandomNumberGenerator.new()
	rng.set_seed(1023)

	var cosmic := Cosmic.new()

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
	block_id_time = (Time.get_ticks_usec() - block_id_time) / 1000.0

	var set_cell_time: float = Time.get_ticks_usec()
	# 9.127 ms
#	for x in row:
#		for y in col:
#			for z in dimension.z:
#				set_cell_item(Vector3i(x, y, z), blk_id_arr[x + (y*row) + (z*row*col)])

	# Total: 7.181 ms, a 27% boost.
	# Not edge
	for x in row:
		for y in col:
			for z in dimension.z:
				if blk_id_arr[x + (y*row) + (z*row*col)] != Air: continue
				var v3 := Vector3(x, y, z)
				if x-1 > 0: set_cell_item(v3 + Vector3.LEFT,    blk_id_arr[x-1 + (y*row)     + (z*row*col)])
				if y-1 > 0: set_cell_item(v3 + Vector3.DOWN,    blk_id_arr[x   + ((y-1)*row) + (z*row*col)])
				if z-1 > 0: set_cell_item(v3 + Vector3.FORWARD, blk_id_arr[x   + (y*row)     + ((z-1)*row*col)])
				if x+1 < row: set_cell_item(v3 + Vector3.RIGHT, blk_id_arr[x+1 + (y*row)     + (z*row*col)])
				if y+1 < row: set_cell_item(v3 + Vector3.UP,    blk_id_arr[x   + ((y+1)*row) + (z*row*col)])
				if z+1 < row: set_cell_item(v3 + Vector3.BACK,  blk_id_arr[x   + (y*row)     + ((z+1)*row*col)])

#	# chatGPT assisted.
#	# Edge
	for i in row:
		for j in col:
			set_cell_item(Vector3(0      , i      , j)              , blk_id_arr[          (i*row)       + (j*row*col)])
			set_cell_item(Vector3(row - 1, i      , j)              , blk_id_arr[row - 1 + (i*row)       + (j*row*col)])
			set_cell_item(Vector3(i      , 0      , j)              , blk_id_arr[i                       + (j*row*col)])
			set_cell_item(Vector3(i      , col - 1, j)              , blk_id_arr[i       + ((col-1)*row) + (j*row*col)])
			set_cell_item(Vector3(i      , j      , 0)              , blk_id_arr[i       + (j*row)                    ])
			set_cell_item(Vector3(i      , j      , dimension.z - 1), blk_id_arr[i       + (j*row)       + ((dimension.z - 1)*row*col)])

	set_cell_time = (Time.get_ticks_usec() - set_cell_time) / 1000.0

	if dbg >= PerformanceInfo.Time:
		var block_sum: int = row * col * dimension.z
		var regenerating_time: float = (Time.get_ticks_usec() - start) / 1000.0
		var bps: int = floori(block_sum / ((Time.get_ticks_usec() - start) / 1_000_000.0))
		prt_perf_stat("_regenerate()", clean_time, regenerating_time, bps, block_id_time, set_cell_time)

# Non-important function are spaced 1 newline instead of 2.
func cbrt(num: float) -> float: return pow(num, 1.0/3.0)

func destory_block(x: int, y: int, z: int) -> void:
	blk_id_arr[x + (y*row) + (z*row*col)] = Air
	set_cell_item(Vector3i(x, y, z), Air)

	if x-1 > 0: set_cell_item(Vector3i(x, y, z) + Vector3i.LEFT,    blk_id_arr[x-1 + (y*row)     + (z*row*col)])
	if y-1 > 0: set_cell_item(Vector3i(x, y, z) + Vector3i.DOWN,    blk_id_arr[x   + ((y-1)*row) + (z*row*col)])
	if z-1 > 0: set_cell_item(Vector3i(x, y, z) + Vector3i.FORWARD, blk_id_arr[x   + (y*row)     + ((z-1)*row*col)])
	if x+1 < row: set_cell_item(Vector3i(x, y, z) + Vector3i.RIGHT, blk_id_arr[x+1 + (y*row)     + (z*row*col)])
	if y+1 < row: set_cell_item(Vector3i(x, y, z) + Vector3i.UP,    blk_id_arr[x   + ((y+1)*row) + (z*row*col)])
	if z+1 < row: set_cell_item(Vector3i(x, y, z) + Vector3i.BACK,  blk_id_arr[x   + (y*row)     + ((z+1)*row*col)])

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

func reset() -> void:
	_regenerate()

func _on_tree_exiting():
	clear()
