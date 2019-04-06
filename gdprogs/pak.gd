extends Node


func _get_pack_entry(data, offset, number):
	var file_name = data.get_string(offset+(64*number), 56)
	var file_offset = data.get_u32(offset+(64*number) + 56)
	var file_size = data.get_u32(offset+(64*number) + 60)
	
	var s = "pak_entry[%d]: %s %d %d" % [ number, file_name, file_offset, file_size]
	console.con_print(s)
	
	var sub = data.get_subarray(file_offset, file_offset + file_size-1)
	var new_file_name = "user://data/" + file_name
	
	var dir = Directory.new()
	dir.make_dir_recursive( new_file_name.get_base_dir() )
	
	var file = File.new()
	file.open(new_file_name, file.WRITE)
	file.store_buffer(sub)
	file.close()


func load_pak(filename):
	var pak = File.new()
	pak.open("user://uncompressed/QUAKE_SW/ID1/" + filename, pak.READ)
	var buffer = pak.get_buffer(pak.get_len())
	
	var data = preload("res://addons/gdPoolByteArrayExt/gdPoolByteArrayExt.gdns").new()
	data.read(buffer)
	
	print("pak_file: ", filename)
	print("pak_size: ", data.size(), " bytes")
	
	var id = ""
	id += char(data.get_u8(0))
	id += char(data.get_u8(1))
	id += char(data.get_u8(2))
	id += char(data.get_u8(3))
	
	print("pak_header_id: ", id)
	
	if id != "PACK":
		print("Not a PAK file!")
		return
	
	var header_offset = data.get_u32(4)
	var header_size = data.get_u32(8)
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


var _req

func _pak_download_completed(result, response_code, headers, body):
	console.con_print_ok("Download completed")

func _pak_download_status():
	var size = _req.get_body_size()
	var downloaded = _req.get_downloaded_bytes()
	
	if size == -1:
		return 0.0

	var ret = float(downloaded) / float(size)
	
	return ret

func _pak_download_thread(userdata):
	var dir = Directory.new()
	dir.make_dir_recursive("user://downloads/")
	_req = HTTPRequest.new()
	get_tree().root.add_child(_req)
	_req.download_file = "user://downloads/quake-shareware.tar.xz"
	_req.use_threads = true
	_req.connect("request_completed", self, "_pak_download_completed")
	_req.request("https://hurikhan.github.io/files/gdQuake1/quake-shareware.tar.xz")

func _confunc_pak_download():
	
	console.con_progress(self, "_pak_download_thread", "", "_pak_download_status")
	
	#while not completed:
	#	OS.delay_msec(500)
	#	console.con_print(str(req.get_downloaded_bytes()))


func _confunc_pak_uncompress():
	var archive = preload("res://addons/gdarchive/gdarchive.gdns").new()
	
	print(archive.get_version())
	print(archive.get_info())
	print(archive.open("user://downloads/quake-shareware.tar.xz"))
	#var files = archive.list()
	#files = archive.list()
	var files = archive.extract("user://uncompressed/")
	print(archive.close())
	
	#get_tree().quit()
