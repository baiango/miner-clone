extends Node3D


func _process(delta: float) -> void:
	var dimension := Glob.dimension
	var radius := dimension / 2
	var pos := (Glob.KIRA as Kira).get_position()
	pos = (pos / 32).floor()
	var chk_pos2 := PackedVector3Array()
	var vertical_chunk := 4
	var horizontal_chunk := 4
	for x in range(
			-vertical_chunk,
			vertical_chunk,
			1
		):
		for y in range(
				-horizontal_chunk,
				horizontal_chunk,
				1
			):
			chk_pos2.append(pos + Vector3.RIGHT * x + Vector3.UP * y)
