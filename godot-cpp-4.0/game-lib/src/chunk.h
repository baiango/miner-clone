#ifndef CHUNK_CLASS_H
#define CHUNK_CLASS_H

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/classes/box_mesh.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include "fast_noise_lite.h"
#include <godot_cpp/variant/variant.hpp>

using namespace godot;

class ChunkServer : public Object
{	GDCLASS(ChunkServer, Object);

private:

protected:
	static void _bind_methods();

public:
	ChunkServer();
	~ChunkServer();

	FastNoiseLite noise;
	PackedFloat32Array generate_chunk(); };

#endif // CHUNK_CLASS_H
