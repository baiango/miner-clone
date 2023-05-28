using Godot;

class Meshes // OOP
{
	BoxMesh box = new BoxMesh();
	Rid[] boxes;
}

public partial class gencs : Node3D
{
	public override void _Ready()
	{
		GD.Print("Hello", " 1", " 2");
		Rid instance = RenderingServer.InstanceCreate();
		// var scenario := get_world_3d().get_scenario()
		World3D scenario = GetWorld3d().GetScenario(); // It won't compile for whatever reason
	}

	private void _on_tree_exiting()
	{
	//	RenderingServer.FreeRid(box.GetRid());
	}
}
