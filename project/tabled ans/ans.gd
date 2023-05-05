@tool
extends GridMap

enum PerformanceInfo { None, Time, Info, Verbose }
var dbg := PerformanceInfo.Time

enum { Dirt, Grass, Stone, Void_grass, Crystal_blue }


"""
_regenerate_fast() stats:
	Clean up time: 26.132 ms
	Regenerating time: 258.449 ms or 1014292(100.5x100.5x100.5) blocks/s
"""
func _regenerate_fast(dimension: Vector3i) -> void:
	var clean_time := clean()

	var start := Time.get_ticks_usec()

	var noi = FastNoiseLite.new()
	noi.set_frequency(0.03)

	var rng = RandomNumberGenerator.new()
	rng.set_seed(1023)

	for x in dimension.x:
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
		_regenerate_fast(Vector3i(64, 64, 64))
	elif dbg >= PerformanceInfo.Info:
		print_debug("Gridmap hash is 2170478937, not regenerating.")


func get_hash() -> int:
	var used_cells := get_used_cells()
	used_cells.sort()
	return hash(used_cells)


func clean() -> float:
	var start := Time.get_ticks_usec()
	clear()
	var end := Time.get_ticks_usec()

	return (end - start) / 1000.0


func prt_perf_stat(func_name: String, clean_time: float, regenerating_time: float, bps: int) -> void:
	var bps_cubed = snappedf(cbrt(bps), 0.1)
	var bps_cb_str = "".join(["(", "x".join([bps_cubed, bps_cubed, bps_cubed]), ")"])
	
	print(func_name, " stats:\n\t",
			"Clean up time: ", clean_time, " ms\n\t",
			"Regenerating time: ", regenerating_time, " ms or ", bps, bps_cb_str, " blocks/s")


func cbrt(num: float) -> float: return pow(num, 1.0/3.0)


func _ready() -> void: # "Scene -> Reload Saved Scene" to see the changes!
	reset()


func _on_tree_exiting():
	clear()
