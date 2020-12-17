extends Node

const CONTENTS_EMPTY 		:= -1
const CONTENTS_SOLID		:= -2
const CONTENTS_WATER		:= -3
const CONTENTS_SLIME		:= -4
const CONTENTS_LAVA			:= -5
const CONTENTS_SKY			:= -6
const CONTENTS_ORIGIN		:= -7
const CONTENTS_CLIP			:= -8

var bsp_meshes = Array()
var bsp_textures = Dictionary()

var map = Dictionary()
var map_loaded = false

var mutex_map_data = Mutex.new()
var mutex_tscn_loading = Mutex.new()
var mutex_tex_loading = Mutex.new()
var mutex_mesh_saving = Mutex.new()

func load_map(filename):
	
	var timer_bsp_parsing = console.con_timer_create()
	
	var dir = Directory.new()
	var path = console.cvars["path_prefix"].value + "cache/" + filename + "/map.res"	
	
	if dir.file_exists(path) and console.cvars["cache"].value == 1:
		var cache_file = File.new()
		cache_file.open(path, File.READ)
		map = cache_file.get_var()
		cache_file.close()
		
	else:
#		var bsp_file = File.new()
#		bsp_file.open(console.cvars["path_prefix"].value + "id1-x/" + filename, bsp_file.READ)
#		var data = bsp_file.get_buffer(bsp_file.get_len())
		
		
		var _filename : String = console.cvars["path_prefix"].value + "id1-x/" + filename
		
		# -----------------------------------------------------
		# dentry_t
		# -----------------------------------------------------
		var dentry_t = parser_v3.create("dentry_t", _filename)
		dentry_t.add("offset",		parser_v3.T_U32	)
		dentry_t.add("size",		parser_v3.T_U32	)
		
		# -----------------------------------------------------
		# dheader_t
		# -----------------------------------------------------
		var dheader_t = parser_v3.create("dheader_t", _filename)
		dheader_t.add("version",		parser_v3.T_U32	)
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
		var vertex_t = parser_v3.create("vertex_t", _filename)
		vertex_t.add("vec",		parser_v3.T_VEC3			)
		# mode
		vertex_t.set_eval_mode(parser_v3.RETURN_UNWRAPPED)
		
		# -----------------------------------------------------
		# boundbox_t
		# -----------------------------------------------------
		var boundbox_t = parser_v3.create("boundbox_t", _filename)
		boundbox_t.add("min",		parser_v3.T_VEC3	)
		boundbox_t.add("max",		parser_v3.T_VEC3	)
		
		# -----------------------------------------------------
		# bboxshort_t
		# -----------------------------------------------------
		var bboxshort_t = parser_v3.create("bboxshort_t", _filename)
		bboxshort_t.add("min_x",		parser_v3.T_I16	)
		bboxshort_t.add("min_y",		parser_v3.T_I16	)
		bboxshort_t.add("min_z",		parser_v3.T_I16	)
		bboxshort_t.add("max_x",		parser_v3.T_I16	)
		bboxshort_t.add("max_y",		parser_v3.T_I16	)
		bboxshort_t.add("max_z",		parser_v3.T_I16	)
		
		# -----------------------------------------------------
		# model_t
		# -----------------------------------------------------
		var model_t = parser_v3.create("model_t", _filename)
		model_t.add("bound",		"boundbox_t"		)
		model_t.add("origin",		parser_v3.T_VEC3	)
		model_t.add("node_id0",		parser_v3.T_U32		)
		model_t.add("node_id1",		parser_v3.T_U32		)
		model_t.add("node_id2",		parser_v3.T_U32		)
		model_t.add("node_id3",		parser_v3.T_U32		)
		model_t.add("numleafs",		parser_v3.T_U32		)
		model_t.add("face_id",		parser_v3.T_U32		)
		model_t.add("face_num",		parser_v3.T_U32		)
		
		# -----------------------------------------------------
		# edge_t
		# -----------------------------------------------------
		var edge_t = parser_v3.create("edge_t", _filename)
		edge_t.add("vertex0",		parser_v3.T_U16	)
		edge_t.add("vertex1",		parser_v3.T_U16	)
		
		# -----------------------------------------------------
		# texinfo_t (doc: surface_t)
		# -----------------------------------------------------
		var texinfo_t = parser_v3.create("texinfo_t", _filename)
		texinfo_t.add("vectorS",		parser_v3.T_VEC3	)
		texinfo_t.add("distS",			parser_v3.T_F32		)
		texinfo_t.add("vectorT",		parser_v3.T_VEC3	)
		texinfo_t.add("distT",			parser_v3.T_F32		)
		texinfo_t.add("texture_id",		parser_v3.T_U32		)
		texinfo_t.add("animated",		parser_v3.T_U32		)
		
		# -----------------------------------------------------
		# face_t
		# -----------------------------------------------------
		var face_t = parser_v3.create("face_t", _filename)
		face_t.add("plane_id",		parser_v3.T_U16	)
		face_t.add("side",			parser_v3.T_U16	)
		face_t.add("ledge_id",		parser_v3.T_U32	)
		face_t.add("ledge_num",		parser_v3.T_U16	)
		face_t.add("texinfo_id",	parser_v3.T_U16	)
		face_t.add("typelight",		parser_v3.T_U8	)
		face_t.add("baselight",		parser_v3.T_U8	)
		face_t.add("light0",		parser_v3.T_U8	)
		face_t.add("light1",		parser_v3.T_U8	)
		face_t.add("lightmap",		parser_v3.T_U32	)
		
		# -----------------------------------------------------
		# mipheader_t
		# -----------------------------------------------------
		var mipheader_t = parser_v3.create("mipheader_t", _filename)
		mipheader_t.add("numtex",		parser_v3.T_U32					)
		mipheader_t.add("offsets",		parser_v3.T_U32,	"numtex"	)
		
		# -----------------------------------------------------
		# miptex_t
		# -----------------------------------------------------
		var miptex_t = parser_v3.create("miptex_t", _filename)
		miptex_t.add("name",		parser_v3.T_STRING,		16	)
		miptex_t.add("width",		parser_v3.T_U32				)
		miptex_t.add("height",		parser_v3.T_U32				)
		miptex_t.add("offset1",		parser_v3.T_U32				)
		miptex_t.add("offset2",		parser_v3.T_U32				)
		miptex_t.add("offset4",		parser_v3.T_U32				)
		miptex_t.add("offset8",		parser_v3.T_U32				)
		
		# -----------------------------------------------------
		# node_t
		# -----------------------------------------------------
		var node_t = parser_v3.create("node_t", _filename)
		node_t.add("plane_id",		parser_v3.T_U32		)
		node_t.add("front",			parser_v3.T_U16		)
		node_t.add("back",			parser_v3.T_U16		)
		node_t.add("box",			"bboxshort_t"		)
		node_t.add("face_id",		parser_v3.T_U16		)
		node_t.add("face_num",		parser_v3.T_U16		)
		
		# -----------------------------------------------------
		# dleaf_t
		# -----------------------------------------------------
		var dleaf_t = parser_v3.create("dleaf_t", _filename)
		dleaf_t.add("type",			parser_v3.T_I32		)
		dleaf_t.add("vislist",		parser_v3.T_I32		)
		dleaf_t.add("bound",		"bboxshort_t"		)
		dleaf_t.add("lface_id",		parser_v3.T_U16		)
		dleaf_t.add("lface_num",	parser_v3.T_U16		)
		dleaf_t.add("sndwater",		parser_v3.T_U8		)
		dleaf_t.add("sndsky",		parser_v3.T_U8		)
		dleaf_t.add("sndslime",		parser_v3.T_U8		)
		dleaf_t.add("sndlava",		parser_v3.T_U8		)
		
		
		# -----------------------------------------------------
		# lface_t
		# -----------------------------------------------------
		var lface_t = parser_v3.create("lface_t", _filename)
		lface_t.add("lface",		parser_v3.T_U16			)
		# mode
		lface_t.set_eval_mode(parser_v3.RETURN_UNWRAPPED)
		
		
		# -----------------------------------------------------
		# lightmap_t
		# -----------------------------------------------------
		var lightmap_t = parser_v3.create("lightmap_t", _filename)
		lightmap_t.add("lightmap",		parser_v3.T_U8			)
		# mode
		lightmap_t.set_eval_mode(parser_v3.RETURN_UNWRAPPED)
		
		# -----------------------------------------------------
		# ledge_t
		# -----------------------------------------------------
		var ledge_t = parser_v3.create("ledge_t", _filename)
		ledge_t.add("ledge",		parser_v3.T_I32			)
		# mode
		ledge_t.set_eval_mode(parser_v3.RETURN_UNWRAPPED)
		
		# -----------------------------------------------------
		# visilist_t
		# -----------------------------------------------------
		var visilist_t = parser_v3.create("visilist_t", _filename)
		visilist_t.add("visilist_t",		parser_v3.T_U8	)
		# mode
		visilist_t.set_eval_mode(parser_v3.RETURN_UNWRAPPED)
		
		# -----------------------------------------------------
		# plane_t
		# -----------------------------------------------------	
		var plane_t = parser_v3.create("plane_t", _filename)
		plane_t.add("normal",		parser_v3.T_VEC3	)
		plane_t.add("dist",			parser_v3.T_F32		)
		plane_t.add("type",			parser_v3.T_U32		)
		
		# -----------------------------------------------------
		# clipnode_t
		# -----------------------------------------------------
		var clipnode_t = parser_v3.create("clipnode_t", _filename)
		clipnode_t.add("planenum",		parser_v3.T_U32		)
		clipnode_t.add("front",			parser_v3.T_I16		)
		clipnode_t.add("back",			parser_v3.T_I16		)
		
		# -----------------------------------------------------
		# eval 
		# -----------------------------------------------------
		
		var _map = Dictionary()
		
		var header = _get_header(dheader_t)
		
		_map.header = header
		
		if console.cvars["mt"].value == 0:
		
			_map.entities = _get_entities(header, _filename)
			_map.planes = _get_entries(header.planes, plane_t)
			_map.miptexs = _get_miptexs(header, mipheader_t, miptex_t)
			_map.vertices = _get_entries(header.vertices, vertex_t)
			_map.visilist = _get_entries(header.visilist, visilist_t)
			_map.nodes = _get_entries(header.nodes, node_t)
			_map.texinfos = _get_entries(header.texinfo, texinfo_t)
			_map.faces = _get_entries(header.faces, face_t)
			_map.lightmaps = _get_lightmap(header.lightmaps, lightmap_t)
			_map.clipnodes = _get_entries(header.clipnodes, clipnode_t)
			_map.leaves = _get_entries(header.leaves, dleaf_t)
			_map.lfaces = _get_entries(header.lfaces, lface_t)
			_map.edges = _get_entries(header.edges, edge_t)
			_map.ledges = _get_entries(header.ledges, ledge_t)
			_map.models = _get_entries(header.models, model_t)
			
			parser_v3.clear()
		else:
		
			#FIXME: check _thread_leaves - does not work in multi threading
			
			var _thread_entities = console.con_thread("entities", self, "_get_entities", [header, _filename]) 
			var _thread_planes = console.con_thread("planes",self,"_get_entries",[header.planes, plane_t])
			var _thread_miptexs = console.con_thread("miptexs",self,"_get_miptexs",[header, mipheader_t, miptex_t])
			var _thread_vertices = console.con_thread("vertices",self,"_get_entries",[header.vertices, vertex_t])
			
			var _thread_visilist = console.con_thread("visilist",self,"_get_entries",[header.visilist, visilist_t])
			var _thread_nodes = console.con_thread("nodes",self,"_get_entries",[header.nodes, node_t])
			var _thread_texinfos = console.con_thread("texinfos",self,"_get_entries",[header.texinfo, texinfo_t])
			var _thread_faces = console.con_thread("faces",self,"_get_entries",[header.faces, face_t])
			
			var _thead_lightmaps = console.con_thread("lightmaps",self,"_get_lightmap",[header.lightmaps, lightmap_t])
			var _thread_clipnodes = console.con_thread("clipnodes",self,"_get_entries",[header.clipnodes, clipnode_t])
