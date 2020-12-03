extends Node

enum {T_VEC3, T_U8, T_U16, T_U32, T_F32, T_STRING, T_I16, T_I32 }
enum {RETURN_AS_DICT, RETURN_AS_ARRAY, RETURN_UNWRAPPED}
enum {NO_OFFSET = -2^63}

var parsers = Dictionary()
var buffer = StreamPeerBuffer.new()
var file = File.new()



func create(name):
	var p = Parser_v3.new()
	p.name = name
	p.this = self
	parsers[name] = p
	return p



func open_file(filename):
	var err = file.open(filename, File.READ)
	buffer.resize(file.get_len())
	buffer.data_array = file.get_buffer(file.get_len())
	buffer.seek(0)



func close_file():
#	buffer.data_array = null
	file.close()



func get_string(offset = NO_OFFSET):
	if offset != NO_OFFSET:
		buffer.seek(offset)
	
	var s : String = ""
		
	for i in range(0,2048):
		
		var u8 = buffer.get_u8()
		
		if u8 == 0:
			break
		else:
			s += char(u8)
	
	return s



func set_offset(offset):
	buffer.seek(offset)



func get_offset():
	return buffer.get_position()



class Parser_v3:
	var name = ""
	var this
	var entries = Array()
	var current_entries = Dictionary()
	var eval_mode = RETURN_AS_DICT
	
	
	func set_eval_mode(mode):
		self.eval_mode = mode
	
	
	func eval(start=-1):
		
		if start != -1:
			this.buffer.seek(start)
		
		self.current_entries = Dictionary()
		
		for i in self.entries:
			self.current_entries[i.desc] = _eval_entry(i.type, i.count)
		
		match self.eval_mode:
			RETURN_AS_DICT:
				return self.current_entries
			RETURN_AS_ARRAY:
				return self.current_entries.values()
			RETURN_UNWRAPPED:
				return self.current_entries.values()[0]
	
	
	func _eval_entry(type, count=1):
	
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
			
			for _i in range(0, count):
				var value = _eval_entry(type)
				arr.push_back(value)
				
			return arr
			
		# -------------------------------------------
		# Load basic type
		# -------------------------------------------
		if typeof(type) == TYPE_STRING:
			var pos = this.buffer.get_position()
			return this.parsers[type].eval(pos)
		else:
			match type:
				T_U32:
					return this.buffer.get_u32()
				T_VEC3:
					var x = this.buffer.get_float()
					var y = this.buffer.get_float()
					var z = this.buffer.get_float()
					return Vector3(x, y, z)
				T_F32:
					return this.buffer.get_float()
				T_U8:
					return this.buffer.get_u8()
				T_U16:
					return this.buffer.get_u16()
				T_STRING:
					return this.buffer.get_string(count)
				T_I16:
					return this.buffer.get_16()
				T_I32:
					return this.buffer.get_32()


	
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
				ret_val += this.parsers[e.type].get_size()
			else:
				if e.type == T_STRING:
					ret_val += e.count
				else:
					ret_val += get_type_size(e.type) * e.count
		
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
