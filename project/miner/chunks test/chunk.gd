@tool
extends GridMap


enum PerformanceInfo { None, Time, Info, Verbose }
var dbg := PerformanceInfo.None

enum { Dirt, Grass, Stone, Void_grass, Crystal_blue, Air=254, Reset=255 }

'''
Kira:
There are not many reasons to use 64 cubes block as the chunk.
First, it slows the game even if did increase its efficiency.
Second, it decreases the md5/blake3 data deduplication hit rate.
Third, it limits how close can level of detail get to Kira.
Just use 16 cubed blocks!

Me:
6.962 ms for 16 cubed, discarding a thread can take up to 10ms.
16 cubed is too small.
42.466 ms for 32 cubed. It is still too small, needs something like 100 ms.
136.153 ms for 48 cubed. The only problem is not bitwise operators compatible.
302.506 ms for 64 cubed. This is the right load for the CPU. But might be too heavy for potatoes.
Potatoes would be like 1000 ms.

Kira:
Hi Ziv! I would like you to try this out. Vector3i(128, 16, 128)
It is the same amount of blocks as 64 cubed.
And it is compatible with bitwise operators.

Me:
How about 32 cubed, but using chunks manager to set the horizontal and vertical generate distance.

Kira:
Try to queue the thread to generate a chunk instead of discarding it after it generates a chunk.
Like... Use chunks manager to place the block instead of the chunk itself.
So you can keep the thread easily.
'''
var dimension := Vector3i(64, 64, 64)
var row := dimension.x
var col := dimension.y
var blk_id_arr := PackedByteArray()
func _init() -> void:
	blk_id_arr.resize(row * col * dimension.z)

func _regenerate() -> void:
	var clean_time := clean()
	var start: float = Time.get_ticks_usec()

	var noi := FastNoiseLite.new()
	noi.set_frequency(0.03)
	# 363.202 ms, 344.709 ms, 358.013 ms
	noi.set_noise_type(FastNoiseLite.TYPE_SIMPLEX) # Does it make it fast? Due to its less complex smoothing.
	# 428.549 ms, 446.794 ms, 422.437 ms
#	noi.set_noise_type(FastNoiseLite.TYPE_SIMPLEX_SMOOTH) # It's default setting
	noi.set_offset(position)

	var rng := RandomNumberGenerator.new()
	rng.set_seed(1023)

#	var cosmic := Cosmic.new()

	var block_id_time: float = Time.get_ticks_usec()
	for x in row:
		for y in col:
			for z in dimension.z:
#				noi.set_frequency(y/1000.0) # Big fail
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

	# Edge
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

func clean() -> float:
	var start: float = Time.get_ticks_usec()
	clear()
	return (Time.get_ticks_usec() - start) / 1000.0

# Too awesome for multithreading to handle. So it mangles together.
func prt_perf_stat(func_name: String, clean_time: float, regenerating_time: float, bps: int, block_id_time: float, set_cell_time: float) -> void:
	var bps_cubed = snappedf(cbrt(bps), 0.1)
	var bps_cb_str = "".join(["(", "x".join([bps_cubed, bps_cubed, bps_cubed]), ")"])

	print(func_name, " stats:")
	print("\tClean up time: ", clean_time, " ms")
	print("\tRegenerating time: ", regenerating_time, " ms or ", bps, bps_cb_str, " blocks/s")
	print("\tblock_id_time: ", block_id_time, " ms")
	print("\tset_cell_time: ", set_cell_time, " ms")

func _ready() -> void:
	set_name(str(position))
	reset()

func reset() -> void:
	_regenerate()

func _on_tree_exiting():
	clear()
