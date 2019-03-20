extends Node

enum {T_U8, T_U16, T_U32, T_I8, T_I16, T_I32, T_F32, T_VEC3, T_STRING }
enum {RETURN_AS_DICT, RETURN_AS_ARRAY, RETURN_UNWRAPPED}


var parsers = Dictionary()


func create(name):
	var p = Parser_v3.new()
	p.name = name
	parsers[name] = p
	return p
	

class Parser_v3:
	var name = ""
	var entries = Array()
	var current_entries = Dictionary()
	var current_offset = 0
	var eval_mode = RETURN_AS_DICT
	var aux_mod = Aux.new()
	
	
	func set_eval_mode(mode):
		self.eval_mode = mode


	func eval(fd, start=0):
		
		#var fd = File.new()
		#fd.open(filename, File.READ)
		
		self.current_offset = 0
		
		self.current_entries = Dictionary()
		
		for i in self.entries:
			self.current_entries[i.desc] = _eval_entry(fd, i.type, start, i.count)
		
		
		match self.eval_mode:
			RETURN_AS_DICT:
				return self.current_entries
			RETURN_AS_ARRAY:
				return self.current_entries.values()
			RETURN_UNWRAPPED:
				return self.current_entries.values()[0]
		
		fd.close()


	func _eval_entry(fd, type, start, count=1):

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
				var value = _eval_entry(fd, type, start)
				arr.push_back(value)
				
			return arr
		
		# -------------------------------------------
		# Load basic type
		# -------------------------------------------
		if typeof(type) == TYPE_STRING:
			var v = parser_v3.parsers[type].eval(fd, start + self.current_offset) #FIXME: access sub-instance?
			self.current_offset += parser_v3.parsers[type].get_size()
			return v
		else:
			match type:
				T_U8:
					var ret = get_u8(fd, start + self.current_offset)
					self.current_offset += get_type_size(T_U8)
					return ret
				T_U16:
					var ret = get_u16(fd, start + self.current_offset)
					self.current_offset += get_type_size(T_U16)
					return ret
				T_U32:
					var ret = get_u32(fd, start + self.current_offset)
					self.current_offset += get_type_size(T_U32)
					return ret
				T_I8:
					var ret = get_i8(fd, start + self.current_offset)
					self.current_offset += get_type_size(T_I8)
					return ret
				T_I16:
					var ret = get_i16(fd, start + self.current_offset)
					self.current_offset += get_type_size(T_I16)
					return ret
				T_I32:
					var ret = get_i32(fd, start + self.current_offset)
					self.current_offset += get_type_size(T_I32)
					return ret
				T_F32:
					var ret = get_f32(fd, start + self.current_offset)
					self.current_offset += get_type_size(T_F32)
					return ret
				T_VEC3:
					var ret = get_vec(fd, start + self.current_offset)
					self.current_offset += get_type_size(T_VEC3)
					return ret
				T_STRING:
					var ret = get_string(fd, start + self.current_offset, count)
					self.current_offset += count
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
			T_U8:
				return 1
			T_U16:
				return 2
			T_U32:
				return 4
			T_I8:
				return 1
			T_I16:
				return 2
			T_I32:
				return 4
			T_F32:
				return 4
			T_VEC3:
				return 12
	
	
	func get_u8(fd, offset):
		fd.seek(offset)
		var v = fd.get_8()
		if v < 0:
			v = v + 0x100
		return v
	
	
	func get_u16(fd, offset):
		fd.seek(offset)
		var v = fd.get_16()
		if v < 0:
			v = v + 0x10000
		return v
	
	
	func get_u32(fd, offset):
		fd.seek(offset)
		var v = fd.get_32()
		if v < 0:
			v = v + 0x10000_0000
		return v
	
	
	func get_vec(fd, offset):
		var v = Vector3()
		fd.seek(offset)
		v.x = fd.get_float()
		v.y = fd.get_float()
		v.z = fd.get_float()
		return v
	
	
	func get_i8(fd, offset):
		fd.seek(offset)
		return fd.get_8()
		
		
	func get_i16(fd, offset):
		fd.seek(offset)
		return fd.get_16()
	
	
	func get_i32(fd, offset):
		fd.seek(offset)
		return fd.get_32()
	
	
	func get_f32(fd, offset):
		fd.seek(offset)
		return fd.get_float()
	
	
	func get_string(fd, offset, _max):
		var s = ""
		var c = 0
		
		fd.seek(offset)
		var data = fd.get_buffer(_max)
		
		for i in range(0, _max):
			c = data[offset+i]
			if c == 0:
				return s
			else:
				s += char(c)
		
		return s