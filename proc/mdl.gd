extends Node

func load_mdl(filename):
	
	var mdl = Dictionary()
	
	var mdl_file = File.new()
	mdl_file.open("user://data/" + filename, mdl_file.READ)
	var data = mdl_file.get_buffer(mdl_file.get_len())
	
	# ---------------------------------------------------
	# header
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
	# skins -- Alias Model Skins
	# ---------------------------------------------------

	var skinbase = 84
	var offset = skinbase
	var skin_size = mdl.header.skin_width * mdl.header.skin_height
	var skins = Array()
	
	var skin_t = parser.create("skin_t")
	skin_t.add("group",		parser.T_U32,		0				)
	skin_t.add("skin",		parser.T_U8_ARR,	4,	skin_size	)

	for i in range(0, mdl.header.num_skins):		
		var group = parser.get_u32(data, offset)
		
		match group:
			0:
				#print(i, " -- singleskin")			
				skins.append( skin_t.eval_as_array(data, offset) )			
				offset = offset + 4 + skin_size
			
			_:
				print(i, " -- groupskin -- untested!!!")
				var nb = parser.get_u32(data, offset + 4)
				var skingroup_t  = parser.create("skin_group")
				skingroup_t.add("group",	parser.T_U32,		0							)
				skingroup_t.add("nb",		parser.T_U32,		4							)
				skingroup_t.add("time",		parser.T_F32_ARR,	8,			nb				)
				skingroup_t.add("skin",		parser.T_U8_ARR,	8 + nb*4,	[nb,skin_size]	)
				skins.append( skingroup_t.eval_as_array(data, offset) )
				
				offset = offset + 8 + nb * 4 + nb * skin_size

	mdl.skins = skins
	
	# ---------------------------------------------------
	# stverts -- Alias Model Skin Vertices
	# ---------------------------------------------------
		
	var stverts = Array()
			
	var stvert_t = parser.create("stvert")
	stvert_t.add("onseam",		parser.T_U32,	0		)
	stvert_t.add("s",			parser.T_U32,	4		)
	stvert_t.add("t",			parser.T_U32,	8		)
	
	for i in range(0, mdl.header.num_verts):
		stverts.append( stvert_t.eval_as_array(data, offset) )
		offset = offset + 12
	
	mdl.stverts = stverts
	
	# ---------------------------------------------------
	# itriangles -- Alias Model Triangles
	# ---------------------------------------------------	
	
	var itriangles = Array()
	
	var itriangle_t = parser.create("itriangle")
	itriangle_t.add("facesfront",	parser.T_U32,		0		)
	itriangle_t.add("vertices",	parser.T_U32_ARR,	4,	3	)
	
	for i in range(0, mdl.header.num_tris):
		itriangles.append( itriangle_t.eval_as_array(data, offset) )
		offset = offset + 16	
	
	mdl.itriangles = itriangles
	
	
	# ---------------------------------------------------
	# evaluate -- Alias Model Frames
	# ---------------------------------------------------	
	
	var framebase = offset
	var frames = Array()
	
	for i in range(0, mdl.header.num_frames ):
		var frame_type = parser.get_u32(data, offset)

		# ---------------------------------------------------
		# eval frame_type = 0 (single frame)
		# ---------------------------------------------------	
			
		if frame_type == 0:
			
			# ---------------------------------------------------
			# frame_type_single_t -- Alias Model Frames
			# ---------------------------------------------------

			var frame_type_single_t = parser.create("frame_type_single")
			frame_type_single_t.add("type",		parser.T_U32,		0	)	# Value = 0
			frame_type_single_t.add("frame",	parser.T_DUMMY,		4	)	# a single frame definition (simpleframe_t)
		
		
			# ---------------------------------------------------
			# simpleframe_t -- Alias Model Frames
			# ---------------------------------------------------
		
			var simpleframe_t = parser.create("simpleframe_t")
			simpleframe_t.add("min",		parser.T_DUMMY,		0,	4	)	# minimum bbox values of X,Y,Z (trivertx_t)
			simpleframe_t.add("max",		parser.T_DUMMY,		4,	4	)	# maximum bbox values of X,Y,Z (trivertx_t)
			simpleframe_t.add("name",		parser.T_STRING,	8,	16	)	# name of frame
			simpleframe_t.add("vertices",	parser.T_DUMMY				)	# array of vertices (trivertx_t[num_verts])

			# ---------------------------------------------------
			# trivertx_t -- Alias Model Frames
			# ---------------------------------------------------	
			
			var trivertx_t = parser.create("trivertx_t")
			trivertx_t.add("packedposition",	parser.T_U8_ARR,	0,	3	)	# X,Y,Z coordinate, packed on 0-255
			trivertx_t.add("lightnormalindex",	parser.T_U8,		3		)	# index of the vertex normal

			# ---------------------------------------------------
			# logic -- single frame
			# ---------------------------------------------------	

			var frame_type_single = frame_type_single_t.eval_as_array(data, offset)
			offset += 4
			
			var simpleframe = simpleframe_t.eval_as_array(data, offset)
							
			var bbox_min = trivertx_t.eval_as_array(data, offset)
			offset += 4
			
			var bbox_max = trivertx_t.eval_as_array(data, offset)
			offset += 4 + 16 # +16 name[16]
					
			var vertices = Array()
			for k in range(0, mdl.header.num_verts):
				vertices.append( trivertx_t.eval_as_array(data, offset) )
				offset += 4
							
			simpleframe[0] = bbox_min
			simpleframe[1] = bbox_max
			simpleframe[3] = vertices
			
			frame_type_single[1] = simpleframe
			
			frames.append( frame_type_single )
				
		# ---------------------------------------------------
		# eval frame_type != 0 (group frame)
		# ---------------------------------------------------	
		
		else:

			# ---------------------------------------------------
			# frame_type_group -- Alias Model Frames
			# ---------------------------------------------------
					
			var frame_type_group_t = parser.create("frame_type_group")
			frame_type_group_t.add("type",		parser.T_U32,		0							)	# Value != 0
			frame_type_group_t.add("nb",		parser.T_U32,		4							)	# Number of frames
			frame_type_group_t.add("min",		parser.T_DUMMY,		8,	4						)	# min position in all simple frames (trivertx_t)
			frame_type_group_t.add("max",		parser.T_DUMMY,		12,	4						)	# max position in all simple frames
			frame_type_group_t.add("times",		parser.T_DUMMY,		16							)	# array of float
			frame_type_group_t.add("frames",	parser.T_DUMMY									)	# array of simpleframe_t
			
						
			# ---------------------------------------------------
			# simpleframe_t -- Alias Model Frames
			# ---------------------------------------------------
		
			var simpleframe_t = parser.create("simpleframe_t")
			simpleframe_t.add("min",		parser.T_DUMMY,		0,	4	)	# minimum bbox values of X,Y,Z (trivertx_t)
			simpleframe_t.add("max",		parser.T_DUMMY,		4,	4	)	# maximum bbox values of X,Y,Z (trivertx_t)
			simpleframe_t.add("name",		parser.T_STRING,	8,	16	)	# name of frame
			simpleframe_t.add("vertices",	parser.T_DUMMY				)	# array of vertices (trivertx_t[num_verts])

			# ---------------------------------------------------
			# trivertx_t -- Alias Model Frames
			# ---------------------------------------------------	
			
			var trivertx_t = parser.create("trivertx_t")
			trivertx_t.add("packedposition",	parser.T_U8_ARR,	0,	3	)	# X,Y,Z coordinate, packed on 0-255
			trivertx_t.add("lightnormalindex",	parser.T_U8,		3		)	# index of the vertex normal

			# ---------------------------------------------------
			# logic -- group frame
			# ---------------------------------------------------				

			var frame_type_group = frame_type_group_t.eval_as_array(data, offset)
			var number_of_frames = frame_type_group[1]
			offset += 8

			var group_bbox_min = trivertx_t.eval_as_array(data, offset)
			offset += 4
			
			var group_bbox_max = trivertx_t.eval_as_array(data, offset)
			offset += 4
			
			# Times[nb]
			
			var times_t = parser.create("times_t")
			times_t.add("times",	parser.T_F32_ARR,	0,	number_of_frames)
			var times = times_t.eval_as_array(data, offset)
			offset = offset + number_of_frames * 4		
					
			# Simple_frames[nb]
			
			var simpleframes = Array()
			
			for k in range(0, number_of_frames):
			
				var simpleframe = simpleframe_t.eval_as_array(data, offset)
								
				var bbox_min = trivertx_t.eval_as_array(data, offset)
				offset += 4
				
				var bbox_max = trivertx_t.eval_as_array(data, offset)
				offset += 4 + 16 # +16 name[16]
						
				var vertices = Array()
				for j in range(0, mdl.header.num_verts):
					vertices.append( trivertx_t.eval_as_array(data, offset) )
					offset += 4
								
				simpleframe[0] = bbox_min
				simpleframe[1] = bbox_max
				simpleframe[3] = vertices
				
				simpleframes.append(simpleframe)
			
			# reassemble
			frame_type_group[2] = group_bbox_min
			frame_type_group[3] = group_bbox_max
			frame_type_group[4] = times
			frame_type_group[5] = simpleframes
					
			frames.append( frame_type_group )
			
	mdl.frames = frames
	
	return mdl


func get_mesh(mdl):
	#print(mdl.header)
	#print(mdl.frames[0])
	
	var vertices = Array()
	var gd_vertices = Array()
	
	var size = mdl.header.scale
	var origin = mdl.header.origin
	
	for packed_vec in mdl.frames[0][1][3]:
		var x = float(packed_vec[0][0])
		var y = float(packed_vec[0][1])
		var z = float(packed_vec[0][2])	
		var v = Vector3(x,y,z) * mdl.header.scale + mdl.header.origin	
		vertices.push_back(v)
	
	
	var front = 0
	var a = 0
	var b = 0
	var c = 0
	
	for triangle in mdl.itriangles:
		
		front = triangle[0]
		
		if front == 0:
			a = triangle[1][0]
			b = triangle[1][1]
			c = triangle[1][2]
		else:
			a = triangle[1][0]
			b = triangle[1][1]
			c = triangle[1][2]
			
		gd_vertices.push_back(vertices[a])
		gd_vertices.push_back(vertices[b])
		gd_vertices.push_back(vertices[c])
		
		
	
	
	
	
	

	var array = Array()
	array.resize(9)
	array[Mesh.ARRAY_VERTEX] = gd_vertices
		
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array)
	return mesh
	
	
	

	