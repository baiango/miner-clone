@tool
class_name Chunk extends GridMap

enum PerformanceInfo { None, Time, Info, Verbose }
var dbg := PerformanceInfo.Time

enum { Dirt, Grass, Stone, Void_grass, Crystal_blue, Air=254, Reset=255 }

var body = RID()


var dimension := Vector3i(64, 128, 64)
var row := dimension.x
var col := dimension.y
var cll := dimension.z # cells
var blk_id_arr := PackedByteArray()
func _init() -> void:
	position.y = -col
	blk_id_arr.resize(row * col * cll)
	print_debug([row, col, cll])
	print_debug(row * col * cll)
	print_debug(len(blk_id_arr))


func _ready() -> void:
	_regenerate()


func _regenerate(pos: Vector3i = Vector3i.ZERO) -> void:
	var clean_time := clean()
	var start: float = Time.get_ticks_usec()

	var noi := FastNoiseLite.new()
	noi.set_offset(pos)
	noi.set_frequency(0.03)

	var rng := RandomNumberGenerator.new()
	rng.set_seed(1023)

	var block_id_time: float = Time.get_ticks_usec()
	for x in row:
		for y in col:
			for z in cll:
				var val := noi.get_noise_3d(x, y, z)
				var rnd_deep := rng.randi()
				var density := -0.5 + (pos.y + y / 200.0)

				var blk_id := Air
				if val > density:
					if y > col - 3:
						blk_id = Grass
					elif y > (rnd_deep & 1) + col - 7:
						blk_id = Dirt
					elif y > 0:
						blk_id = Stone

				blk_id_arr[x + (y*row) + (z*row*col)] = blk_id
	block_id_time = (Time.get_ticks_usec() - block_id_time) / 1000.0

	var set_cell_time: float = Time.get_ticks_usec()

#	for x in row:
#		for y in col:
#			for z in cll:
#				set_cell_item(Vector3(x, y, z), blk_id_arr[x + (y*row) + (z*row*col)])

	# Total: 7.181 ms, a 27% boost.
	# Not edge
	for x in row:
		for y in col:
			for z in cll:
				if blk_id_arr[x + (y*row) + (z*row*col)] != Air: continue
				var v3 := Vector3(x, y, z)
				if x-1 > 0: set_cell_item(v3 + Vector3.LEFT,    blk_id_arr[x-1 + (y*row)     + (z*row*col)])
				if y-1 > 0: set_cell_item(v3 + Vector3.DOWN,    blk_id_arr[x   + ((y-1)*row) + (z*row*col)])
				if z-1 > 0: set_cell_item(v3 + Vector3.FORWARD, blk_id_arr[x   + (y*row)     + ((z-1)*row*col)])
				if x+1 < row: set_cell_item(v3 + Vector3.RIGHT, blk_id_arr[x+1 + (y*row)     + (z*row*col)])
				if y+1 < col: set_cell_item(v3 + Vector3.UP,    blk_id_arr[x   + ((y+1)*row) + (z*row*col)]) # does this cause the top block not showing? fixed it by using col instead of row
				if z+1 < cll: set_cell_item(v3 + Vector3.BACK,  blk_id_arr[x   + (y*row)     + ((z+1)*row*col)])


	# Edge
	for i in row:
		for j in cll:
			# set_cell_item(Vector3(0      , i      , j)              , blk_id_arr[          (i*row)       + (j*row*col)])
			# set_cell_item(Vector3(row - 1, i      , j)              , blk_id_arr[row - 1 + (i*row)       + (j*row*col)])
			# set_cell_item(Vector3(i      , 0      , j)              , blk_id_arr[i                       + (j*row*col)])
			# set_cell_item(Vector3(i      , col - 1, j)              , blk_id_arr[i       + ((col-1)*row) + (j*row*col)])
			# set_cell_item(Vector3(i      , j      , 0)              , blk_id_arr[i       + (j*row)                    ])
			# set_cell_item(Vector3(i      , j      , cll - 1), blk_id_arr[i       + (j*row)       + ((cll - 1)*row*col)])

			# 2.57% boost. (2987.642 + 2953.954 + 2975.305) / (2896.144 + 2885.804 + 2910.767)	if blk_id_arr[i*row + (j*row*col)] != Air:
			# if blk_id_arr[i*row + (j*row*col)] != Air:
			# 	set_cell_item(Vector3(0      , i      , j)              , blk_id_arr[          (i*row)       + (j*row*col)])
			# if blk_id_arr[row - 1 + (i*row) + (j*row*col)] != Air:
			# 	set_cell_item(Vector3(row - 1, i      , j)              , blk_id_arr[row - 1 + (i*row)       + (j*row*col)])
			# if blk_id_arr[i + (j*row*col)] != Air:
			# 	set_cell_item(Vector3(i      , 0      , j)              , blk_id_arr[i                       + (j*row*col)])
			# if blk_id_arr[i + ((col-1)*row) + (j*row*col)] != Air:
			# 	set_cell_item(Vector3(i      , col - 1, j)              , blk_id_arr[i       + ((col-1)*row) + (j*row*col)])
			# if blk_id_arr[i + (j*row)] != Air:
			# 	set_cell_item(Vector3(i      , j      , 0)              , blk_id_arr[i       + (j*row)                    ])
			# if blk_id_arr[i + (j*row) + ((cll - 1)*row*col)] != Air:
			# 	set_cell_item(Vector3(i      , j      , cll - 1), blk_id_arr[i       + (j*row)       + ((cll - 1)*row*col)])

			# Slow as the first one.
