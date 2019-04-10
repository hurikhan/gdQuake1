/* raw.h */

#ifndef RAW_H
#define RAW_H

#include "core/object.h"


class Raw : public Object {
	GDCLASS(Raw, Object);

private:

	union DU {
		uint8_t u8;
		uint16_t u16;
		uint32_t u32;

		int8_t i8;
		int16_t i16;
		int32_t i32;

		float_t f32;
		double_t f64;

		uint8_t byte[8];
	};

protected:
	static Raw *singleton;
	static void _bind_methods();

public:
	static Raw *get_singleton() { return singleton; }

	uint8_t get_u8(PoolVector<uint8_t> data, size_t offset);
	uint16_t get_u16(PoolVector<uint8_t> data, size_t offset);
	uint32_t get_u32(PoolVector<uint8_t> data, size_t offset);

	int8_t get_i8(PoolVector<uint8_t> data, size_t offset);
	int16_t get_i16(PoolVector<uint8_t> data, size_t offset);
	int32_t get_i32(PoolVector<uint8_t> data, size_t offset);

	float get_f32(PoolVector<uint8_t> data, size_t offset);
	float get_f64(PoolVector<uint8_t> data, size_t offset);

	Vector3 get_vec(PoolVector<uint8_t> data, size_t offset);
	String get_string(PoolVector<uint8_t> data, size_t offset, size_t max);

	Raw();
};

#endif
