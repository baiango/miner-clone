#ifndef COSMIC_CLASS_H
#define COSMIC_CLASS_H

#include <godot_cpp/classes/object.hpp>

using namespace godot;

class Cosmic : public Object
{	GDCLASS(Cosmic, Object);

private:
	// There's no way to get variables without a function.
	// prefix "static" to allocate it until Godot is closed.
	uint64_t rng_seed;

protected:
	static void _bind_methods();

public:
	Cosmic();
	~Cosmic();

	uint64_t clamp(uint64_t value, uint64_t min, uint64_t max);
	uint64_t rng64(int bit_size);
	Array rng_array(int size, int bit_size);
	Array arr3d(int x, int y, int z); };

#endif // COSMIC_CLASS_H
