/* raw.cpp */

#include "raw.h"

uint8_t Raw::get_u8(PoolVector<uint8_t> data, size_t offset) {
	return data[offset];
}

uint16_t Raw::get_u16(PoolVector<uint8_t> data, size_t offset) {
	DU du;

	du.byte[0] = data[offset];
	du.byte[1] = data[offset + 1];

	return du.u16;
}

uint32_t Raw::get_u32(PoolVector<uint8_t> data, size_t offset) {
	DU du;

	du.byte[0] = data[offset];
	du.byte[1] = data[offset + 1];
	du.byte[2] = data[offset + 2];
	du.byte[3] = data[offset + 3];

	return du.u32;
}

int8_t Raw::get_i8(PoolVector<uint8_t> data, size_t offset) {
	DU du;

	du.byte[0] = data[offset];

	return du.i8;
}

int16_t Raw::get_i16(PoolVector<uint8_t> data, size_t offset) {
	DU du;

	du.byte[0] = data[offset];
	du.byte[1] = data[offset + 1];

	return du.u16;
}

int32_t Raw::get_i32(PoolVector<uint8_t> data, size_t offset) {
	DU du;

	du.byte[0] = data[offset];
	du.byte[1] = data[offset + 1];
	du.byte[2] = data[offset + 2];
	du.byte[3] = data[offset + 3];

	return du.u32;
}

float Raw::get_f32(PoolVector<uint8_t> data, size_t offset) {
	DU du;

	du.byte[0] = data[offset];
	du.byte[1] = data[offset + 1];
	du.byte[2] = data[offset + 2];
	du.byte[3] = data[offset + 3];

	return float(du.f32);
}

float Raw::get_f64(PoolVector<uint8_t> data, size_t offset) {
	DU du;

	du.byte[0] = data[offset];
	du.byte[1] = data[offset + 1];
	du.byte[2] = data[offset + 2];
	du.byte[3] = data[offset + 3];
	du.byte[4] = data[offset + 4];
	du.byte[5] = data[offset + 5];
	du.byte[6] = data[offset + 6];
	du.byte[7] = data[offset + 7];

	return float(du.f64);
}

Vector3 Raw::get_vec(PoolVector<uint8_t> data, size_t offset) {

	float_t x, y, z;

	x = get_f32(data, offset + 0);
	y = get_f32(data, offset + 4);
	z = get_f32(data, offset + 8);

	Vector3 v;

	v.x = x;
	v.y = y;
	v.z = z;

	return v;
}

String Raw::get_string(PoolVector<uint8_t> data, size_t offset, size_t max) {

	char *cstr = (char*) memalloc(max+1);	

	for(size_t i=0; i < max; i++) {
		cstr[i] = data[offset+i];
		if (data[offset+i] == 0)
			break;
	}

	if (cstr[max-2] != 0)
		cstr[max-1] = 0;

	String s = String(cstr);	

	memfree(cstr);

	return s;
}

void Raw::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_u8", "data", "offset"), &Raw::get_u8);
	ClassDB::bind_method(D_METHOD("get_u16", "data", "offset"), &Raw::get_u16);
	ClassDB::bind_method(D_METHOD("get_u32", "data", "offset"), &Raw::get_u32);

	ClassDB::bind_method(D_METHOD("get_i8", "data", "offset"), &Raw::get_i8);
	ClassDB::bind_method(D_METHOD("get_i16", "data", "offset"), &Raw::get_i16);
	ClassDB::bind_method(D_METHOD("get_i32", "data", "offset"), &Raw::get_i32);

	ClassDB::bind_method(D_METHOD("get_f32", "data", "offset"), &Raw::get_f32);
	ClassDB::bind_method(D_METHOD("get_f64", "data", "offset"), &Raw::get_f64);

	ClassDB::bind_method(D_METHOD("get_vec", "data", "offset"), &Raw::get_vec);
	ClassDB::bind_method(D_METHOD("get_string", "data", "offset", "max"), &Raw::get_string);
}

Raw *Raw::singleton = NULL;

Raw::Raw() {
	singleton = this;
}
