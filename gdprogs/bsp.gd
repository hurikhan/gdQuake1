extends Node

var map = Dictionary()
var map_loaded = false
var raw = Raw.new()

func load_map(filename):
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
	# lightmap_t
	# -----------------------------------------------------	
	var lightmap_t = parser_v2.create("lightmap_t")
	lightmap_t.add("lightmap",		parser_v2.T_U8			)
	# mode
	lightmap_t.set_eval_mode(parser_v2.RETURN_UNWRAPPED)
	
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
	
	var _map = Dictionary()
	
	var header = _get_header(data, dheader_t)
	
	_map.header = header
	
	_map.entities = _get_entities(data, header)
	_map.planes = _get_entries(data, header.planes, plane_t)
	_map.miptexs = _get_miptexs(data, header, mipheader_t, miptex_t)
	_map.vertices = _get_entries(data, header.vertices, vertex_t)
	_map.visilist = _get_entries(data, header.visilist, visilist_t)
	_map.nodes = _get_entries(data, header.nodes, node_t)
	_map.texinfos = _get_entries(data, header.texinfo, texinfo_t)
	_map.faces = _get_entries(data, header.faces, face_t)
	_map.lightmaps = _get_entries(data, header.lightmaps, lightmap_t)
	_map.clipnodes = _get_entries(data, header.clipnodes, clipnode_t)
	_map.leaves = _get_entries(data, header.leaves, dleaf_t)
	_map.lfaces = _get_entries(data, header.lfaces, lface_t)
	_map.edges = _get_entries(data, header.edges, edge_t)
	_map.ledges = _get_entries(data, header.ledges, ledge_t)
	_map.models = _get_entries(data, header.models, model_t)
	
	_map.filename = filename
	_map.valid = true

	map = _map
	map_loaded = true

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
	var entities = Array()
	var s : String = raw.get_string(data, header.entities.offset, header.entities.size)
	var entries = s.split("{")
	
	for e in entries:
		var sub_e = e.split("\n")
		
		#print(sub_e)
		
		var entity = Dictionary()
		
		for i in sub_e:
			
			if i == "}":
				break
			
			if i.begins_with("\""):
				var name_end = i.find("\"", 1)
				var name = i.substr(1, name_end-1)
				
				var value = i.substr(name_end + 3, len(i) - name_end - 4 ) 
				
				entity[name] = value
		
		if len(entity) != 0:
			entities.push_back(entity)
	
	return entities



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

# ----------------------------------------------------------------------

func _get_triangles(polygon, normal, texinfo, miptex):
	
	var ret = Dictionary()
	var v = PoolVector3Array()
	var n = PoolVector3Array()
	var st = PoolVector3Array()
	
	while(polygon.size() >= 3):
		
		for i in range(3):
			
			v.push_back(polygon[i])
			n.push_back(normal)
			
			var s = texinfo.vectorS.dot(polygon[i]) + texinfo.distS 
			var t = texinfo.vectorT.dot(polygon[i]) + texinfo.distT
			s /= miptex.width
			t /= miptex.height
			st.push_back( Vector3( s, t, 1.0 ))
		
		polygon.remove(1)
			
	ret.vertices = v
	ret.normals = n
	ret.st = st
	
	return ret



func _get_bbox(polygon, normal):
	for vec in polygon:
		var st = vec.dot(normal)