#			var a := blk_id_arr[i*row + (j*row*col)]
#			var b := blk_id_arr[row - 1 + (i*row) + (j*row*col)]
#			var c := blk_id_arr[i + (j*row*col)]
#			var d := blk_id_arr[i + ((col-1)*row) + (j*row*col)]
#			var e := blk_id_arr[i + (j*row)]
#			var f := blk_id_arr[i + (j*row) + ((cll - 1)*row*col)]
#			set_cell_item(Vector3(0      , i      , j)              , a)
#			set_cell_item(Vector3(row - 1, i      , j)              , b)
#			set_cell_item(Vector3(i      , 0      , j)              , c)
#			set_cell_item(Vector3(i      , col - 1, j)              , d)
#			set_cell_item(Vector3(i      , j      , 0)              , e)
#			set_cell_item(Vector3(i      , j      , cll - 1), f)

			# Don't optimize this please! I checked with Air and by not reading the memory.
			# It barely slows down.
#			set_cell_item(Vector3(0      , i      , j)              , Air)
#			set_cell_item(Vector3(row - 1, i      , j)              , Air)
#			set_cell_item(Vector3(i      , 0      , j)              , Air)
#			set_cell_item(Vector3(i      , col - 1, j)              , Air)
#			set_cell_item(Vector3(i      , j      , 0)              , Air)
#			set_cell_item(Vector3(i      , j      , cll - 1), Air)

			# Get rid of the second one! And use this one.
			# This won't work well with non-cube chunk.
			var LEFT_BLOCK := blk_id_arr[i*row + (j*row*col)] # LEFT_BLOCK as in Vector3.LEFT
			var RIGHT_BLOCK := blk_id_arr[row - 1 + (i*row) + (j*row*col)]
			var UP_BLOCK := blk_id_arr[i + ((col-1)*row) + (j*row*col)]
			var DOWN_BLOCK := blk_id_arr[i + (j*row*col)] # Why the row has to be 1? # Fixed now
			var FORWARD_BLOCK := blk_id_arr[i + (j*row)] # Note! FORWARD as is Vector3.FORWARD
			var BACK_BLOCK := blk_id_arr[i + (j*row) + ((cll - 1)*row*col)]
			if LEFT_BLOCK != Air:    set_cell_item(Vector3(0, i, j), LEFT_BLOCK)
			if RIGHT_BLOCK != Air:   set_cell_item(Vector3(row - 1, i, j), RIGHT_BLOCK)
			if UP_BLOCK != Air:      set_cell_item(Vector3(i, col - 1, j), UP_BLOCK)
			if DOWN_BLOCK != Air:    set_cell_item(Vector3(i, 0, j), DOWN_BLOCK)
			if FORWARD_BLOCK != Air: set_cell_item(Vector3(i, j, 0), FORWARD_BLOCK)
			if BACK_BLOCK != Air:    set_cell_item(Vector3(i, j, cll - 1), BACK_BLOCK)

	set_cell_time = (Time.get_ticks_usec() - set_cell_time) / 1000.0

	if dbg >= PerformanceInfo.Time:
		var block_sum: int = row * col * cll
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
