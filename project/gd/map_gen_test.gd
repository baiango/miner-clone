# non-production ready
extends GridMap

var define = preload("map_gen_define.gd").new()


func _regenerate_with_array(dimension: Vector3i) -> void:
	clear()

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
						blk_id_arr[x + dimension.x][y][z] = define.Stone
					elif y >= (rnd_deep & 3) + 1:
						blk_id_arr[x + dimension.x][y][z] = define.Dirt
					elif y >= 0:
						blk_id_arr[x + dimension.x][y][z] = define.Grass
				else:
					blk_id_arr[x + dimension.x][y][z] = -1

	for x in range(-dimension.x, dimension.x):
		for y in dimension.y:
			for z in dimension.z:
				set_cell_item(Vector3i(x, ~y, z), blk_id_arr[x + dimension.x][y][z])

	if define.dbg >= define.PerformanceInfo.Time:
		var block_sum := dimension.x * dimension.y * dimension.z
		print_debug("_regenerate_with_array Bps: ", floor(block_sum / ((Time.get_ticks_usec() - start) / 1_000_000.0)), " blocks/s")
