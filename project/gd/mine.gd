extends Node


func _input(_event):
	if Input.is_action_just_pressed("lmb"):
		var ply = $".."
		if not ply.anim_locked:
			$BreakBlock.start()


@onready var hit := $"../Skeleton3D/pipe/pipe/hit"
@onready var hit_miss := $"../Skeleton3D/pipe/pipe/hit/hit_miss"
@onready var blks := get_node(Glob.BLKS) as GridMap
func _on_break_block_timeout():
	var pos := Vector3i(floor(hit.global_position))
	pos += Vector3i(0, blks.dimension.y, 0)

	if blks.get_cell_item(pos) == blks.Air or blks.get_cell_item(pos) == GridMap.INVALID_CELL_ITEM:
		pos.y -= 1
	if blks.get_cell_item(pos) == blks.Air or blks.get_cell_item(pos) == GridMap.INVALID_CELL_ITEM:
		pos.y -= 1
	if blks.get_cell_item(pos) != blks.Air or blks.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM:
		blks.destory_block(pos.x, pos.y, pos.z)
		hit.play()
	else:
		hit_miss.play()

	$BreakPos.position = pos + Vector3i.ONE
