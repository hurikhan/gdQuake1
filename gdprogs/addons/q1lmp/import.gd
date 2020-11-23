# import.gd
tool
extends EditorImportPlugin


var color = []
var raw = Raw.new()


func get_importer_name():
	return "gdquake1.lmp"


func get_visible_name():
	return "Quake 1 lmp"


func get_recognized_extensions():
	return ["lmp"]


func get_save_extension():
	return "res"


func get_resource_type():
	return "Image"


func get_preset_count():
	return 1


func get_preset_name(preset):
	return "Default"


func get_import_options(preset):
	return []


func import(source_file, save_path, options, platform_variants, gen_files):
	
	var img
	
	_load_pallete(source_file.get_base_dir() + "/")
	
	if source_file.get_file() == "palette.lmp":
		img = _create_pallete_img()
	else:
		if source_file.get_file() == "colormap.lmp":
			img = _create_colormap_img(source_file)
		else:
			img = _load_lmp(source_file)
	
	return ResourceSaver.save(save_path + ".res", img)



func _create_pallete_img():
	var image = Image.new()
	image.create(16, 16, false, Image.FORMAT_RGB8)
	image.lock()
	
	for y in range(0,16):
		for x in range(0,16):
			image.set_pixel(x,y, color[16*y + x])
	
	image.unlock()
	
	return image


func _create_colormap_img(filename):
	var file = File.new()
	file.open(filename, file.READ)
	var data = file.get_buffer(file.get_len())
	file.close()
	
	var image = Image.new()
	image.create(256, 64, false, Image.FORMAT_RGB8)
	image.lock()
	
	for y in range(0,64):
		for x in range(0,256):
			image.set_pixel(x,y, color[data[256*y + x]])
	
	image.unlock()
	
	return image


func _load_pallete(dir):
	var file = File.new()
	file.open(dir + "palette.lmp", file.READ)
	var data = file.get_buffer(file.get_len())
	file.close()
	
	for i in range(0,256):
		var r = float( data[i*3] ) / 256
		var g = float( data[i*3+1] ) / 256
		var b = float( data[i*3+2] ) / 256
		color.insert(i, Color( r, g, b ) )


func _load_lmp(filename):
	
	var file = File.new()
	file.open(filename, file.READ)
	var data = file.get_buffer(file.get_len())
	file.close()
	
	var w = raw.get_u32(data, 0)
	var h = raw.get_u32(data, 4)
	
	var sub = data.subarray(8, data.size()-1)
	
	var image = Image.new()
	image.create(w, h, false, Image.FORMAT_RGB8)
	image.lock()
	
	for x in range(0,w):
		for y in range(0,h):
			image.set_pixel(x,y, color[sub[x+y*w]])
	
	image.unlock()
	
	return image
