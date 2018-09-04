extends Node

func find_file_by_ext(path, ext):
	var dir = Directory.new()
	
	if dir.open(path) == OK:
		
		var ret = Array()
		
		dir.list_dir_begin(true, true)
		var file_name = dir.get_next()
		while (file_name != ""):
			if dir.current_is_dir():
				pass
			else:
				if file_name.ends_with(ext):
					#print("Found file: " + file_name)
					ret.append(file_name)
			file_name = dir.get_next()
		
		return ret
	else:
		print("An error occurred when trying to access the path.")

func test_armor():
	mdl.load_mdl("progs/armor.mdl")
	mdl.models["progs/armor.mdl"].set_node($"3d/TestMesh")
	mdl.models["progs/armor.mdl"].set_frame("armor")



func _get_triangles(polygon, normal):
	
	var ret = Dictionary()
	var v = PoolVector3Array()
	var n = PoolVector3Array()
	
	while(polygon.size() >= 3):
		
		v.push_back(polygon[0])
		v.push_back(polygon[1])
		v.push_back(polygon[2])
		
		n.push_back(normal)
		n.push_back(normal)
		n.push_back(normal)
		
		polygon.remove(1)
			
	ret.vertices = v
	ret.normals = n		
	return ret


func _ready():
	print("------------------------------------------------------")
	#pak.load_pak("PAK0.PAK")
	pallete.load_pallete()
	#wad.load_wad("gfx.wad")
	#mdl.load_mdl("progs/armor.mdl")

	#var map = bsp.load_bsp("maps/b_bh25.bsp")
	var map = bsp.load_bsp("maps/e1m1.bsp")

	$gui/Label.set_text("maps/e1m1.bsp")

	print(map.models[0])

	var m0 = map.models[0]
	var faces = map.faces
	var ledges = map.ledges
	var edges = map.edges
	var vertices = map.vertices
	var planes = map.planes

	var v = PoolVector3Array()
	var n = PoolVector3Array()

	for f in range(m0.face_id, m0.face_id + m0.face_num):


		var normal = planes[faces[f].plane_id].normal
							
		var polygon = PoolVector3Array()
		
		for e in range(faces[f].ledge_id, faces[f].ledge_id + faces[f].ledge_num):
			if ledges[e] > 0:
				polygon.push_back(vertices[edges[ledges[e]].vertex0])
			else:
				polygon.push_back(vertices[edges[-ledges[e]].vertex1])
		
		if faces[f].side == 1:
			normal = normal * -1
		
		var triangles = _get_triangles(polygon, normal)
		v.append_array(triangles.vertices)
		n.append_array(triangles.normals)


	# Create mesh	
	var array = Array()
	array.resize(9)
	array[Mesh.ARRAY_VERTEX] = v
	array[Mesh.ARRAY_NORMAL] = n

	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array)

	# Create material
#	var mat = SpatialMaterial.new()
#	mesh.surface_set_material(0, mat)
#
	$"3d/TestMesh".set_mesh(mesh)

	
	#get_tree().quit()
	
	
	

