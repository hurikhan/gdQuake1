extends Node

var precalc_normals = Array()


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
	skin_t.add("raw_tex",	parser.T_U8_ARR,	4,	skin_size	)

	for i in range(0, mdl.header.num_skins):		
		var group = parser.get_u32(data, offset)
		
		match group:
			0:
				skins.append( skin_t.eval_as_dict(data, offset) )			
				offset = offset + 4 + skin_size
			
			_:
				var nb = parser.get_u32(data, offset + 4)
				var skingroup_t  = parser.create("skin_group")
				skingroup_t.add("group",	parser.T_U32,		0							)
				skingroup_t.add("nb",		parser.T_U32,		4							)
				skingroup_t.add("times",	parser.T_F32_ARR,	8,			nb				)
				skingroup_t.add("raw_texs",	parser.T_U8_ARR,	8 + nb*4,	[nb,skin_size]	)
				skins.append( skingroup_t.eval_as_dict(data, offset) )
				
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
		stverts.append( stvert_t.eval_as_dict(data, offset) )
		offset = offset + 12
	
	mdl.stverts = stverts
	
	# ---------------------------------------------------
	# itriangles -- Alias Model Triangles
	# ---------------------------------------------------	
	
	var itriangles = Array()
	
	var itriangle_t = parser.create("itriangle")
	itriangle_t.add("facesfront",	parser.T_U32,		0		)
	itriangle_t.add("vertices",		parser.T_U32_ARR,	4,	3	)
	
	for i in range(0, mdl.header.num_tris):
		itriangles.append( itriangle_t.eval_as_dict(data, offset) )
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
			frame_type_single_t.add("group",	parser.T_U32,		0	)	# Value = 0
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
			trivertx_t.add("packedpositions",	parser.T_U8_ARR,	0,	3	)	# X,Y,Z coordinate, packed on 0-255
			trivertx_t.add("lightnormalindex",	parser.T_U8,		3		)	# index of the vertex normal

			# ---------------------------------------------------
			# logic -- single frame
			# ---------------------------------------------------	

			var frame_type_single = frame_type_single_t.eval_as_dict(data, offset)
			offset += 4
			
			var simpleframe = simpleframe_t.eval_as_dict(data, offset)
							
			var bbox_min = trivertx_t.eval_as_dict(data, offset)
			offset += 4
			
			var bbox_max = trivertx_t.eval_as_dict(data, offset)
			offset += 4 + 16 # +16 name[16]
					
			var vertices = Array()
			for k in range(0, mdl.header.num_verts):
				vertices.append( trivertx_t.eval_as_dict(data, offset) )
				offset += 4
							
			simpleframe.min = bbox_min
			simpleframe.max = bbox_max
			simpleframe.vertices = vertices
			
			frame_type_single.frame = simpleframe
			
			frames.append( frame_type_single )
				
		# ---------------------------------------------------
		# eval frame_type != 0 (group frame)
		# ---------------------------------------------------	
		
		else:

			# ---------------------------------------------------
			# frame_type_group -- Alias Model Frames
			# ---------------------------------------------------
					
			var frame_type_group_t = parser.create("frame_type_group")
			frame_type_group_t.add("group",		parser.T_U32,		0							)	# Value != 0
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
			trivertx_t.add("packedpositions",	parser.T_U8_ARR,	0,	3	)	# X,Y,Z coordinate, packed on 0-255
			trivertx_t.add("lightnormalindex",	parser.T_U8,		3		)	# index of the vertex normal

			# ---------------------------------------------------
			# logic -- group frame
			# ---------------------------------------------------				

			var frame_type_group = frame_type_group_t.eval_as_dict(data, offset)
			var number_of_frames = frame_type_group.nb
			offset += 8

			var group_bbox_min = trivertx_t.eval_as_dict(data, offset)
			offset += 4
			
			var group_bbox_max = trivertx_t.eval_as_dict(data, offset)
			offset += 4
			
			# Times[nb]
			
			var times_t = parser.create("times_t")
			times_t.add("times",	parser.T_F32_ARR,	0,	number_of_frames)
			var times = times_t.eval_as_array(data, offset)
			offset = offset + number_of_frames * 4		
					
			# Simple_frames[nb]
			
			var simpleframes = Array()
			
			for k in range(0, number_of_frames):
			
				var simpleframe = simpleframe_t.eval_as_dict(data, offset)
								
				var bbox_min = trivertx_t.eval_as_dict(data, offset)
				offset += 4
				
				var bbox_max = trivertx_t.eval_as_dict(data, offset)
				offset += 4 + 16 # +16 name[16]
						
				var vertices = Array()
				for j in range(0, mdl.header.num_verts):
					vertices.append( trivertx_t.eval_as_dict(data, offset) )
					offset += 4
								
				simpleframe.min = bbox_min
				simpleframe.max = bbox_max
				simpleframe.vertices = vertices
				
				simpleframes.append(simpleframe)
			
			# reassemble
			frame_type_group.min = group_bbox_min
			frame_type_group.max = group_bbox_max
			frame_type_group.times = times
			frame_type_group.frames = simpleframes
					
			frames.append( frame_type_group )
			
	mdl.frames = frames
	
	return mdl


