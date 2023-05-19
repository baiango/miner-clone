#include "cosmic.h"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void Cosmic::_bind_methods()
{	ClassDB::bind_method(D_METHOD("rng64", "bit_size"), &Cosmic::rng64, DEFVAL(64)); }

Cosmic::Cosmic()
{	rng_seed = 1023; }

Cosmic::~Cosmic() {}


/* https://github.com/numpy/numpy/issues/16313#issuecomment-640008156
32 bits
0xff37f1f758180525
0xda942042e4dd58b5
https://github.com/vigna/CPRNG
https://onlinelibrary.wiley.com/doi/10.1002/spe.3030
15 bits
0x72ed
16 bits
0xd9f5
0xecc5
32 bits
0xfffeb28d
0xcffef595
0xef912f85
0x89f353b5
0x915f77f5
0x93d765dd
0xf9b25d65
0xe817fb2d
63 bits
0x7e91d554f7f50a65
64 bits
0xd1342543de82ef95
0xf1357aea2e62a9c5
0xfc0072fa0b15f4fd
0xdefba91144f2b375
128 bits
0xdb36357734e34abb0050d0761fcdfc15
0xaadec8c3186345282b4e141f3a1232d5 */
int Cosmic::clamp(int value, int min, int max)
{	if (value < min) return min;
	if (value > max) return max;
	return value; }

uint64_t Cosmic::rng64(int bit_size)
{	Cosmic::clamp(bit_size, 0, 64);
	rng_seed *= 0xdefba91144f2b375;
	return rng_seed >> (64 - bit_size); }
