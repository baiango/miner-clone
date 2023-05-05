@tool
extends GridMap


enum { Dirt, Grass, Stone, Void_grass, Crystal_blue }
func regenerate():
	clear()

	var dimension = Vector3i(32, 32, 4)

	var noi = FastNoiseLite.new()
	noi.set_frequency(0.03)

	var rng = RandomNumberGenerator.new()
	rng.set_seed(1023)
	# since modulo "%" use "a-(a//b)*b" which is slow. I use bitwise and "&".
	# bitwise and "&" only work for numbers that are in power of 2 minus 1. (2**n - 1)
	for x in range(-dimension.x, dimension.x):
		for y in dimension.y:
			for z in dimension.z:
				var val = noi.get_noise_3d(x, y, z)
				var rnd_deep = rng.randi()

				var blk_id = -1
				if val > -0.3:
					if y >= (rnd_deep & 3) + 5:
						blk_id = Stone
					elif y >= (rnd_deep & 1) + 1:
						blk_id = Dirt
					elif y >= 0:
						blk_id = Grass

				set_cell_item(Vector3i(x, -1 - y, z), blk_id)


func _ready(): # "Scene -> Reload Saved Scene" to see the changes!
	regenerate()
