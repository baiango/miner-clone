extends Node


func _input(event) -> void:
	if Input.is_action_just_pressed("lmb"):
		if not ($".." as Kira).anim_locked:
			($BreakBlock as Timer).start()


@onready var hit := $"../Skeleton3D/pipe/pipe/hit" as AudioStreamPlayer3D
@onready var hit_miss := $"../Skeleton3D/pipe/pipe/hit/hit_miss" as AudioStreamPlayer3D
@onready var blks := Glob.BLKS as Chunk
func _on_break_block_timeout() -> void:
	var pos := Vector3i(hit.get_global_position().floor())
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

	($BreakPos as Node3D).position = pos + Vector3i.ONE
