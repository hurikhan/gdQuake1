extends Node

var color = []

func load_pallete():
	var file = File.new()
	file.open("user://data/gfx/palette.lmp", file.READ)
	var data = file.get_buffer(file.get_len())
	file.close()
	
	for i in range(0,256):
		var r = float( data[i*3] ) / 256
		var g = float( data[i*3+1] ) / 256
		var b = float( data[i*3+2] ) / 256
		color.insert(i, Color( r, g, b ) )
	
	print("pallete: ", color.size(), " colors loaded.")