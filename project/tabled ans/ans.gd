@tool
extends GridMap

enum PerformanceInfo { None, Time, Info, Verbose }
var dbg := PerformanceInfo.None

enum { Dirt, Grass, Stone, Void_grass, Crystal_blue }


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
	_regenerate(Vector3i(64, 64, 64))


func prt_perf_stat(func_name: String, clean_time: float, regenerating_time: float, bps: int) -> void:
	var bps_cubed = snappedf(cbrt(bps), 0.1)
	var bps_cb_str = "".join(["(", "x".join([bps_cubed, bps_cubed, bps_cubed]), ")"])
	
	print(func_name, " stats:\n\t",
			"Clean up time: ", clean_time, " ms\n\t",
			"Regenerating time: ", regenerating_time, " ms or ", bps, bps_cb_str, " blocks/s")


"""
_regenerate() stats:
	Clean up time: 0.224 ms
	Regenerating time: 316.456 ms or 828371(93.9x93.9x93.9) blocks/s
"""
func _regenerate(dimension: Vector3i) -> void:
	var clean_time := clean()

	var start := Time.get_ticks_usec()

	var noi = FastNoiseLite.new()
	noi.set_frequency(0.03)

	var rng = RandomNumberGenerator.new()
	rng.set_seed(1023)

	var blk_id_arr := []
	blk_id_arr.resize(dimension.x)
	for x in dimension.x:
		blk_id_arr[x] = []
		blk_id_arr[x].resize(dimension.y)
		for y in dimension.y:
			blk_id_arr[x][y] = []
			blk_id_arr[x][y].resize(dimension.z)

	for x in dimension.x:
		for y in dimension.y:
			for z in dimension.z:
				var val = noi.get_noise_3d(x, y, z)
				var rnd_deep := rng.randi()

				var blk_id := -1
				if val > -0.3:
					if y >= (rnd_deep & 1) + 5:
						blk_id = Stone
					elif y >= (rnd_deep & 1) + 1:
						blk_id = Dirt
					elif y >= 0:
						blk_id = Grass
				blk_id_arr[x][y][z] = blk_id

	for x in dimension.x:
		for y in dimension.y:
			for z in dimension.z:
				set_cell_item(Vector3i(x, ~y, z), blk_id_arr[x][y][z])


	if dbg >= PerformanceInfo.Time:
		var block_sum := dimension.x * dimension.y * dimension.z
		var regenerating_time := (Time.get_ticks_usec() - start) / 1000.0
		var bps := floori(block_sum / ((Time.get_ticks_usec() - start) / 1_000_000.0))
		prt_perf_stat("_regenerate()", clean_time, regenerating_time, bps)


func _ready() -> void: # "Scene -> Reload Saved Scene" to see the changes!
	return
	reset()


func _on_tree_exiting():
	clear()
