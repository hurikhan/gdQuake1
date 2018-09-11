extends Node

func find_file_by_ext(path, ext):
	var dir = Directory.new()
	
	if dir.open(path) == OK:
		
		var ret = Array()
		
		dir.list_dir_begin(true, true)
		var file_name = dir.get_next()
		while (file_name != ""):
			if dir.current_is_dir():
				pass
			else:
				if file_name.ends_with(ext):
					#print("Found file: " + file_name)
					ret.append(file_name)
			file_name = dir.get_next()
		
		return ret
	else:
		print("An error occurred when trying to access the path.")

func test_armor():
	mdl.load_mdl("progs/armor.mdl")
	mdl.models["progs/armor.mdl"].set_node($"3d/TestMesh")
	mdl.models["progs/armor.mdl"].set_frame("armor")


func _ready():
	print("------------------------------------------------------")
	#pak.load_pak("PAK0.PAK")
	pallete.load_pallete()
	#wad.load_wad("gfx.wad")
	#mdl.load_mdl("progs/armor.mdl")
	
	#var map = bsp.load_bsp("maps/b_bh25.bsp")
	var map = bsp.load_bsp("maps/e1m1.bsp")
	#var map = bsp.load_bsp("maps/start.bsp")
	
	$gui/Label.set_text(map.filename)
	
	var level = bsp._get_node(map, 0 )
	$"3d/TestMesh".add_child(level)
	
	#get_tree().quit()
	
	
	

