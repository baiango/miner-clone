extends Node


enum { Dirt, Grass, Stone, Void_grass, Crystal_blue, Air=254, Reset=255 }


func _input(_event):
	if Input.is_action_just_pressed("lmb"):
		var ply = $".."
		if not ply.anim_locked:
			$BreakBlock.start()


@onready var hit := $"../Skeleton3D/pipe/pipe/hit"
@onready var hit_miss := $"../Skeleton3D/pipe/pipe/hit/hit_miss"
@onready var chks := get_node(Glob.CHKS)
func _on_break_block_timeout():
	if not chks: return
	var pos := Vector3i(floor(hit.global_position))
	pos += Vector3i(0, chks.dimension.y, 0)

	if chks.get_cell_item(pos) == chks.Air or chks.get_cell_item(pos) == GridMap.INVALID_CELL_ITEM:
		pos.y -= 1
	if chks.get_cell_item(pos) == chks.Air or chks.get_cell_item(pos) == GridMap.INVALID_CELL_ITEM:
		pos.y -= 1
	if chks.get_cell_item(pos) != chks.Air or chks.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM:
		destory_block(pos.x, pos.y, pos.z)
		hit.play()
	else:
		hit_miss.play()

	$BreakPos.position = pos + Vector3i.ONE

# Can't handle multi chunks. Only the first chunk will work.
var row := Glob.DIMENSION.x
var col := Glob.DIMENSION.y
func destory_block(x: int, y: int, z: int) -> void:
	print_debug([x,y,z])
	chks.blk_id_arr[x + (y*row) + (z*row*col)] = Air
	chks.set_cell_item(Vector3i(x, y, z), Air)

	if x-1 > 0: chks.set_cell_item(Vector3i(x, y, z) + Vector3i.LEFT,    chks.blk_id_arr[x-1 + (y*row)     + (z*row*col)])
	if y-1 > 0: chks.set_cell_item(Vector3i(x, y, z) + Vector3i.DOWN,    chks.blk_id_arr[x   + ((y-1)*row) + (z*row*col)])
	if z-1 > 0: chks.set_cell_item(Vector3i(x, y, z) + Vector3i.FORWARD, chks.blk_id_arr[x   + (y*row)     + ((z-1)*row*col)])
	if x+1 < row: chks.set_cell_item(Vector3i(x, y, z) + Vector3i.RIGHT, chks.blk_id_arr[x+1 + (y*row)     + (z*row*col)])
	if y+1 < row: chks.set_cell_item(Vector3i(x, y, z) + Vector3i.UP,    chks.blk_id_arr[x   + ((y+1)*row) + (z*row*col)])
	if z+1 < row: chks.set_cell_item(Vector3i(x, y, z) + Vector3i.BACK,  chks.blk_id_arr[x   + (y*row)     + ((z+1)*row*col)])
