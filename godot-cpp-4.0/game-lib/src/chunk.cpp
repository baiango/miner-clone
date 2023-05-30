#include "chunk.h"

using namespace godot;

void ChunkServer::_bind_methods()
{	ClassDB::bind_method(D_METHOD("generate_chunk"), &ChunkServer::generate_chunk); }

ChunkServer::ChunkServer()
{	noise.SetNoiseType(FastNoiseLite::NoiseType_OpenSimplex2); }

ChunkServer::~ChunkServer() {}

PackedFloat32Array ChunkServer::generate_chunk()
{	PackedFloat32Array noiseData;
	noiseData.resize(128 * 128);
	int index = 0;

	for (int y = 0; y < 128; y++)
		for (int x = 0; x < 128; x++)
			noiseData[index++] = noise.GetNoise((float)x, (float)y);

	return noiseData; }
