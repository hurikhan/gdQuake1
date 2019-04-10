extends Node

var textures = Dictionary()

onready var raw = Raw.new()

func load_lmp(filename):
	
	if not textures.has(filename):
		
		var file = File.new()
		file.open("user://data/" + filename, file.READ)
		var data = file.get_buffer(file.get_len())
		file.close()
		
		console.con_print("lmp_file: %s" % filename)
		
		var w = raw.get_u32(data, 0)
		var h = raw.get_u32(data, 4)
		
		console.con_print("lmp_width: %d" % w)
		console.con_print("lmp_height: %d" % h)
		
		var sub = data.subarray(8, data.size()-1)
		
		var image = Image.new()
		image.create(w, h, false, Image.FORMAT_RGB8)
		image.lock()
		
		for x in range(0,w):
			for y in range(0,h):
				image.set_pixel(x,y, pallete.color[sub[x+y*w]])
		
		image.unlock()
		
		var tex = ImageTexture.new()
		tex.create_from_image(image)
		textures[filename] = tex
		
	else:
		console.con_print("lmp: %s already loaded." % filename)
	
	return textures[filename]


func _ready():
	console.register_command("lmp_load", {
		node = self,
		description = "Loads an lmp image.",
		args = "",
		num_args = 1
	})
	console.register_command("lmp_show", {
		node = self,
		description = "Shows an lmp image in the console.",
		args = "",
		num_args = 1
	})


func _confunc_lmp_load(args):
	load_lmp(args[1])


func _confunc_lmp_show(args):
	var tex = load_lmp(args[1])
	var image = tex.get_data()
	console.con_print_image(image)
