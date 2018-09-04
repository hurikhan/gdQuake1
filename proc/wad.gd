extends Node

var status_bar = Dictionary()
var mip_texture = Dictionary()


func _load_status_bar(data, offset, size, name):
	var w = aux.get_u32(data, offset)
	var h = aux.get_u32(data, offset+4)
	
#	print(name, " ", w, " ", h)	
#	print(offset, " ", size)
	
	var sub = data.subarray(offset+8, offset+8+size-1)
	
	var image = Image.new()
	image.create(w, h, false, Image.FORMAT_RGB8)
	image.lock()
	
	for x in range(0,w):
		for y in range(0,h):
			#print(x+y*w)
			image.set_pixel(x,y, pallete.color[sub[x+y*w]])
	image.unlock()
	
	var tex = ImageTexture.new()
	tex.create_from_image(image)
	status_bar[name] = tex
	
	print("wad_status_bar: ", name, " loaded.")



func _get_wad_entry(data, offset, number):
	
	var _offset = offset + (number * 32)
	
	var entry_offset = aux.get_u32(data, _offset)
	var entry_dsize = aux.get_u32(data, _offset+4)
	var entry_size = aux.get_u32(data, _offset+8)
	var entry_type = char(data[_offset+12])
	var entry_cmprs = data[_offset+13]
	var entry_dummy = aux.get_u16(data, _offset+14)
	var entry_name = aux.get_string(data, _offset+16, 16)
	
#	print("wad_entry --------------------------------")
#	print("wad_entry_offset: ", entry_offset)
#	print("wad_entry_dsize: ", entry_dsize)
#	print("wad_entry_size: ", entry_size)
#	print("wad_entry_type: ", entry_type)
#	print("wad_entry_cmprs: ", entry_cmprs)
#	print("wad_entry_dummy: ", entry_dummy)
#	print("wad_entry_name: ", entry_name)
	
	if entry_type == "B":
		_load_status_bar(data, entry_offset, entry_dsize, entry_name)

func load_wad(filename):
	
	var file = File.new()
	file.open("user://data/" + filename, file.READ)
	var data = file.get_buffer(file.get_len())
	file.close()
	
	print("wad_file: ", filename)
	print("wad_size: ", data.size(), " bytes")
	
	var id = ""
	id += char(data[0])
	id += char(data[1])
	id += char(data[2])
	id += char(data[3])
	
	print("wad_header_id: ", id)
	
	var header_entries = aux.get_u32(data, 4)
	var header_offset = aux.get_u32(data, 8)
	
	print("wad_header_entries: ", header_entries)
	print("wad_header_offset: ", header_offset)
	
	for i in range(0, header_entries):
		_get_wad_entry(data, header_offset, i)
