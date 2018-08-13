extends Node

enum {T_STRING, T_U8, T_U32, T_VEC3, T_F32, T_U8_ARR T_F32_ARR, T_U32_ARR, T_DUMMY}


func create(name, debug_level=0):
	var p = Parser.new()
	p.name = name
	p.debug_level = debug_level
	
	return p


func get_u32(data, offset):
	var ret = 0
	ret += data[offset]
	ret += data[offset+1] * 256
	ret += data[offset+2] * 256 * 256
	ret += data[offset+3] * 256 * 256 * 256
	return ret


class Parser:
	
	var name
	var debug_level
	var e = Array()	
	var aux = Aux.new()
	
	
	func _get_string(data, offset, _max):
		var s = ""
		var c = 0
		
		for i in range(0, _max):
			c = data[offset+i]
			if c == 0:
				return s
			else:
				s += char(c)
		
		return s
	
	
	func _get_u8(data, offset):	
		return data[offset]
	
	
	func _get_u32(data, offset):
		var ret = 0
		ret += data[offset]
		ret += data[offset+1] * 256
		ret += data[offset+2] * 256 * 256
		ret += data[offset+3] * 256 * 256 * 256
		return ret

	
	func _get_vec(data, offset):
		var ret = aux.get_vec(data, offset)
		return ret
	
	
	func _get_f32(data, offset):
		var ret = aux.get_f32(data, offset)
		return ret
	
	
	func _get_u8_arr(data, offset, length):
		if not typeof(length) == TYPE_ARRAY:
			var ret = data.subarray(offset, offset + length - 1)
			return ret
		else:
			var ret = Array()
			for i in range(0, length[0]):
				var start = offset + (i * length[1])
				var end = start + length[1] - 1
				var sub = data.subarray(start, end)
				ret.append(sub)
			return ret
	
	
	func _get_f32_arr(data, offset, length):
		var ret = Array()		
		for i in range(length):
			ret.append(_get_f32(data, offset + i * 4))
		return ret
	
	
	func _get_u32_arr(data, offset, length):
		var ret = Array()		
		for i in range(length):
			ret.append(_get_u32(data, offset + i * 4))
		return ret
	
	
	func _get_dummy():
		return null
	
	
	func _eval_entry(data, type, offset, length):
		match type:
			T_STRING:
				var v = _get_string(data, offset, length)
				return v
				
			T_U8:
				var v = _get_u8(data, offset)
				return v			
						
			T_U32:
				var v = _get_u32(data, offset)
				return v
			
			T_VEC3:
				var v = _get_vec(data, offset)
				return v
			
			T_F32:
				var v = _get_f32(data, offset)
				return v
			
			T_U8_ARR:
				var v = _get_u8_arr(data, offset, length)
				return v

			T_F32_ARR:
				var v = _get_f32_arr(data, offset, length)
				return v

			T_U32_ARR:
				var v = _get_u32_arr(data, offset, length)
				return v
			
			T_DUMMY:
				var v = _get_dummy()
				return v
	
	
	func add(desc, type, offset=0, length=0):
		
		var d = Dictionary()
		d.desc = desc
		d.type = type
		d.offset = offset
		d.length = length
		
		e.append(d)
	
	
	func eval_as_dict(data, start=0):
		
		var d = Dictionary()
		
		for i in e:
			d[i.desc] = _eval_entry(data, i.type, start + i.offset, i.length)
		
		return d
	
	
	func eval_as_array(data, start=0):
		
		var arr = Array()
		
		for i in e:
			arr.append( _eval_entry(data, i.type, start + i.offset, i.length) )
		
		return arr
	
	