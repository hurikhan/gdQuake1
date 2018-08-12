extends Node

func load_mdl(filename):
	
	var mdl = Dictionary()
	
	var mdl_file = File.new()
	mdl_file.open("user://data/" + filename, mdl_file.READ)
	var data = mdl_file.get_buffer(mdl_file.get_len())
	
	# ---------------------------------------------------
	# Header
	# ---------------------------------------------------
	
	var header = parser.create("header")
	
	header.add("id",			parser.T_STRING,	0,	4	)
	header.add("version",		parser.T_U32,		4		)
	header.add("scale",			parser.T_VEC3,		8		)
	header.add("origin",		parser.T_VEC3,		20		)
	header.add("radius",		parser.T_F32,		32		)
	header.add("eye_position",	parser.T_VEC3,		36		)
	header.add("num_skins",		parser.T_U32,		48		)	
	header.add("skin_width",	parser.T_U32,		52		)
	header.add("skin_height",	parser.T_U32,		56		)	
	header.add("num_verts",		parser.T_U32,		60		)
	header.add("num_tris",		parser.T_U32,		64		)
	header.add("num_frames",	parser.T_U32,		68		)
	header.add("synctype",		parser.T_U32,		72		)
	header.add("flags",			parser.T_U32,		76		)
	header.add("size",			parser.T_F32,		80		)

	mdl.header = header.eval_as_dict(data)
	
	# ---------------------------------------------------
	# skins
	# ---------------------------------------------------	

	var offset = 84
	var skin_size = mdl.header.skin_width * mdl.header.skin_height
	var skins = Array()
	
	var skin_single = parser.create("skin_single")
	skin_single.add("group",	parser.T_U32,		0				)
	skin_single.add("skin",		parser.T_U8_ARR,	4,	skin_size	)

	for i in range(0, mdl.header.num_skins):		
		var group = parser.get_u32(data, offset)
		
		match group:
			0:
				print(i, " -- single")			
				skins.append( skin_single.eval_as_array(data, offset) )			
				offset = offset + 4 + skin_size
			
			_:
				print(i, " -- groupskin -- untested!!!")
				var nb = parser.get_u32(data, offset + 4)
				var skin_group  = parser.create("skin_group")
				skin_group.add("group",		parser.T_U32,		0							)
				skin_group.add("nb",		parser.T_U32,		4							)
				skin_group.add("time",		parser.T_F32_ARR,	8,			nb				)
				skin_group.add("skin",		parser.T_U8_ARR,	8 + nb*4,	[nb,skin_size]	)
				skins.append( skin_group.eval_as_array(data, offset) )
				
				offset = offset + 8 + nb * 4 + nb * skin_size

	mdl.skins = skins
	
	print(mdl)
			




	

	