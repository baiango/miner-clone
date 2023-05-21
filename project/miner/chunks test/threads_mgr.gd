@tool
extends Node3D


func _ready() -> void:
	var start: float = Time.get_ticks_usec()
	# 981.216 ms
#	spawn_chunk(0)
#	spawn_chunk(1)
#	spawn_chunk(2)
#	spawn_chunk(3)
#	return
	# 371.608 ms
	var thd_call := Callable(self, "spawn_chunk")

	var thd_count = 4
	var thd_arr = []
	for t in thd_count:
		thd_arr.append(Thread.new())
		thd_arr[t].start(thd_call.bind(t))

	for t in thd_count:
		thd_arr[t].wait_to_finish()
	print_debug((Time.get_ticks_usec() - start) / 1000.0, " ms")


var chk := preload("res://miner/chunks test/chunk.tscn") as Resource
var chk_pos := PackedVector3Array([
	Vector3(0, -64, 0),
	Vector3(64, -64, 0),
	Vector3(64, -64, 64),
	Vector3(0, -64, 64),
])
func spawn_chunk(ipos: int) -> void:
	add_child(chk.instantiate())
	get_children()[-1].position = chk_pos[ipos]

