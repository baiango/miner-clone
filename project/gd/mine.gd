extends Node


func _input(_event):
	if Input.is_action_just_pressed("lmb"):
		var ply = $".."
		if not ply.anim_locked:
			$BreakBlock.start()


@onready var hit := $"../Skeleton3D/pipe/pipe/hit"
@onready var blks := Glob.BLKS as GridMap
func _on_break_block_timeout():
	var pos := Vector3i(floor(hit.global_position))
	if blks.get_cell_item(pos) == GridMap.INVALID_CELL_ITEM:
		pos.y -= 1
	if blks.get_cell_item(pos) == GridMap.INVALID_CELL_ITEM:
		pos.y -= 1

	blks.set_cell_item(pos, GridMap.INVALID_CELL_ITEM)
	$BreakPos.position = pos + Vector3i.ONE
