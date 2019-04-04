extends Node

enum {T_VEC3, T_U8, T_U16, T_U32, T_F32, T_STRING, T_I16, T_I32 }
enum {RETURN_AS_DICT, RETURN_AS_ARRAY, RETURN_UNWRAPPED}


var parsers = Dictionary()


func create(name):
	var p = Parser_v2.new()
	p.name = name
	parsers[name] = p
	return p
	

class Parser_v2:
	var name = ""
	var entries = Array()
	var current_entries = Dictionary()
	var current_offset = 0
	var eval_mode = RETURN_AS_DICT
	var aux_mod = Aux.new()
	
	
	func set_eval_mode(mode):
		self.eval_mode = mode


	func eval(data, start=0):
		
		self.current_offset = 0
		
		self.current_entries = Dictionary()
		
		for i in self.entries:
			self.current_entries[i.desc] = _eval_entry(data, i.type, start, i.count)
		
		
		match self.eval_mode:
			RETURN_AS_DICT:
				return self.current_entries
			RETURN_AS_ARRAY:
				return self.current_entries.values()
			RETURN_UNWRAPPED:
				return self.current_entries.values()[0]


	func _eval_entry(data, type, start, count=1):

		# ----------------------------------------------------
		# Check if count is an key of the current dictionary
		# ----------------------------------------------------	
		if typeof(count) == TYPE_STRING:
			if self.current_entries.has(count):
				count = self.current_entries[count]
					
		# -------------------------------------------
		# Load array (count != 1)
		# -------------------------------------------						
		if count != 1 and type != T_STRING:
			
			var arr = Array()

			for i in range(0, count):
				var value = _eval_entry(data, type, start)
				arr.push_back(value)
				
			return arr
		
		# -------------------------------------------
		# Load basic type
		# -------------------------------------------
		if typeof(type) == TYPE_STRING:
			var v = parser_v2.parsers[type].eval(data, start + self.current_offset)
			self.current_offset += parser_v2.parsers[type].get_size()
			return v
		else:
			match type:
				T_U32:
					var ret = aux.get_u32(data, start + self.current_offset)
					self.current_offset += get_type_size(T_U32)
					return ret
				T_VEC3:
					var ret = aux_mod.get_vec(data, start + self.current_offset)
					self.current_offset += get_type_size(T_VEC3)
					return ret
				T_F32:
					var ret = aux_mod.get_f32(data, start + self.current_offset)
					self.current_offset += get_type_size(T_F32)
					return ret
				T_U8:
					var ret = aux.get_u8(data, start + self.current_offset)
					self.current_offset += get_type_size(T_U8)
					return ret
				T_U16:
					var ret = aux.get_u16(data, start + self.current_offset)
					self.current_offset += get_type_size(T_U16)
					return ret
				T_STRING:
					var ret = aux.get_string(data, start + self.current_offset, count)
					self.current_offset += count
					return ret
				T_I16:
					var ret = aux.get_i16(data, start + self.current_offset)
					self.current_offset += get_type_size(T_I16)
					return ret
				T_I32:
					var ret = aux.get_i32(data, start + self.current_offset)
					self.current_offset += get_type_size(T_I32)
					return ret


	
	func add(desc, type, count=1):
		
		var d = Dictionary()
		d.desc = desc
		d.type = type
		d.count = count
		
		entries.push_back(d)
	
	
	func get_size():
		var ret_val = 0
		
		for e in self.entries:
			if typeof(e.type) == TYPE_STRING:
				ret_val += parser_v2.parsers[e.type].get_size()
			else:
				if e.type == T_STRING:
					ret_val += e.count
				else:
					ret_val += get_type_size(e.type)
		
		return ret_val
	
	
	func get_type_size(type):
		match type:
			T_VEC3:
				return 12
			T_U8:
				return 1
			T_U16:
				return 2
			T_I16:
				return 2
			T_U32:
				return 4
			T_I32:
				return 4	
			T_F32:
				return 4			