func get_skin(mdl, index):
	var skin = mdl.skins[index]
	var w = mdl.header.skin_width
	var h = mdl.header.skin_height
	var group = skin.group
	
	if group == 0:
		var data = skin.raw_tex
		
		var image = Image.new()
		image.create(w, h, false, Image.FORMAT_RGB8)
		image.lock()
		
		for x in range(0,w):
			for y in range(0,h):
				image.set_pixel(x,y, pallete.color[data[x+y*w]])
		
		image.unlock()		
		var tex = ImageTexture.new()
		tex.create_from_image(image)
		
		return tex		
	else:
		var groupskin = Dictionary()	
		groupskin.type = "groupskin"
		groupskin.nb = skin.nb
		groupskin.times = skin.times
		
		var texs = Array()
		
		for i in range(0,groupskin.nb):
			var data = skin.raw_texs[i]
			
			var image = Image.new()
			image.create(w, h, false, Image.FORMAT_RGB8)
			image.lock()
			
			for x in range(0,w):
				for y in range(0,h):
					image.set_pixel(x,y, pallete.color[data[x+y*w]])
			
			image.unlock()		
			var tex = ImageTexture.new()
			tex.create_from_image(image)
			texs.push_back(tex)
		
		groupskin.texs = texs
		return groupskin
		
		

