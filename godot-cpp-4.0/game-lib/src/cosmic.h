#ifndef COSMIC_CLASS_H
#define COSMIC_CLASS_H

#include <godot_cpp/classes/object.hpp>

using namespace godot;

class Cosmic : public Object {
	GDCLASS(Cosmic, Object);

private:
	// There's no way to get variables without a function.
	// prefix "static" to allocate it until Godot is closed.
	uint64_t rng_seed;

protected:
	static void _bind_methods();

public:
	Cosmic();
	~Cosmic();

	int clamp(int value, int min, int max);
	uint64_t rng64(int bit_size);
};

#endif // COSMIC_CLASS_H
