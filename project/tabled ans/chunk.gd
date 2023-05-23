@tool
class_name Chunk extends GridMap

enum PerformanceInfo { None, Time, Info, Verbose }
var dbg := PerformanceInfo.Time

enum { Dirt, Grass, Stone, Void_grass, Crystal_blue, Air=254, Reset=255 }

var body = RID()


var dimension := Vector3i(64, 128, 32)
var row := dimension.x
var col := dimension.y
var cll := dimension.z # cells
var blk_id_arr := PackedByteArray()
func _init() -> void:
	position.y = -col
	blk_id_arr.resize(row * col * cll)


func _ready() -> void:
	_regenerate()


@warning_ignore("narrowing_conversion")
func _regenerate(pos: Vector3i = Vector3i(position.x, position.y + col, position.z)) -> void:
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

#	for x in row: # debug
#		for y in col:
#			for z in cll:
#				set_cell_item(Vector3(x, y, z), blk_id_arr[x + (y*row) + (z*row*col)])

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
		for j in col:
			var FORWARD_BLOCK := blk_id_arr[i + (j*row)] # Note! FORWARD as is Vector3.FORWARD
			var BACK_BLOCK := blk_id_arr[i + (j*row) + ((cll-1)*row*col)]
			if FORWARD_BLOCK != Air: set_cell_item(Vector3(i, j, 0), FORWARD_BLOCK)
			if BACK_BLOCK != Air:    set_cell_item(Vector3(i, j, cll - 1), BACK_BLOCK)

	for i in cll:
		for j in col:
			var LEFT_BLOCK := blk_id_arr[j*row + (i*row*col)]  # LEFT_BLOCK as in Vector3.LEFT
			var RIGHT_BLOCK := blk_id_arr[row - 1 + (j*row) + (i*row*col)]
			if LEFT_BLOCK != Air:    set_cell_item(Vector3(0, j, i), LEFT_BLOCK)
			if RIGHT_BLOCK != Air:   set_cell_item(Vector3(row - 1, j, i), RIGHT_BLOCK)

	for i in row:
		for j in cll:
			var UP_BLOCK := blk_id_arr[i + ((col-1)*row) + (j*row*col)]
			var DOWN_BLOCK := blk_id_arr[i + (j*row*col)]
			if UP_BLOCK != Air:      set_cell_item(Vector3(i, col - 1, j), UP_BLOCK)
			if DOWN_BLOCK != Air:    set_cell_item(Vector3(i, 0, j), DOWN_BLOCK)

	set_cell_time = (Time.get_ticks_usec() - set_cell_time) / 1000.0

	if dbg >= PerformanceInfo.Time:
		var block_sum: int = row * col * cll
		var regenerating_time: float = (Time.get_ticks_usec() - start) / 1000.0
		var bps: int = floori(block_sum / ((Time.get_ticks_usec() - start) / 1_000_000.0))
		prt_perf_stat("_regenerate()", clean_time, regenerating_time, bps, block_id_time, set_cell_time)

# Non-important function are spaced 1 newline instead of 2.
func cbrt(num: float) -> float: return pow(num, 1.0/3.0)

func minimum(nums: PackedInt64Array) -> int:
	var ret := 2 ** 63 - 1
	for n in nums: ret = mini(ret, n)
	return ret

func destory_block(x: int, y: int, z: int) -> void:
	# Fixed the bug!
	if minimum([x, y, z]) < 0: return
	if x > row or y > col or z > cll: return
	blk_id_arr[x + (y*row) + (z*row*col)] = Air
	set_cell_item(Vector3i(x, y, z), Air)

	if x-1 > 0: set_cell_item(Vector3i(x, y, z) + Vector3i.LEFT,    blk_id_arr[x-1 + (y*row)     + (z*row*col)])
	if y-1 > 0: set_cell_item(Vector3i(x, y, z) + Vector3i.DOWN,    blk_id_arr[x   + ((y-1)*row) + (z*row*col)])
	if z-1 > 0: set_cell_item(Vector3i(x, y, z) + Vector3i.FORWARD, blk_id_arr[x   + (y*row)     + ((z-1)*row*col)])
	if x+1 < row: set_cell_item(Vector3i(x, y, z) + Vector3i.RIGHT, blk_id_arr[x+1 + (y*row)     + (z*row*col)])
	if y+1 < col: set_cell_item(Vector3i(x, y, z) + Vector3i.UP,    blk_id_arr[x   + ((y+1)*row) + (z*row*col)])
	if z+1 < cll: set_cell_item(Vector3i(x, y, z) + Vector3i.BACK,  blk_id_arr[x   + (y*row)     + ((z+1)*row*col)])

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

func _on_tree_exiting() -> void:
	clear()