func get_mesh(mdl):
	
	var vertices = Array()
	var normals = Array()
	var uvs = Array()
	var onseam = Array()
	var gd_vertices = PoolVector3Array()
	var gd_normals = PoolVector3Array()
	var gd_uvs = PoolVector3Array()
		
	# Skin	
	var skin = get_skin(mdl, 0)
	
	# UVs
	var s = 0
	var t = 0
	var w = float(mdl.header.skin_width)
	var h = float(mdl.header.skin_height)
	
	for uv in mdl.stverts:
		onseam.push_back( uv.onseam )
		s = float( uv.s ) /w
		t = float( uv.t ) /h
		uvs.push_back(Vector3(s,t,0.0))
	
	
	# Verticex
	# Normals	
	var scale = mdl.header.scale
	var origin = mdl.header.origin
	var raw_vecs = null
	
	if mdl.frames[0].group == 0:
		raw_vecs = mdl.frames[0].frame.vertices
	else:
		raw_vecs = mdl.frames[0].frames[0].vertices
		
	for raw_vec in raw_vecs:
		var x = float(raw_vec.packedpositions[0])
		var y = float(raw_vec.packedpositions[1])
		var z = float(raw_vec.packedpositions[2])	
		var v = Vector3(x,y,z) * scale + origin	
		vertices.push_back(v)
		normals.push_back(precalc_normals[ raw_vec.lightnormalindex ] )
		
	
	# Tris
	var a = 0
	var b = 0
	var c = 0
	
	for triangle in mdl.itriangles:
		
		a = triangle.vertices[0]
		b = triangle.vertices[1]
		c = triangle.vertices[2]		
			
		gd_vertices.push_back(vertices[a])
		gd_vertices.push_back(vertices[b])
		gd_vertices.push_back(vertices[c])
		gd_normals.push_back(normals[a])
		gd_normals.push_back(normals[b])
		gd_normals.push_back(normals[c])			
		
		if triangle.facesfront == 0:
			if onseam[a] == 0x20:
				if uvs[a].x <= 0.5:
					uvs[a].x += 0.5
			if onseam[b] == 0x20:
				if uvs[b].x <= 0.5:
					uvs[b].x += 0.5
			if onseam[c] == 0x20:
				if uvs[c].x <= 0.5:
					uvs[c].x += 0.5					
		else:
			if onseam[a] == 0x20:
				if uvs[a].x >= 0.5:
					uvs[a].x -= 0.5
			if onseam[b] == 0x20:
				if uvs[b].x >= 0.5:
					uvs[b].x -= 0.5
			if onseam[c] == 0x20:
				if uvs[c].x >= 0.5:
					uvs[c].x -= 0.5			
		
		gd_uvs.push_back(uvs[a])
		gd_uvs.push_back(uvs[b])
		gd_uvs.push_back(uvs[c])
	
			
	var array = Array()
	array.resize(9)
	array[Mesh.ARRAY_VERTEX] = gd_vertices
	array[Mesh.ARRAY_NORMAL] = gd_normals
	array[Mesh.ARRAY_TEX_UV] = gd_uvs
		
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array)
	
	var mat = SpatialMaterial.new()
	mat.set_texture(0, skin)
	
	mesh.surface_set_material(0, mat)

	return mesh


func _ready():
	init_precalc_normals()

	
