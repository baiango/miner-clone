@tool
extends GridMap

var Define = preload("map_gen_define.gd").new()
var Test_unit = preload("map_gen_test.gd").new()


func _regeneratef(dimension: Vector3i) -> void:
	clear()

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
						blk_id = Define.Stone
					elif y >= (rnd_deep & 3) + 1:
						blk_id = Define.Dirt
					elif y >= 0:
						blk_id = Define.Grass

				# The bitwise NOT operator "~" will filp numbers's sign
				# and then subtracts 1 or plus 1 depending on the sign.
				set_cell_item(Vector3i(x, ~y, z), blk_id)

	if Define.dbg >= Define.PerformanceInfo.Time:
		var block_sum := dimension.x * dimension.y * dimension.z
		print_debug("_regenerate_with_array Bps: ", floor(block_sum / ((Time.get_ticks_usec() - start) / 1_000_000.0)), " blocks/s")


func reset():
	if hash(get_used_cells()) != 167173250:
		_regeneratef(Vector3i(32, 32, 4))
	elif Define.dbg == Define.PerformanceInfo.Info:
		print_debug("Current Gridmap hash is 167173250. Skipped regenerating.")


# To keep performace in check.
# It should be over 262144 or 64 cubed (64x64x64) blocks per second on i5-9300H.
	# _regeneratef Bps: 481138 blocks/s
	# _regenerate_with_array Bps: 357299 blocks/s
func benchmark():
	clear()

	var start := Time.get_ticks_usec()

	var dimension := Vector3i(128, 64, 128)
#	dimension = Vector3i(32, 32, 4) # default dimension
	var block_sum := dimension.x * dimension.y * dimension.z
	
	_regeneratef(dimension)
	Test_unit._regenerate_with_array(dimension)


func _ready(): # "Scene -> Reload Saved Scene" to see the changes!
	var dimension := Vector3i(32, 32, 4)

	if not Engine.is_editor_hint():
		pass
#		benchmark()

	print_debug("Current Gridmap hash ", hash(get_used_cells()))
	if hash(get_used_cells()) != 167173250:
		_regeneratef(dimension)
		print_debug("Regenerated Gridmap hash ", hash(get_used_cells()))
