extends Node


func create(name, debug_level=0):
	var p = Parser.new()
	p.name = name
	p.debug_level = debug_level
	
	return p


func destroy(p):
	pass



class Parser:
	var name
	var debug_level
	var e = Array()
	var d = Dictionary()
	
	var aux = Aux.new()
	
	enum {T_STRING, T_U32, T_VEC3, T_F32}
		
	
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
	
	
	
	func add(desc, type, offset, length=0):
		
		var d = Dictionary()
		d.desc = desc
		d.type = type
		d.offset = offset
		d.length = length
		
		e.append(d)
	
	
	func eval(data):
		for i in e:
			match i.type:
				T_STRING:
					var v = _get_string(data, i.offset, i.length)
					print(i.desc, " -- ", v )
					d[i.desc] = v
				
				T_U32:
					var v = _get_u32(data, i.offset)
					print(i.desc, " -- ", v )
					d[i.desc] = v
				
				T_VEC3:
					var v = _get_vec(data, i.offset)
					print(i.desc, " -- ", v )
					d[i.desc] = v
				
				T_F32:
					var v = _get_f32(data, i.offset)
					print(i.desc, " -- ", v )
					d[i.desc] = v					
	


func _ready():
	
	var mdl = File.new()
	mdl.open("user://data/progs/armor.mdl", mdl.READ)
	var data = mdl.get_buffer(mdl.get_len())
	
	
	var pa = create("hallo")
	
	pa.add("id",			pa.T_STRING,	0,	4	)
	pa.add("version",		pa.T_U32,		4		)
	pa.add("scale",			pa.T_VEC3,		8		)
	pa.add("origin",		pa.T_VEC3,		20		)
	pa.add("radius",		pa.T_F32,		32		)
	pa.add("eye_position",	pa.T_VEC3,		36		)
	pa.add("num_skins",		pa.T_U32,		52		)	
	pa.add("skin_width",	pa.T_U32,		56		)
	pa.add("skin_height",	pa.T_U32,		60		)	
	pa.add("num_tris",		pa.T_U32,		64		)
	pa.add("num_frames",	pa.T_U32,		68		)
	pa.add("synctype",		pa.T_U32,		72		)
	pa.add("flags",			pa.T_U32,		76		)
	pa.add("size",			pa.T_F32,		80		)
	
	print("----------------------------------")
	pa.eval(data)
	print("----------------------------------")
	
	print(pa.d)
	
	