extends Node

func load_mdl(filename):
	
	var mdl = File.new()
	mdl.open("user://data/" + filename, mdl.READ)
	var data = mdl.get_buffer(mdl.get_len())
	
	var aux2 = Aux.new()
	
	var f = aux2.get_f32(data, 32)
	var v = aux2.get_vec(data, 36)
	
	print(f)
	print(v)
	
	return
	
	
	print("mdl_file: ", filename)
	print("mdl_size: ", data.size(), " bytes")
	
	var id = ""
	id += char(data[0])
	id += char(data[1])
	id += char(data[2])
	id += char(data[3])
	
	print("mdl_header_id: ", id)
	
	if id != "IDPO":
		print("Not a MDL file!")
		return
	
	var mdl_version = aux.get_u32(data, 4)
	#var mdl_scale = aux.get_f32(data, 8)
	var mdl_origin = aux.get_f32(data, 20)
	
	print("mdl_header_version: ", mdl_version)
	print("mdl_origin: ", mdl_origin)