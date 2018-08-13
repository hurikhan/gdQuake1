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


func test_mdl():
	var mdls = find_file_by_ext("user://data/progs/", ".mdl")	
	var all_start = OS.get_ticks_msec()
	
	for i in mdls:
		var start = OS.get_ticks_msec()
		mdl.load_mdl("progs/" + i)
		var end = OS.get_ticks_msec()	
		print(i, " loaded. ( ", str(end-start), "ms )")

	var all_end = OS.get_ticks_msec()	
	print("\nModels loaded in: ", str(all_end-all_start), "ms")	


func _ready():
	print("------------------------------------------------------")
	#pak.load_pak("PAK0.PAK")
	pallete.load_pallete()
	#wad.load_wad("gfx.wad")
	#var m = mdl.load_mdl("progs/armor.mdl")
	var m = mdl.load_mdl("progs/zombie.mdl")
	
	var mesh = mdl.get_mesh(m)
	var mi = $"3d/TestMesh"
	mi.set_mesh(mesh)
	
	#test_show_mdl(m)

	


	#get_tree().quit()