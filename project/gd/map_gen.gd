@tool
extends GridMap

enum PerformanceInfo { None, Time, Info, Verbose }
var dbg := PerformanceInfo.Time

enum { Dirt, Grass, Stone, Void_grass, Crystal_blue }


func _regenerate_fast(dimension: Vector3i) -> void:
	var clean_time := clean()

	var start := Time.get_ticks_usec()

	var noi = FastNoiseLite.new()
	noi.set_frequency(0.03)

	var rng = RandomNumberGenerator.new()
	rng.set_seed(1023)

	for x in range(-dimension.x, dimension.x):
		for y in dimension.y:
			for z in dimension.z:
				var val = noi.get_noise_3d(x, y, z)
				var rnd_deep := rng.randi()
				
				# since modulo "%" use "a-(a//b)*b" which is slow. I use bitwise AND "&".
				# bitwise AND "&" only work for numbers that are in power of 2 minus 1. (2**n - 1)
				var blk_id := -1
				if val > -0.3:
					if y >= (rnd_deep & 1) + 5:
						blk_id = Stone
					elif y >= (rnd_deep & 3) + 1:
						blk_id = Dirt
					elif y >= 0:
						blk_id = Grass

				# The bitwise NOT operator "~" will filp numbers's sign
				# and then subtracts 1 or plus 1 depending on the sign.
				set_cell_item(Vector3i(x, ~y, z), blk_id)

	if dbg >= PerformanceInfo.Time:
		var block_sum := dimension.x * dimension.y * dimension.z
		var regenerating_time := (Time.get_ticks_usec() - start) / 1000.0
		var bps := floori(block_sum / ((Time.get_ticks_usec() - start) / 1_000_000.0))
		prt_perf_stat("_regenerate_fast()", clean_time, regenerating_time, bps)


func reset() -> void:
	if get_hash() != 2170478937:
		if dbg >= PerformanceInfo.Info:
			print_debug("Current Gridmap hash is not 2170478937 but ", get_hash(), ".\n\t",
					"Regenerated with _regenerate_fast().")
		_regenerate_fast(Vector3i(32, 32, 4))
	elif dbg >= PerformanceInfo.Info:
		print_debug("Gridmap hash is 2170478937, not regenerating.")


'''
# To keep performace in check.
# It should be over 262144 or 64 cubed (64x64x64) blocks per second on i5-9300H.
_regenerate_fast() stats:
	Clean up time: 0.02 ms
	Regenerating time: 2159.91 ms or 485471 blocks/s
_regenerate_with_array() stats:
	Clean up time: 274.066 ms
	Regenerating time: 2609.08 ms or 401894 blocks/s
'''
func benchmark() -> void:
	clear()

	var dimension := Vector3i(128, 64, 128)
#	dimension = Vector3i(32, 32, 4) # default dimension
	
	_regenerate_fast(dimension)
	_regenerate_with_array(dimension)


# It will hash(empty array) if you put in map_gen_define
func get_hash() -> int:
	var used_cells := self.get_used_cells()
	used_cells.sort()
	return hash(used_cells)


# It will not clean if you put in map_gen_define
func clean() -> float:
	var start := Time.get_ticks_usec()
	clear()
	var end := Time.get_ticks_usec()

	return (end - start) / 1000.0


func prt_perf_stat(func_name: String, clean_time: float, regenerating_time: float, bps: int) -> void:
	print(func_name, " stats:\n\t",
			"Clean up time: ", clean_time, " ms\n\t",
			"Regenerating time: ", regenerating_time, " ms or ", bps, " blocks/s")


func _ready() -> void: # "Scene -> Reload Saved Scene" to see the changes!
	if not Engine.is_editor_hint():
		pass
#		benchmark()

	reset()

# non-production ready
func _regenerate_with_array(dimension: Vector3i) -> void:
	var clean_time := clean()

	var start := Time.get_ticks_usec()

	var noi = FastNoiseLite.new()
	noi.set_frequency(0.03)

	var rng = RandomNumberGenerator.new()
	rng.set_seed(1023)

	var blk_id_arr := []
	blk_id_arr.resize(dimension.x * 2)
	for x in dimension.x * 2:
		blk_id_arr[x] = []
		blk_id_arr[x].resize(dimension.y)
		for y in dimension.y:
			blk_id_arr[x][y] = []
			blk_id_arr[x][y].resize(dimension.z)

	for x in range(-dimension.x, dimension.x):
		for y in dimension.y:
			for z in dimension.z:
				var val = noi.get_noise_3d(x, y, z)
				var rnd_deep := rng.randi()
				
				if val > -0.3:
					if y >= (rnd_deep & 1) + 5:
						blk_id_arr[x + dimension.x][y][z] = Stone
					elif y >= (rnd_deep & 3) + 1:
						blk_id_arr[x + dimension.x][y][z] = Dirt
					elif y >= 0:
						blk_id_arr[x + dimension.x][y][z] = Grass
				else:
					blk_id_arr[x + dimension.x][y][z] = -1

	for x in range(-dimension.x, dimension.x):
		for y in dimension.y:
			for z in dimension.z:
				set_cell_item(Vector3i(x, ~y, z), blk_id_arr[x + dimension.x][y][z])

	if dbg >= PerformanceInfo.Time:
		var block_sum := dimension.x * dimension.y * dimension.z
		var regenerating_time := (Time.get_ticks_usec() - start) / 1000.0
		var bps := floori(block_sum / ((Time.get_ticks_usec() - start) / 1_000_000.0))
		prt_perf_stat("_regenerate_with_array()", clean_time, regenerating_time, bps)
