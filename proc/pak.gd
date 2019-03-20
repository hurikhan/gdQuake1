extends Node


func _get_pack_entry(data, offset, number):
	var file_name = aux.get_string(data, offset+(64*number), 56)
	var file_offset = aux.get_u32(data, offset+(64*number) + 56)
	var file_size = aux.get_u32(data, offset+(64*number) + 60)
	
	#print("pak_entry: ", file_name, " ", file_offset, " ", file_size)
	console.con_print("pak_entry: " + file_name + " " + str(file_offset) + " " + str(file_size))
	
	var sub = data.subarray(file_offset, file_offset + file_size-1)
	var new_file_name = "user://data/" + file_name
	
	var dir = Directory.new()
	dir.make_dir_recursive( new_file_name.get_base_dir() )
	
	var file = File.new()
	file.open(new_file_name, file.WRITE)
	file.store_buffer(sub)
	file.close()


func load_pak(filename):
	var pak = File.new()
	pak.open("res://data/" + filename, pak.READ)
	var data = pak.get_buffer(pak.get_len())
	
	print("pak_file: ", filename)
	print("pak_size: ", data.size(), " bytes")
	
	var id = ""
	id += char(data[0])
	id += char(data[1])
	id += char(data[2])
	id += char(data[3])
	
	print("pak_header_id: ", id)
	
	if id != "PACK":
		print("Not a PAK file!")
		return
	
	var header_offset = aux.get_u32(data, 4)
	var header_size = aux.get_u32(data, 8)
	var header_entries = header_size / 64
	
	console.con_print("pak_header_offset: " + str(header_offset))
	console.con_print("pak_header_size: " + str(header_size) + " (" + str(header_entries) + " entries)")
	
	for i in range(0, header_entries):
		_get_pack_entry(data, header_offset, i)


func _ready():
	console.register_command("pak_init", {
		node = self,
		description = "Deflates the pak file.",
		args = "",
		num_args = 0
	})
	console.register_command("pak_download", {
		node = self,
		description = "Downloads the shareware PAK file.",
		args = "",
		num_args = 0
	})
	console.register_command("pak_uncompress", {
		node = self,
		description = "Uncompresses the shareware PAK file.",
		args = "",
		num_args = 0
	})


func _confunc_pak_init():
	pak.load_pak("PAK0.PAK")


func _confunc_pak_download():
	var dir = Directory.new()
	dir.make_dir_recursive("user://downloads/lutris/")
	
	var req = HTTPRequest.new()
	get_tree().root.add_child(req)
	
	
	req.download_file = "user://downloads/lutris/quake-shareware.tar.gz"
	#req.use_threads = true
	req.request("https://lutris.net/files/games/quake/quake-shareware.tar.gz")


func _confunc_pak_uncompress():
	var dir = Directory.new()
	dir.make_dir_recursive("user://downloads/lutris/uncompressed")
	
	print(__octale("1234"))
	
	var fd = File.new()
	var err =fd.open_compressed("user://downloads/lutris/quake-shareware.tar.gz", File.READ, File.COMPRESSION_GZIP)
	print(err)
	
	
	# ---------------------------------------------------------
	# define tar header
	# ---------------------------------------------------------
	
	var header = parser_v3.create("tar_header")
	header.add("name",			parser_v3.T_STRING,	100	)
#	header.add("mode",			parser.T_STRING,	8	)
#	header.add("uid",			parser.T_STRING,	8	)
#	header.add("gid",			parser.T_STRING,	8	)
#	header.add("size",			parser.T_STRING,	12	)
#	header.add("mtime",			parser.T_STRING,	12	)
#	header.add("chksum",		parser.T_STRING,	8	)
#	header.add("typeflag",		parser.T_STRING,	1	)
#	header.add("linkname",		parser.T_STRING,	100	)
#	header.add("magic",			parser.T_STRING,	6	)
#	header.add("version",		parser.T_STRING,	2	)
#	header.add("uname",			parser.T_STRING,	32	)
#	header.add("gname",			parser.T_STRING,	32	)
#	header.add("devmajor",		parser.T_STRING,	8	)
#	header.add("devminor",		parser.T_STRING,	8	)
#	header.add("prefix",		parser.T_STRING,	155	)
	
	#var pheader = header.eval(fd)
	#print(pheader)
	
	fd.close()


func __octale(s):
	return s[-1]
	
	
