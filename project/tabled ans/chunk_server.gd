@tool
class_name gen extends Node3D


var mesh := BoxMesh.new()
var m = Meshes.new() # You must keep the reference.


class Meshes: # OOP
	var mesh := BoxMesh.new()
	var chunks: Array[RID] = []

	func spawn_box(pos: Vector3, world: World3D):
		chunks.append(RenderingServer.instance_create())
		var instance := chunks[-1]
		var scenario := world.scenario
		RenderingServer.instance_set_scenario(instance, scenario)

		RenderingServer.instance_set_base(instance, mesh) # Add mesh

		var xform := Transform3D(Basis(), pos) # Set position
		RenderingServer.instance_set_transform(instance, xform)

	func remove_box(index: int):
		RenderingServer.free_rid(chunks[index])
		chunks.remove_at(index)

	func get_box_rid(index: int) -> RID: return chunks[index] # More type-safe than directly access it

	func clear() -> void:
		for r in chunks:
			RenderingServer.free_rid(r)


func _ready() -> void:
	var instance := RenderingServer.instance_create()
	var scenario := get_world_3d().scenario
	RenderingServer.instance_set_scenario(instance, scenario)
	
	# Add mesh
	RenderingServer.instance_set_base(instance, mesh)
	# Move
	var xform := Transform3D(Basis(), Vector3(0, 0, -2))
	RenderingServer.instance_set_transform(instance, xform)

	m.spawn_box(Vector3(0, 0, -6), get_world_3d())
	m.spawn_box(Vector3(0, 0, -4), get_world_3d())
	m.spawn_box(Vector3(0, 0, -3), get_world_3d())
	print(m.get_box_rid(1))
	m.remove_box(1)
	print(m.get_box_rid(1)) # Not gonna be same as last one
	m.remove_box(1)


	var arr_mesh := ArrayMesh.new()
	var face_arr := []
	var face_index := []
	var face_uv := []

func _on_tree_exiting():
	RenderingServer.free_rid(mesh)
	m.clear()
