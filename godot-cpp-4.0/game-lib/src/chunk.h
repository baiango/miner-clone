#ifndef CHUNK_CLASS_H
#define CHUNK_CLASS_H

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/classes/box_mesh.hpp>
#include <godot_cpp/classes/node3d.hpp>

using namespace godot;

class ChunkServer : public Object
{	GDCLASS(ChunkServer, Object);

private:
	BoxMesh mesh;

protected:
	static void _bind_methods();

public:
	ChunkServer();
	~ChunkServer();
};

#endif // CHUNK_CLASS_H
