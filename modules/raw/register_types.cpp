/* register_types.cpp */

#include "raw.h"
#include "register_types.h"
#include "core/class_db.h"

void register_raw_types() {
	ClassDB::register_class<Raw>();
}

void unregister_raw_types() {
}

