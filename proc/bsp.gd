extends Node


func load_bsp(filename):
	var bsp_file = File.new()
	bsp_file.open("user://data/" + filename, bsp_file.READ)
	var data = bsp_file.get_buffer(bsp_file.get_len())

	# -----------------------------------------------------
	# dentry_t
	# -----------------------------------------------------
	var dentry_t = parser_v2.create("dentry_t")
	dentry_t.add("offset",		parser_v2.T_U32	)
	dentry_t.add("size",		parser_v2.T_U32	)

	# -----------------------------------------------------
	# dheader_t
	# -----------------------------------------------------
	var dheader_t = parser_v2.create("dheader_t")
	dheader_t.add("version",		parser_v2.T_U32	)
	dheader_t.add("entities",		"dentry_t"		)
	dheader_t.add("planes",			"dentry_t"		)
	dheader_t.add("miptex",			"dentry_t"		)
	dheader_t.add("vertices",		"dentry_t"		)
	dheader_t.add("visilist",		"dentry_t"		)
	dheader_t.add("nodes",			"dentry_t"		)
	dheader_t.add("texinfo",		"dentry_t"		)
	dheader_t.add("faces",			"dentry_t"		)
	dheader_t.add("lightmaps",		"dentry_t"		)
	dheader_t.add("clipnodes",		"dentry_t"		)
	dheader_t.add("leaves",			"dentry_t"		)
	dheader_t.add("lfaces",			"dentry_t"		)
	dheader_t.add("edges",			"dentry_t"		)
	dheader_t.add("ledges",			"dentry_t"		)
	dheader_t.add("models",			"dentry_t"		)		
	
		
	# -----------------------------------------------------
	# vertex_t
	# -----------------------------------------------------	
	var vertex_t = parser_v2.create("vertex_t")
	vertex_t.add("vec",		parser_v2.T_VEC3			)
	# mode
	vertex_t.set_eval_mode(parser_v2.RETURN_UNWRAPPED)
	
	# -----------------------------------------------------
	# boundbox_t
	# -----------------------------------------------------
	var boundbox_t = parser_v2.create("boundbox_t")
	boundbox_t.add("min",		parser_v2.T_VEC3	)
	boundbox_t.add("max",		parser_v2.T_VEC3	)

	# -----------------------------------------------------
	# bboxshort_t
	# -----------------------------------------------------
	var bboxshort_t = parser_v2.create("bboxshort_t")
	bboxshort_t.add("min_x",		parser_v2.T_I16	)
	bboxshort_t.add("min_y",		parser_v2.T_I16	)
	bboxshort_t.add("min_z",		parser_v2.T_I16	)
	bboxshort_t.add("max_x",		parser_v2.T_I16	)
	bboxshort_t.add("max_y",		parser_v2.T_I16	)
	bboxshort_t.add("max_z",		parser_v2.T_I16	)

	# -----------------------------------------------------
	# model_t
	# -----------------------------------------------------
	var model_t = parser_v2.create("model_t")
	model_t.add("bound",		"boundbox_t"		)
	model_t.add("origin",		parser_v2.T_VEC3	)
	model_t.add("node_id0",		parser_v2.T_U32		)
	model_t.add("node_id1",		parser_v2.T_U32		)
	model_t.add("node_id2",		parser_v2.T_U32		)
	model_t.add("node_id3",		parser_v2.T_U32		)
	model_t.add("numleafs",		parser_v2.T_U32		)
	model_t.add("face_id",		parser_v2.T_U32		)
	model_t.add("face_num",		parser_v2.T_U32		)

	# -----------------------------------------------------
	# edge_t
	# -----------------------------------------------------
	var edge_t = parser_v2.create("edge_t")
	edge_t.add("vertex0",		parser_v2.T_U16	)
	edge_t.add("vertex1",		parser_v2.T_U16	)

	# -----------------------------------------------------
	# texinfo_t (doc: surface_t)
	# -----------------------------------------------------
	var texinfo_t = parser_v2.create("texinfo_t")
	texinfo_t.add("vectorS",		parser_v2.T_VEC3	)
	texinfo_t.add("distS",			parser_v2.T_F32		)
	texinfo_t.add("vectorT",		parser_v2.T_VEC3	)
	texinfo_t.add("distT",			parser_v2.T_F32		)
	texinfo_t.add("texture_id",		parser_v2.T_U32		)
	texinfo_t.add("animated",		parser_v2.T_U32		)	
	
	# -----------------------------------------------------
	# face_t
	# -----------------------------------------------------
	var face_t = parser_v2.create("face_t")
	face_t.add("plane_id",		parser_v2.T_U16	)
	face_t.add("side",			parser_v2.T_U16	)
	face_t.add("ledge_id",		parser_v2.T_U32	)
	face_t.add("ledge_num",		parser_v2.T_U16	)
	face_t.add("texinfo_id",	parser_v2.T_U16	)
	face_t.add("typelight",		parser_v2.T_U8	)
	face_t.add("baselight",		parser_v2.T_U8	)
	face_t.add("light0",		parser_v2.T_U8	)
	face_t.add("light1",		parser_v2.T_U8	)
	face_t.add("lightmap",		parser_v2.T_U32	)

	# -----------------------------------------------------
	# mipheader_t
	# -----------------------------------------------------
	var mipheader_t = parser_v2.create("mipheader_t")
	mipheader_t.add("numtex",		parser_v2.T_U32					)
	mipheader_t.add("offsets",		parser_v2.T_U32,	"numtex"	)

	# -----------------------------------------------------
	# miptex_t
	# -----------------------------------------------------
	var miptex_t = parser_v2.create("miptex_t")
	miptex_t.add("name",		parser_v2.T_STRING,		16	)
	miptex_t.add("width",		parser_v2.T_U32				)
	miptex_t.add("height",		parser_v2.T_U32				)
	miptex_t.add("offset1",		parser_v2.T_U32				)
	miptex_t.add("offset2",		parser_v2.T_U32				)
	miptex_t.add("offset4",		parser_v2.T_U32				)
	miptex_t.add("offset8",		parser_v2.T_U32				)

	# -----------------------------------------------------
	# node_t
	# -----------------------------------------------------
	var node_t = parser_v2.create("node_t")
	node_t.add("plane_id",		parser_v2.T_U32		)
	node_t.add("front",			parser_v2.T_U16		)
	node_t.add("back",			parser_v2.T_U16		)
	node_t.add("box",			"bboxshort_t"		)
	node_t.add("face_id",		parser_v2.T_U16		)
	node_t.add("face_num",		parser_v2.T_U16		)
	
	# -----------------------------------------------------
	# dleaf_t
	# -----------------------------------------------------
	var dleaf_t = parser_v2.create("dleaf_t")
	dleaf_t.add("type",			parser_v2.T_I32		)
	dleaf_t.add("vislist",		parser_v2.T_I32		)
	dleaf_t.add("bound",		"bboxshort_t"		)
	dleaf_t.add("lface_id",		parser_v2.T_U16		)
	dleaf_t.add("lface_num",	parser_v2.T_U16		)
	dleaf_t.add("sndwater",		parser_v2.T_U8		)
	dleaf_t.add("sndsky",		parser_v2.T_U8		)
	dleaf_t.add("sndslime",		parser_v2.T_U8		)
	dleaf_t.add("sndlava",		parser_v2.T_U8		)
	
	# -----------------------------------------------------
	# lface_t
	# -----------------------------------------------------	
	var lface_t = parser_v2.create("lface_t")
	lface_t.add("lface",		parser_v2.T_U16			)
	# mode
	lface_t.set_eval_mode(parser_v2.RETURN_UNWRAPPED)
	
	# -----------------------------------------------------
	# ledge_t
	# -----------------------------------------------------	
	var ledge_t = parser_v2.create("ledge_t")
	ledge_t.add("ledge",		parser_v2.T_I32			)
	# mode
	ledge_t.set_eval_mode(parser_v2.RETURN_UNWRAPPED)
	
	# -----------------------------------------------------
	# visilist_t
	# -----------------------------------------------------	
	var visilist_t = parser_v2.create("visilist_t")
	visilist_t.add("visilist_t",		parser_v2.T_U8	)
	# mode
	visilist_t.set_eval_mode(parser_v2.RETURN_UNWRAPPED)

	# -----------------------------------------------------
	# plane_t
	# -----------------------------------------------------	
	var plane_t = parser_v2.create("visilist_t")
	plane_t.add("normal",		parser_v2.T_VEC3	)
	plane_t.add("dist",			parser_v2.T_F32		)
	plane_t.add("type",			parser_v2.T_U32		)	

	# -----------------------------------------------------
	# clipnode_t
	# -----------------------------------------------------	
	var clipnode_t = parser_v2.create("clipnode_t")
	clipnode_t.add("planenum",		parser_v2.T_U32		)
	clipnode_t.add("front",			parser_v2.T_I16		)
	clipnode_t.add("back",			parser_v2.T_I16		)	

		
	# -----------------------------------------------------
	# eval 
	# -----------------------------------------------------	

	var bsp = Dictionary()

	var header = _get_header(data, dheader_t)
	
	bsp.header = header
	
	bsp.entities = _get_entities(data, header)
	bsp.planes = _get_entries(data, header.planes, plane_t)		
	bsp.miptexs = _get_miptexs(data, header, mipheader_t, miptex_t)	
	bsp.vertices = _get_entries(data, header.vertices, vertex_t)
	bsp.visilist = _get_entries(data, header.visilist, visilist_t)	
	bsp.nodes = _get_entries(data, header.nodes, node_t)	
	bsp.texinfos = _get_entries(data, header.texinfo, texinfo_t)
	bsp.faces = _get_entries(data, header.faces, face_t)
	# lightmaps
	bsp.clipnodes = _get_entries(data, header.clipnodes, clipnode_t)	
	bsp.leaves = _get_entries(data, header.leaves, dleaf_t)
	bsp.lfaces = _get_entries(data, header.lfaces, lface_t)	
	bsp.edges = _get_entries(data, header.edges, edge_t)		
	bsp.ledges = _get_entries(data, header.ledges, ledge_t)	
	bsp.models = _get_entries(data, header.models, model_t)

	return bsp



