extends Node

onready var raw = Raw.new()
var _req

func _get_pack_entry(data, offset, number):
	var file_name = raw.get_string(data, offset+(64*number), 56)
	var file_offset = raw.get_u32(data, offset+(64*number) + 56)
	var file_size = raw.get_u32(data, offset+(64*number) + 60)
	
	var s = "pak_entry[%d]: %s %d %d" % [ number, file_name, file_offset, file_size]
	console.con_print(s)
	
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
	pak.open("user://uncompressed/QUAKE_SW/ID1/" + filename, pak.READ)
	var data = pak.get_buffer(pak.get_len())
		
	print("pak_file: ", filename)
	print("pak_size: ", data.size(), " bytes")
	
	var id = ""
	id += char(raw.get_u8(data, 0))
	id += char(raw.get_u8(data, 1))
	id += char(raw.get_u8(data, 2))
	id += char(raw.get_u8(data, 3))
	
	print("pak_header_id: ", id)
	
	if id != "PACK":
		print("Not a PAK file!")
		return
	
	var header_offset = raw.get_u32(data, 4)
	var header_size = raw.get_u32(data, 8)
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


func _pak_download_status():
	var size = _req.get_body_size()
	var downloaded = _req.get_downloaded_bytes()

	if size == -1:
		return [console.STATUS_INIT, "Begin downloading..."]

	var percent = int( float(downloaded) / float(size) * 100)

	if percent >= 100:
		return [console.STATUS_FINISHED, ["Downloading... 100%", "Download finished"] ]
	
	return [console.STATUS_PROGRESS, "Downloading... %d%%" % percent]


func _pak_download_thread(userdata):
	var dir = Directory.new()
	dir.make_dir_recursive("user://downloads/")
	_req = HTTPRequest.new()
	get_tree().root.add_child(_req)
	_req.download_file = "user://downloads/quake-shareware.tar.xz"
	_req.use_threads = true
	_req.request("https://hurikhan.github.io/files/gdQuake1/quake-shareware.tar.xz")


func _confunc_pak_download():
	console.con_progress(self, "_pak_download_thread", "", "_pak_download_status")


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
