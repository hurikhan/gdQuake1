extends Node

var texture = Dictionary()

onready var raw = Raw.new()

func load_lmp(filename):
	
	if not texture.has(filename):
		
		var file = File.new()
		file.open("user://data/" + filename, file.READ)
		var data = file.get_buffer(file.get_len())
		file.close()
		
		print("lmp_file: ", filename)
		
		var w = raw.get_u32(data, 0)
		var h = raw.get_u32(data, 4)
		
		print("lmp_width: ", w)
		print("lmp_height: ", h)
		
		var sub = data.subarray(8, data.size()-1)
		
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
		texture[filename] = tex
		
	else:
		print("lmp: ", filename, " already loaded.")
	
	return texture[filename]