#			var _thread_leaves = console.con_thread("leaves",self,"_get_entries",[data, header.leaves, dleaf_t])
			var _thread_lfaces = console.con_thread("lfaces",self,"_get_entries",[header.lfaces, lface_t])
			
			var _thread_edges = console.con_thread("edges",self,"_get_entries",[header.edges, edge_t])
			var _thread_ledges = console.con_thread("ledges",self,"_get_entries",[header.ledges, ledge_t])
			var _thead_models = console.con_thread("models",self,"_get_entries",[header.models, model_t])
			
			_map.entities = console.con_thread_wait(_thread_entities)
			_map.planes = console.con_thread_wait(_thread_planes)
			_map.miptexs = console.con_thread_wait(_thread_miptexs)
			_map.vertices = console.con_thread_wait(_thread_vertices)
			
			_map.visilist = console.con_thread_wait(_thread_visilist)
			_map.nodes = console.con_thread_wait(_thread_nodes)
			_map.texinfos = console.con_thread_wait(_thread_texinfos)
			_map.faces = console.con_thread_wait(_thread_faces)
			
			_map.lightmaps = console.con_thread_wait(_thead_lightmaps)
			_map.clipnodes = console.con_thread_wait(_thread_clipnodes)
#			_map.leaves = console.con_thread_wait(_thread_leaves)
			_map.lfaces = console.con_thread_wait(_thread_lfaces)
			
			_map.edges = console.con_thread_wait(_thread_edges)
			_map.ledges = console.con_thread_wait(_thread_ledges)
			_map.models = console.con_thread_wait(_thead_models)
			
			parser_v3.clear()
		
		_map.filename = filename
		_map.valid = true
		map = _map
		
		if console.cvars["cache"].value == 1:
			var new_file_name = console.cvars["path_prefix"].value + "cache/" + map.filename + "/"
			var dir2 = Directory.new()
			dir2.make_dir_recursive( new_file_name.get_base_dir() )
			
			var file = File.new()
			var err = file.open(new_file_name + "map.res", file.WRITE)
			file.store_var(map, true)
			file.close()
		
	map_loaded = true
	
	timer_bsp_parsing.print("Parsed BSP data in ")
	
	var timer_model_parsing = console.con_timer_create()
	
	if console.cvars["mt"].value == 0 or true:
		# -----------------------------------------------------
		# single thread bsp model loading 
		# -----------------------------------------------------
		for i in range(len(map.models)):
			bsp_meshes.insert(i, _get_model(map, i))
		
	else:
		# -----------------------------------------------------
		# multi thread bsp model loading 
		# -----------------------------------------------------
		var threads = {}
		var models_num : int = len(map.models)
		var steps : int = 4							# FIXME: >1 crashes... 
		
		for i in range(0, models_num):
			threads[i] = console.con_thread("model %d" % [i], self, "_get_model",[map, i])
			
		for i in range(0, models_num):
			bsp_meshes.insert(i, console.con_thread_wait( threads[i] ) )
	
	timer_model_parsing.print("Generated/Loaded Models in ")



