/* aux.cpp */

#include "aux.h"
#include <cstdint>

float Aux::get_f32(PoolVector<uint8_t> data, int offset) {

	union {
		float f;
		uint8_t b[4];
	} u;

	u.b[0] = data[offset + 0];
	u.b[1] = data[offset + 1];
	u.b[2] = data[offset + 2];
	u.b[3] = data[offset + 3];


	return u.f;
}

Vector3 Aux::get_vec(PoolVector<uint8_t> data, int offset) {

	float x,y,z;

	x = get_f32(data, offset + 0);
	y = get_f32(data, offset + 4);
	z = get_f32(data, offset + 8);

	Vector3 v;

	v.x = x;
	v.y = y;
	v.z = z;

	return v;
}

void Aux::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_f32", "data", "offset"), &Aux::get_f32);
	ClassDB::bind_method(D_METHOD("get_vec", "data", "offset"), &Aux::get_vec);
}

Aux::Aux() {
}
