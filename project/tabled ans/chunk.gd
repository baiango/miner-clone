@tool
class_name Chunk extends GridMap

enum PerformanceInfo { None, Time, Info, Verbose }
var perf_dbg := PerformanceInfo.Time
enum UnitTest { None, Light, Brute_force } # Brute_force will freeze Godot for at least 10 seconds
var err_dbg := UnitTest.Light

enum { Dirt, Grass, Stone, Void_grass, Crystal_blue, Air=254, Error=255 }

var body = RID()


var dimension := Vector3i(32, 64, 16)
var row := dimension.x
var col := dimension.y
var cll := dimension.z # cells
var blk_id_arr := PackedByteArray()
func _init() -> void:
	position.y = -col
	blk_id_arr.resize(row * col * cll)
	blk_id_arr.fill(Error)


func _ready() -> void:
	_regenerate()
	if err_dbg >= UnitTest.Light:
		unit_test()


func _regenerate() -> void:
	var clean_time := clean()
	var start: float = Time.get_ticks_usec()

	var block_id_time: float = _regenerate_block_id()
	if err_dbg >= UnitTest.Light:
		var error_found_index := blk_id_arr.find(Error)
		@warning_ignore("integer_division")
		var xyz := [error_found_index % row, error_found_index / row % col, error_found_index / row / col]
		if error_found_index != -1:
			push_error("".join(["Found Error(id 255)/Unused in the blk_id_arr[", error_found_index, "] or ", xyz," when generating blocks... Is it unused?"]))

	var set_cell_time: float = _set_cell()
	if err_dbg >= UnitTest.Light:
		var air_list := get_used_cells_by_item(Air)
		if air_list:
			push_error("".join(["Found ", len(air_list), " Air(id 254)! There should be no air in the Chunk! Use GridMap.INVALID_CELL_ITEM instead."]))

	if perf_dbg >= PerformanceInfo.Time:
		var block_sum := row * col * cll
		var regenerating_time: float = (Time.get_ticks_usec() - start) / 1000.0
		var bps := floori(block_sum / ((Time.get_ticks_usec() - start) / 1_000_000.0))
		prt_perf_stat("_regenerate()", clean_time, regenerating_time, bps, block_id_time, set_cell_time)


@warning_ignore("narrowing_conversion")
func _regenerate_block_id(pos: Vector3i = Vector3i(position.x, position.y + col, position.z)) -> float:
	var block_id_time: float = Time.get_ticks_usec()
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

				blk_id_arr[x + (y*row) + (z*row*col)] = blk_id

	return (Time.get_ticks_usec() - block_id_time) / 1000.0


func _set_cell() -> float:
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
				var LEFT_BLOCK: int = Air; var DOWN_BLOCK: int = Air; var FORWARD_BLOCK: int = Air; var RIGHT_BLOCK: int = Air; var UP_BLOCK: int = Air; var BACK_BLOCK: int = Air
				if x-1 > 0: LEFT_BLOCK = blk_id_arr[x-1 + (y*row) + (z*row*col)]
				if y-1 > 0: DOWN_BLOCK = blk_id_arr[x + ((y-1)*row) + (z*row*col)]
				if z-1 > 0: FORWARD_BLOCK = blk_id_arr[x + (y*row) + ((z-1)*row*col)]
				if x+1 < row: RIGHT_BLOCK = blk_id_arr[x+1 + (y*row) + (z*row*col)]
				if y+1 < col: UP_BLOCK = blk_id_arr[x + ((y+1)*row) + (z*row*col)]
				if z+1 < cll: BACK_BLOCK = blk_id_arr[x + (y*row) + ((z+1)*row*col)]
				if LEFT_BLOCK != Air: set_cell_item(v3 + Vector3.LEFT, LEFT_BLOCK)
				if DOWN_BLOCK != Air: set_cell_item(v3 + Vector3.DOWN, DOWN_BLOCK)
				if FORWARD_BLOCK != Air: set_cell_item(v3 + Vector3.FORWARD, FORWARD_BLOCK)
				if RIGHT_BLOCK != Air: set_cell_item(v3 + Vector3.RIGHT, RIGHT_BLOCK)
				if UP_BLOCK != Air: set_cell_item(v3 + Vector3.UP, UP_BLOCK)
				if BACK_BLOCK != Air: set_cell_item(v3 + Vector3.BACK, BACK_BLOCK)

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

	return (Time.get_ticks_usec() - set_cell_time) / 1000.0

func unit_test() -> void:
	var start: float = Time.get_ticks_usec()
	if err_dbg >= UnitTest.Brute_force:
		for x in range(-row, row * 2):
			for y in range(-col, col * 2):
				for z in range(-cll, cll * 2):
					destory_block(x, y, z)
	print("unit_test() completed in ", (Time.get_ticks_usec() - start) / 1000.0," ms")

# Non-important function are spaced 1 newline instead of 2.
func cbrt(num: float) -> float: return pow(num, 1.0/3.0)

func minimum(nums: PackedInt64Array) -> int:
	var ret := 2 ** 63 - 1
	for n in nums: ret = mini(ret, n)
	return ret

func destory_block(x: int, y: int, z: int) -> void:
	if minimum([x, y, z]) < 0: return
	if x >= row or y >= col or z >= cll: return # Found the bug by unit_test() and fixed the bug!
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