func _get_header(struct):
	var header = struct.eval(0)
	for i in header:
		print(i, " ",header[i])
	return header



func _get_entries(dir, struct):
	var arr = Array()
	var struct_size = struct.get_size()
	
	struct.set_offset(dir.offset)
	
	if dir.size != 0:
		for i in range(0, dir.size / struct_size):
			var e = struct.eval(dir.offset + i * struct_size)
			arr.push_back(e)
	
	return arr



func _get_lightmap(dir, struct):
	var arr = PoolByteArray()
	arr.resize(dir.size)
	
	struct.open_file()
	
	if dir.size != 0:
		arr = struct.buffer.data_array.subarray(dir.offset, dir.offset+dir.size)
	
	return arr



func _get_entities(header, filename):
	
	var file1 = File.new()
	var err1 = file1.open(filename, File.READ)
	var buffer = file1.get_buffer(file1.get_len())
	file1.close()
	
	var _data = buffer.subarray(header.entities.offset, header.entities.offset + header.entities.size)
	
	# Save entities.txt
	var path = console.cvars["path_prefix"].value + "cache/" + "entities.txt"
	
	var _entities_txt = File.new()
	var _dir = Directory.new()
	_dir.make_dir_recursive( path.get_base_dir() )
	
	var file2 = File.new()
	var err2 = file2.open(path, File.WRITE)
	file2.store_buffer(_data)
	file2.close()
	
	# Create entities dictionary
	var entities = Array()
	
	var s := String(_data)
	
	var entries = s.split("{")
	
	for e in entries:
		var sub_e = e.split("\n")
		
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