func init_precalc_normals():
	precalc_normals.push_back(Vector3(-0.525731, 0.000000, 0.850651))
	precalc_normals.push_back(Vector3(-0.442863, 0.238856, 0.864188))
	precalc_normals.push_back(Vector3(-0.295242, 0.000000, 0.955423))
	precalc_normals.push_back(Vector3(-0.309017, 0.500000, 0.809017))
	precalc_normals.push_back(Vector3(-0.162460, 0.262866, 0.951056))
	precalc_normals.push_back(Vector3(0.000000, 0.000000, 1.000000))
	precalc_normals.push_back(Vector3(0.000000, 0.850651, 0.525731))
	precalc_normals.push_back(Vector3(-0.147621, 0.716567, 0.681718))
	precalc_normals.push_back(Vector3(0.147621, 0.716567, 0.681718))
	precalc_normals.push_back(Vector3(0.000000, 0.525731, 0.850651))
	precalc_normals.push_back(Vector3(0.309017, 0.500000, 0.809017))
	precalc_normals.push_back(Vector3(0.525731, 0.000000, 0.850651))
	precalc_normals.push_back(Vector3(0.295242, 0.000000, 0.955423))
	precalc_normals.push_back(Vector3(0.442863, 0.238856, 0.864188))
	precalc_normals.push_back(Vector3(0.162460, 0.262866, 0.951056))
	precalc_normals.push_back(Vector3(-0.681718, 0.147621, 0.716567))
	precalc_normals.push_back(Vector3(-0.809017, 0.309017, 0.500000))
	precalc_normals.push_back(Vector3(-0.587785, 0.425325, 0.688191))
	precalc_normals.push_back(Vector3(-0.850651, 0.525731, 0.000000))
	precalc_normals.push_back(Vector3(-0.864188, 0.442863, 0.238856))
	precalc_normals.push_back(Vector3(-0.716567, 0.681718, 0.147621))
	precalc_normals.push_back(Vector3(-0.688191, 0.587785, 0.425325))
	precalc_normals.push_back(Vector3(-0.500000, 0.809017, 0.309017))
	precalc_normals.push_back(Vector3(-0.238856, 0.864188, 0.442863))
	precalc_normals.push_back(Vector3(-0.425325, 0.688191, 0.587785))
	precalc_normals.push_back(Vector3(-0.716567, 0.681718, -0.147621))
	precalc_normals.push_back(Vector3(-0.500000, 0.809017, -0.309017))
	precalc_normals.push_back(Vector3(-0.525731, 0.850651, 0.000000))
	precalc_normals.push_back(Vector3(0.000000, 0.850651, -0.525731))
	precalc_normals.push_back(Vector3(-0.238856, 0.864188, -0.442863))
	precalc_normals.push_back(Vector3(0.000000, 0.955423, -0.295242))
	precalc_normals.push_back(Vector3(-0.262866, 0.951056, -0.162460))
	precalc_normals.push_back(Vector3(0.000000, 1.000000, 0.000000))
	precalc_normals.push_back(Vector3(0.000000, 0.955423, 0.295242))
	precalc_normals.push_back(Vector3(-0.262866, 0.951056, 0.162460))
	precalc_normals.push_back(Vector3(0.238856, 0.864188, 0.442863))
	precalc_normals.push_back(Vector3(0.262866, 0.951056, 0.162460))
	precalc_normals.push_back(Vector3(0.500000, 0.809017, 0.309017))
	precalc_normals.push_back(Vector3(0.238856, 0.864188, -0.442863))
	precalc_normals.push_back(Vector3(0.262866, 0.951056, -0.162460))
	precalc_normals.push_back(Vector3(0.500000, 0.809017, -0.309017))
	precalc_normals.push_back(Vector3(0.850651, 0.525731, 0.000000))
	precalc_normals.push_back(Vector3(0.716567, 0.681718, 0.147621))
	precalc_normals.push_back(Vector3(0.716567, 0.681718, -0.147621))
	precalc_normals.push_back(Vector3(0.525731, 0.850651, 0.000000))
	precalc_normals.push_back(Vector3(0.425325, 0.688191, 0.587785))
	precalc_normals.push_back(Vector3(0.864188, 0.442863, 0.238856))
	precalc_normals.push_back(Vector3(0.688191, 0.587785, 0.425325))
	precalc_normals.push_back(Vector3(0.809017, 0.309017, 0.500000))
	precalc_normals.push_back(Vector3(0.681718, 0.147621, 0.716567))
	precalc_normals.push_back(Vector3(0.587785, 0.425325, 0.688191))
	precalc_normals.push_back(Vector3(0.955423, 0.295242, 0.000000))
	precalc_normals.push_back(Vector3(1.000000, 0.000000, 0.000000))
	precalc_normals.push_back(Vector3(0.951056, 0.162460, 0.262866))
	precalc_normals.push_back(Vector3(0.850651, -0.525731, 0.000000))
	precalc_normals.push_back(Vector3(0.955423, -0.295242, 0.000000))
	precalc_normals.push_back(Vector3(0.864188, -0.442863, 0.238856))
	precalc_normals.push_back(Vector3(0.951056, -0.162460, 0.262866))
	precalc_normals.push_back(Vector3(0.809017, -0.309017, 0.500000))
	precalc_normals.push_back(Vector3(0.681718, -0.147621, 0.716567))
	precalc_normals.push_back(Vector3(0.850651, 0.000000, 0.525731))
	precalc_normals.push_back(Vector3(0.864188, 0.442863, -0.238856))
	precalc_normals.push_back(Vector3(0.809017, 0.309017, -0.500000))
	precalc_normals.push_back(Vector3(0.951056, 0.162460, -0.262866))
	precalc_normals.push_back(Vector3(0.525731, 0.000000, -0.850651))
	precalc_normals.push_back(Vector3(0.681718, 0.147621, -0.716567))
	precalc_normals.push_back(Vector3(0.681718, -0.147621, -0.716567))
	precalc_normals.push_back(Vector3(0.850651, 0.000000, -0.525731))
	precalc_normals.push_back(Vector3(0.809017, -0.309017, -0.500000))
	precalc_normals.push_back(Vector3(0.864188, -0.442863, -0.238856))
	precalc_normals.push_back(Vector3(0.951056, -0.162460, -0.262866))
	precalc_normals.push_back(Vector3(0.147621, 0.716567, -0.681718))
	precalc_normals.push_back(Vector3(0.309017, 0.500000, -0.809017))
	precalc_normals.push_back(Vector3(0.425325, 0.688191, -0.587785))
	precalc_normals.push_back(Vector3(0.442863, 0.238856, -0.864188))
	precalc_normals.push_back(Vector3(0.587785, 0.425325, -0.688191))
	precalc_normals.push_back(Vector3(0.688191, 0.587785, -0.425325))
	precalc_normals.push_back(Vector3(-0.147621, 0.716567, -0.681718))
	precalc_normals.push_back(Vector3(-0.309017, 0.500000, -0.809017))
	precalc_normals.push_back(Vector3(0.000000, 0.525731, -0.850651))
	precalc_normals.push_back(Vector3(-0.525731, 0.000000, -0.850651))
	precalc_normals.push_back(Vector3(-0.442863, 0.238856, -0.864188))
	precalc_normals.push_back(Vector3(-0.295242, 0.000000, -0.955423))
	precalc_normals.push_back(Vector3(-0.162460, 0.262866, -0.951056))
	precalc_normals.push_back(Vector3(0.000000, 0.000000, -1.000000))
	precalc_normals.push_back(Vector3(0.295242, 0.000000, -0.955423))
	precalc_normals.push_back(Vector3(0.162460, 0.262866, -0.951056))
	precalc_normals.push_back(Vector3(-0.442863, -0.238856, -0.864188))
	precalc_normals.push_back(Vector3(-0.309017, -0.500000, -0.809017))
	precalc_normals.push_back(Vector3(-0.162460, -0.262866, -0.951056))
	precalc_normals.push_back(Vector3(0.000000, -0.850651, -0.525731))
	precalc_normals.push_back(Vector3(-0.147621, -0.716567, -0.681718))
	precalc_normals.push_back(Vector3(0.147621, -0.716567, -0.681718))
	precalc_normals.push_back(Vector3(0.000000, -0.525731, -0.850651))
	precalc_normals.push_back(Vector3(0.309017, -0.500000, -0.809017))
	precalc_normals.push_back(Vector3(0.442863, -0.238856, -0.864188))
	precalc_normals.push_back(Vector3(0.162460, -0.262866, -0.951056))
	precalc_normals.push_back(Vector3(0.238856, -0.864188, -0.442863))
	precalc_normals.push_back(Vector3(0.500000, -0.809017, -0.309017))
	precalc_normals.push_back(Vector3(0.425325, -0.688191, -0.587785))
	precalc_normals.push_back(Vector3(0.716567, -0.681718, -0.147621))
	precalc_normals.push_back(Vector3(0.688191, -0.587785, -0.425325))
	precalc_normals.push_back(Vector3(0.587785, -0.425325, -0.688191))
	precalc_normals.push_back(Vector3(0.000000, -0.955423, -0.295242))
	precalc_normals.push_back(Vector3(0.000000, -1.000000, 0.000000))
	precalc_normals.push_back(Vector3(0.262866, -0.951056, -0.162460))
	precalc_normals.push_back(Vector3(0.000000, -0.850651, 0.525731))
	precalc_normals.push_back(Vector3(0.000000, -0.955423, 0.295242))
	precalc_normals.push_back(Vector3(0.238856, -0.864188, 0.442863))
	precalc_normals.push_back(Vector3(0.262866, -0.951056, 0.162460))
	precalc_normals.push_back(Vector3(0.500000, -0.809017, 0.309017))
	precalc_normals.push_back(Vector3(0.716567, -0.681718, 0.147621))
	precalc_normals.push_back(Vector3(0.525731, -0.850651, 0.000000))
	precalc_normals.push_back(Vector3(-0.238856, -0.864188, -0.442863))
	precalc_normals.push_back(Vector3(-0.500000, -0.809017, -0.309017))
	precalc_normals.push_back(Vector3(-0.262866, -0.951056, -0.162460))
	precalc_normals.push_back(Vector3(-0.850651, -0.525731, 0.000000))
	precalc_normals.push_back(Vector3(-0.716567, -0.681718, -0.147621))
	precalc_normals.push_back(Vector3(-0.716567, -0.681718, 0.147621))
	precalc_normals.push_back(Vector3(-0.525731, -0.850651, 0.000000))
	precalc_normals.push_back(Vector3(-0.500000, -0.809017, 0.309017))
	precalc_normals.push_back(Vector3(-0.238856, -0.864188, 0.442863))
	precalc_normals.push_back(Vector3(-0.262866, -0.951056, 0.162460))
	precalc_normals.push_back(Vector3(-0.864188, -0.442863, 0.238856))
	precalc_normals.push_back(Vector3(-0.809017, -0.309017, 0.500000))
	precalc_normals.push_back(Vector3(-0.688191, -0.587785, 0.425325))
	precalc_normals.push_back(Vector3(-0.681718, -0.147621, 0.716567))
	precalc_normals.push_back(Vector3(-0.442863, -0.238856, 0.864188))
	precalc_normals.push_back(Vector3(-0.587785, -0.425325, 0.688191))
	precalc_normals.push_back(Vector3(-0.309017, -0.500000, 0.809017))
	precalc_normals.push_back(Vector3(-0.147621, -0.716567, 0.681718))
	precalc_normals.push_back(Vector3(-0.425325, -0.688191, 0.587785))
	precalc_normals.push_back(Vector3(-0.162460, -0.262866, 0.951056))
	precalc_normals.push_back(Vector3(0.442863, -0.238856, 0.864188))
	precalc_normals.push_back(Vector3(0.162460, -0.262866, 0.951056))
	precalc_normals.push_back(Vector3(0.309017, -0.500000, 0.809017))
	precalc_normals.push_back(Vector3(0.147621, -0.716567, 0.681718))
	precalc_normals.push_back(Vector3(0.000000, -0.525731, 0.850651))
	precalc_normals.push_back(Vector3(0.425325, -0.688191, 0.587785))
	precalc_normals.push_back(Vector3(0.587785, -0.425325, 0.688191))
	precalc_normals.push_back(Vector3(0.688191, -0.587785, 0.425325))
	precalc_normals.push_back(Vector3(-0.955423, 0.295242, 0.000000))
	precalc_normals.push_back(Vector3(-0.951056, 0.162460, 0.262866))
	precalc_normals.push_back(Vector3(-1.000000, 0.000000, 0.000000))
	precalc_normals.push_back(Vector3(-0.850651, 0.000000, 0.525731))
	precalc_normals.push_back(Vector3(-0.955423, -0.295242, 0.000000))
	precalc_normals.push_back(Vector3(-0.951056, -0.162460, 0.262866))
	precalc_normals.push_back(Vector3(-0.864188, 0.442863, -0.238856))
	precalc_normals.push_back(Vector3(-0.951056, 0.162460, -0.262866))
	precalc_normals.push_back(Vector3(-0.809017, 0.309017, -0.500000))
	precalc_normals.push_back(Vector3(-0.864188, -0.442863, -0.238856))
	precalc_normals.push_back(Vector3(-0.951056, -0.162460, -0.262866))
	precalc_normals.push_back(Vector3(-0.809017, -0.309017, -0.500000))
	precalc_normals.push_back(Vector3(-0.681718, 0.147621, -0.716567))
	precalc_normals.push_back(Vector3(-0.681718, -0.147621, -0.716567))
	precalc_normals.push_back(Vector3(-0.850651, 0.000000, -0.525731))
	precalc_normals.push_back(Vector3(-0.688191, 0.587785, -0.425325))
	precalc_normals.push_back(Vector3(-0.587785, 0.425325, -0.688191))
	precalc_normals.push_back(Vector3(-0.425325, 0.688191, -0.587785))
	precalc_normals.push_back(Vector3(-0.425325, -0.688191, -0.587785))
	precalc_normals.push_back(Vector3(-0.587785, -0.425325, -0.688191))
	precalc_normals.push_back(Vector3(-0.688191, -0.587785, -0.425325))

	
	print(precalc_normals.size(), " precalculated vertex normals loaded.")
	