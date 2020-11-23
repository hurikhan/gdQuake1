extends Node

onready var raw = Raw.new()
var _req

func _get_pack_entry(data, offset, number):
	var file_name = raw.get_string(data, offset+(64*number), 56)
	var file_offset = raw.get_u32(data, offset+(64*number) + 56)
	var file_size = raw.get_u32(data, offset+(64*number) + 60)
	
	var s = "pak_entry[%d]: %s [offset: %d size: %d]" % [ number, file_name, file_offset, file_size]
	console.con_print(s)
	
	var sub = data.subarray(file_offset, file_offset + file_size-1)
	var new_file_name = console.cvars["path_prefix"].value + "id-x/" + file_name
	
	var dir = Directory.new()
	dir.make_dir_recursive( new_file_name.get_base_dir() )
	
	var file = File.new()
	file.open(new_file_name, file.WRITE)
	file.store_buffer(sub)
	file.close()


func load_pak(filename):
	var pak = File.new()
	pak.open("res://data/id1/" + filename, pak.READ)
	var data = pak.get_buffer(pak.get_len())
	
	console.con_print("pak_file: %s" % filename)
	console.con_print("pak_size: %s bytes" % data.size())
	
	var id = ""
	id += char(raw.get_u8(data, 0))
	id += char(raw.get_u8(data, 1))
	id += char(raw.get_u8(data, 2))
	id += char(raw.get_u8(data, 3))
	
	console.con_print("pak_header_id: %s" % id)
	
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
	console.register_command("pak_decompress", {
		node = self,
		description = "Decompresses the shareware PAK file.",
		args = "",
		num_args = 0
	})



func _confunc_pak_init():
	pak.load_pak("pak0.pak")


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


func _confunc_pak_decompress():
	pass