func _get_miptexs(header, mipheader_t, miptex_t):
	var mipheader = mipheader_t.eval(header.miptex.offset)
	
	var miptexs = Array()
	
	for i in range(0, mipheader.numtex):
		var miptex = miptex_t.eval(header.miptex.offset + mipheader.offsets[i] )
		miptexs.push_back(miptex)
	
	for i in range(0, miptexs.size()):
		var start = header.miptex.offset + mipheader.offsets[i] + miptexs[i].offset1
		var end = start + miptexs[i].width * miptexs[i].height
		miptexs[i].raw_tex1 = miptex_t.buffer.data_array.subarray(start, end-1)
	
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



func _get_model(map, model_index):
	
	var dir = Directory.new()
	var path = console.cvars["path_prefix"].value + "cache/" + map.filename + "/models/model_" + str(model_index) + ".tscn"
	
	if dir.file_exists(path) and console.cvars["cache"].value == 1:
		mutex_tscn_loading.lock()
		var origin = load(path).instance()
		mutex_tscn_loading.unlock()
		return origin
	else:
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
			mesh.set_name("mesh_array_" + str(t_index))
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array)
			
			var raw_tex = miptexs[texinfos[t].texture_id].raw_tex1
			var w = miptexs[texinfos[t].texture_id].width
			var h = miptexs[texinfos[t].texture_id].height
			
			mutex_tex_loading.lock()
			
			var shader_tex = _get_tex(map, texinfos[t].texture_id)
			var shader_mat = _get_shader_mat(map, texinfos[t].texture_id)
			
			mutex_tex_loading.unlock()
			
			mesh.surface_set_material(0, shader_mat)
			mesh.surface_set_name(0, map.miptexs[texinfos[t].texture_id].name)
			
			
			meshes[t] = mesh
			
			t_index += 1
		
		var origin = Spatial.new()
		origin.rotation_degrees = Vector3(-90,0,0)
		origin.scale = Vector3(0.01,0.01,0.01)
		origin.name = "origin"
		
		var meshes_node = Spatial.new()
		meshes_node.name = "meshes"
		origin.add_child(meshes_node)
		meshes_node.set_owner(origin)
		
		var i = 0
		
		for m in meshes:
			var mi = MeshInstance.new()
			mi.name = "mesh_" + str(i)
			mi.set_mesh(meshes[m])
			meshes_node.add_child(mi)
			mi.set_owner(origin)
			i += 1
		

		if console.cvars["cache"].value == 1:
			dir.make_dir_recursive( path.get_base_dir() )
			var scene = PackedScene.new()
			scene.pack(origin)
			
			mutex_mesh_saving.lock()
			ResourceSaver.save(path, scene)
			mutex_mesh_saving.unlock()
			
		
		
		return origin