func _get_header(data, struct):
	var header = struct.eval(data, 0)
	for i in header:
		print(i, " ",header[i])
	return header


func _get_entries(data, dir, struct):
	var arr = Array()
	var struct_size = struct.get_size()
	
	if dir.size != 0:
		for i in range(0, dir.size / struct_size):
			var e = struct.eval(data, dir.offset + i * struct_size)
			arr.push_back(e)

	return arr


func _get_entities(data, header):
	return aux.get_string(data, header.entities.offset, header.entities.size)


func _get_miptexs(data, header, mipheader_t, miptex_t):
	var mipheader = mipheader_t.eval(data, header.miptex.offset)
	
	var miptexs = Array()
	
	for i in range(0, mipheader.numtex):
		var miptex = miptex_t.eval(data, header.miptex.offset + mipheader.offsets[i] )
		miptexs.push_back(miptex)
	
	for i in range(0, miptexs.size()):
		var start = header.miptex.offset + mipheader.offsets[i] + miptexs[i].offset1
		var end = start + miptexs[i].width * miptexs[i].height
		miptexs[i].raw_tex1 = data.subarray(start, end-1)
	
	return miptexs


func _ready():
	#load_bsp("maps/start.bsp")
	#load_bsp("maps/b_bh25.bsp")
	pass
	