func _get_node(map, model_index):
	var model = map.models[model_index]
	var faces = map.faces
	var ledges = map.ledges
	var edges = map.edges
	var vertices = map.vertices
	var planes = map.planes
	var texinfos = map.texinfos
	var miptexs= map.miptexs
	var tex = Dictionary()
	var meshes = Dictionary()
	
	for f in range(model.face_id, model.face_id + model.face_num):
	
		var tex_key = faces[f].texinfo_id
	
		var v = PoolVector3Array()
		var n = PoolVector3Array()
		var st = PoolVector3Array()
	
		if not tex.has(tex_key):
			tex[tex_key] = Dictionary()
			tex[tex_key].v = v
			tex[tex_key].n = n
			tex[tex_key].st = st
		else:
			v = tex[tex_key].v
			n = tex[tex_key].n
			st = tex[tex_key].st
	
		var normal = planes[faces[f].plane_id].normal
							
		var polygon = PoolVector3Array()
		
		for e in range(faces[f].ledge_id, faces[f].ledge_id + faces[f].ledge_num):
			if ledges[e] > 0:
				polygon.push_back(vertices[edges[ledges[e]].vertex0])
			else:
				polygon.push_back(vertices[edges[-ledges[e]].vertex1])
		
		if faces[f].side == 1:
			normal = normal * -1
		
		var texinfo = texinfos[faces[f].texinfo_id]
		var miptex = miptexs[texinfo.texture_id]
		var triangles = _get_triangles(polygon, normal, texinfo, miptex)
		v.append_array(triangles.vertices)
		n.append_array(triangles.normals)
		st.append_array(triangles.st)
		
		tex[tex_key].v = v
		tex[tex_key].n = n
		tex[tex_key].st = st
	
	var t_index = 0
	
	for t in tex:
	
		# Create mesh
		var array = Array()
		array.resize(9)
		array[Mesh.ARRAY_VERTEX] = tex[t].v
		array[Mesh.ARRAY_NORMAL] = tex[t].n
		array[Mesh.ARRAY_TEX_UV] = tex[t].st
	
		var mesh = ArrayMesh.new()
		mesh.set_name("Tex_MeshInstance_" + str(t_index))
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array)
		
		var raw_tex = miptexs[texinfos[t].texture_id].raw_tex1
		var w = miptexs[texinfos[t].texture_id].width
		var h = miptexs[texinfos[t].texture_id].height
		var mat_tex = _get_tex(map, texinfos[t].texture_id)
		var mat = SpatialMaterial.new()
		mat.set_texture(0, mat_tex)
		
		mesh.surface_set_material(0, mat)
		
		meshes[t] = mesh
		
		t_index += 1
	
	var origin = Spatial.new()
	
	for m in meshes:
		var mi = MeshInstance.new()
		mi.set_mesh(meshes[m])
		origin.add_child(mi)
		mi.set_owner(origin)
	
	return origin



func _get_tex(map, index):
	var data = map.miptexs[index].raw_tex1
	var w = map.miptexs[index].width
	var h = map.miptexs[index].height
	
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


func _ready():
	console.register_command("map", {
		node = self,
		description = "Loads a bsp map.",
		args = "<Filename>",
		num_args = 1
	})
	console.register_command("map_info", {
		node = self,
		description = "Info about bsp entries.",
		args = "<entry>",
		num_args = 1
	})
#	console.register_command("bsp_entity_list", {
#		node = self,
#		description = "Lists the entities with the specified classname",
#		args = "<Classname>",
#		num_args = 1
#	})
#	console.register_command("bsp_entity_show", {
#		node = self,
#		description = "Shows the entities with the specified classname",
#		args = "<Classname>",
#		num_args = 1
#	})


func _confunc_map(args):
	load_map("maps/%s" % args[1])
	console.con_print_ok("maps/%s loaded." % args[1])


func _confunc_map_info(args):
	if map_loaded:
		if args[1] == "entities":
			for e in map.entities:
				console.con_print(e)
	else:
		console.con_print_warn("No map loaded!")


#func _load_icon(name, caption = "Caption!", text = ""):
#	var scene = preload("res://gfx/icons/Icon.tscn").instance()
#	scene.set_rotation_degrees(Vector3(90,0,0))
#
#	scene.get_node("Viewport/IconText/Caption").set_text(caption)
#	scene.get_node("Viewport/IconText/Text").set_text(text)
#
#	return scene


#func _confunc_bsp_entity_list(args):
#
#	var num = 0
#
#	for i in thread_map.entities:
#		if args[1] != "":
#			if i["classname"] == args[1]:
#				console.con_print(str(num) + ":" + str(i))
#		else:
#			console.con_print(str(num) + ":" + str(i))
#
#		num += 1


#func _confunc_bsp_entity_show(args):
#
#	var icons_node = $"/root/world/icons"
#	var index_num = 0
#	var light_num = 0
#
#	for i in thread_map.entities:
#
#		if i["classname"] == args[1]:
#			if i["classname"] == "light":
#
#				var xyz = i["origin"].split(" ")
#				var x = float(xyz[0])
#				var y = float(xyz[1])
#				var z = float(xyz[2])
#				var origin = Vector3(x, y, z)
#
#				var icon = _load_icon("sun", "[" + str(index_num) + "] light" + str(light_num))
#				icon.set_translation(origin)
#				icons_node.add_child(icon)
#
#				var light = OmniLight.new()
#				light.set_translation(origin)
#				light.omni_range = 1000
#				light.light_energy = 3
#				icons_node.add_child(light)
#
#				light_num += 1
#
#		index_num += 1