func _get_tex(map, index):
	
	var _name : String = _get_tex_name(map, index)
	
	if bsp_textures.has(_name) and console.cvars["cache"].value == 1:
		return bsp_textures[_name]
	else:
		
		var dir = Directory.new()
		
		var path = console.cvars["path_prefix"].value + "cache/" + map.filename + "/textures/" + _name + ".tex"
		
		if ResourceLoader.exists(path) and console.cvars["cache"].value == 1:
			var tex = ResourceLoader.load(path)
			tex.resource_name = _name
			tex.resource_path = path
			bsp_textures[_name] = tex
			return tex
			
		else:
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
			
			if _name.begins_with("sky"):
				tex.flags = ImageTexture.FLAG_REPEAT;
			
			if console.cvars["cache"].value == 1:
				bsp_textures[_name] = tex
				dir.make_dir_recursive( path.get_base_dir() )
				tex.resource_name = _name
				tex.resource_path = path
				ResourceSaver.save(path, tex)
			
			return tex



func _get_tex_name(map, index):
	var _name = map.miptexs[index].name
	
	if _name.begins_with('*'):
		_name.erase(0,1)
		_name = "__asterisk__" + _name
			
	if _name.begins_with('+'):
		_name.erase(0,1)
		_name = "__plus__" + _name
	
	return _name



func _get_shader_mat(map, index):
	var _name : String = _get_tex_name(map, index)
	var shader_tex = bsp_textures[_name]
	
	var shader_mat = ShaderMaterial.new()
	
	if _name.begins_with("sky"):
		shader_mat.shader = load("res://shader/sky.shader")
	else:
		shader_mat.shader = load("res://shader/unshaded.shader")
		
	shader_mat.set_shader_param("tex", shader_tex)
	
	return shader_mat







func _load_entities():
	
	return
	
	progs.load_progs("progs.dat")
	
	var origin = $"/root/world/map/origin"
	
	var entities_node = Spatial.new()
	entities_node.name = "entities"
	#entities.set_owner(origin)
	
	$"/root/world/map/origin".add_child(entities_node)
	
	#var worldspawn = map.entities["worldspawn"]
	
	for e in map.entities:
		if e.has("classname"):
			
			var entity = entities.spawn()
			var evar = entity.get_meta("entvars")
			
			if e.classname == "worldspawn":
				evar["model"] = map.filename
				
			match e.classname:
			
				_:#, "func_door":
					
					var timer_entity = console.con_timer_create(console.DEBUG_LOW)
					
					for key in e:
						if key in evar:
							# -----------------------------------------------------
							# set entity fields
							# -----------------------------------------------------
							match typeof(evar[key]):
								TYPE_STRING:
									evar[key] = str(e[key])
