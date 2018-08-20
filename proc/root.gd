extends Node

var test2_mdls = null
var test2_index = 0
var test3_frames = null
var test3_index = 0


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



func _ready():
	print("------------------------------------------------------")
	#pak.load_pak("PAK0.PAK")
	pallete.load_pallete()
	#wad.load_wad("gfx.wad")
	
#	mdl.load_mdl("progs/armor.mdl")
#	test2_mdls = find_file_by_ext("user://data/progs/", ".mdl")
#	for file in test2_mdls:
#		mdl.load_mdl("progs/" + file)
#
#
#	print(mdl.models)

	mdl.load_mdl("progs/player.mdl")

	mdl.models["progs/player.mdl"].set_node($"3d/TestMesh")
	print(mdl.models["progs/player.mdl"].frames)
	mdl.models["progs/player.mdl"].set_frame("stand1")
	mdl.models["progs/player.mdl"].set_skin(0)
	

	test3_frames = mdl.models["progs/player.mdl"].frames.keys()


	#get_tree().quit()


func _on_Timer_timeout():
	
	if test3_index >= mdl.models["progs/player.mdl"].frames.size() - 1:
		test3_index = 0
		
	mdl.models["progs/player.mdl"].set_frame(test3_frames[test3_index])
	mdl.models["progs/player.mdl"].set_skin(0)
	
	test3_index += 1
	
	$gui/Label.set_text(test3_frames[test3_index])
	
	$"3d/Timer".start()
