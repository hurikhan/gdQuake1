/* aux.h */

#ifndef AUX_H
#define AUX_H

#include "reference.h"

class Aux : public Reference {
	GDCLASS(Aux, Reference);

protected:
	static void _bind_methods();

public:
	float get_f32(PoolVector<uint8_t> data, int offset);
	Vector3 get_vec(PoolVector<uint8_t> data, int offset);

	Aux();
};

#endif