#									print("%s -- string: %s" % [key, evar[key]])
								TYPE_REAL:
									evar[key] = float(e[key])
#									print("%s -- float: %f"  % [key, evar[key]])
								TYPE_VECTOR3:
									var split = e[key].split(" ")
									var x := float(split[0])
									var y := float(split[1])
									var z := float(split[2])
									evar[key] = Vector3(x, y, z)
#									print("%s -- vector: %f %f %f"  % [key, evar[key].x, evar[key].y, evar[key].z])
								_:
									console.con_print_warn("Enity field %s not set!" % key)
									
						else:
							match key:
								# -----------------------------------------------------
								# angle hack
								# -----------------------------------------------------
								"angle":
									var angles := Vector3()
									match int(e["angle"]):
										-1:
											angles = Vector3(0.0, 0.0, 90.0)		# up
										-2:
											angles = Vector3(0.0, 0.0, -90.0)		# down
										_:
											angles.y = float(e["angle"])
										
									evar["angles"] = angles
#									print("%s -- vector: %f %f %f"  % ["angles", evar["angles"].x, evar["angles"].y, evar["angles"].z])
									
									
									
					#entity.set_meta("entvars", evar)
					
					progs.set_global_by_name("self", entity.get_instance_id())
					progs.set_global_by_name("world", entity.get_instance_id())
					
					console.con_print_debug(console.DEBUG_LOW, "---")
					timer_entity.print("Entity %s parsed in " % e.classname)
					
					var timer_exec = console.con_timer_create(console.DEBUG_LOW)
					progs.exec(e.classname)
					timer_exec.print("Executed %s in " % e.classname)

	
#	print(entity.get_meta("entvars").classname)
	
#	for e in map.entities:
#		if e.has("model"):
#			#console.con_print("%s -- model: %d" % [e.classname, e.model])
#			var model = _get_model(map, e.model)
#			model.name = "enity_model_%d" % e.model
#			model.rotation_degrees = Vector3(0, 0, 0)
#			model.scale = Vector3(1.0, 1.0, 1.0)
#			models_node.add_child(model)
	
	
	
	return entities



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

#	console.register_command("bsp_lightmap_uv2", {
#		node = self,
#		description = "Generates the UV2 Coordinates for the whole map.",
#		args = "",
#		num_args = 0
#	})

func _confunc_map(args):
	
	map = Dictionary()
	map_loaded = false
	
	bsp_meshes = Array()
	bsp_textures = Dictionary()
	
	for c in $"/root/world/map".get_children():
		$"/root/world/map".remove_child(c)
		c.queue_free()
	
	load_map("maps/%s" % args[1])
	$"/root/world/map".add_child(bsp_meshes[0])
	
	var _entities = _load_entities()
	#$"/root/world/map/origin".add_child(_entities)

	console.con_print_ok("maps/%s loaded." % args[1])



func _confunc_map_info(args):
	if map_loaded:
		if args[1] == "entities":
			for e in map.entities:
				console.con_print("---")
				for k in e.keys():
					console.con_print("%s %s" % [k, e[k]])
	else:
		console.con_print_warn("No map loaded!")



func _load_icon(name, caption = "Caption!", text = ""):
	var scene = preload("res://gfx/icons/Icon.tscn").instance()
	scene.set_rotation_degrees(Vector3(90,0,0))
	
	#scene.get_node("Viewport/IconText/Caption").set_text(caption)
	#scene.get_node("Viewport/IconText/Text").set_text(text)
	
	return scene


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
#	var icons_node = $"/root/world/map/e1m1bsp_0"
#	var index_num = 0
#	var light_num = 0
#
#	for i in map.entities:
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
##				if i.has("light"):
##					var light = OmniLight.new()
##					light.set_translation(origin)
##					light.omni_range = 4
##					light.light_energy = float(i["light"]) / 256.0
##					icons_node.add_child(light)
##					light.set_owner(icons_node)
#
#				light_num += 1
#
#		index_num += 1


#func _confunc_bsp_lightmap_uv2():
#	var meshes = $"/root/world/map/e1m1bsp_0/Meshes".get_children()
#
#	for mi in meshes:
#		mi.mesh.lightmap_unwrap(mi.get_global_transform(), 0.025)
#		mi.use_in_baked_light = true
#
#	var path = console.cvars["path_prefix"].value + "cache/maps/e1m1.bsp/Models/Lightmapped.tscn"
#	var scene = PackedScene.new()
#
#	scene.pack($"/root/world/map/e1m1bsp_0")
#	ResourceSaver.save(path, scene)
	
