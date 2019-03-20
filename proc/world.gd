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



func init_console():
	var banner = """
           _  ___              _        _
  __ _  __| |/ _ \\ _   _  __ _| | _____/ |
 / _` |/ _` | | | | | | |/ _` | |/ / _ \\ |
| (_| | (_| | |_| | |_| | (_| |   <  __/ |
 \\__, |\\__,_|\\__\\_\\\\__,_|\\__,_|_|\\_\\___|_|
 |___/                                    
"""

	console.con_print(banner)
	console.load_config()



func _ready():
	print("------------------------------------------------------")
	
	init_console()
	
	#pak.load_pak("PAK0.PAK")
	#pallete.load_pallete()
	#wad.load_wad("gfx.wad")
	#mdl.load_mdl("progs/armor.mdl")
	
#	var map = bsp.load_bsp("maps/b_bh25.bsp")
#	var map = bsp.load_bsp("maps/e1m1.bsp")
#	#var map = bsp.load_bsp("maps/start.bsp")
#	var level = bsp._get_node(map, 0 )
#	var door1 = bsp._get_node(map, 1 )
#	var door2 = bsp._get_node(map, 2 )
#	$gui/Label.set_text(map.filename)
		
#	$"3d/TestMesh".add_child(level)
#	$"3d/TestMesh".add_child(door1)
#	$"3d/TestMesh".add_child(door2)
	#get_tree().quit()
	
	var archive = preload("res://addons/gdArchive/gdArchive.gdns").new()
	
	print(archive.get_version())
	print(archive.get_info())
	print(archive.open("user://downloads/lutris/quake-shareware.tar.gz"))
	#var files = archive.list()
	var files = archive.extract("user://test/")
	print(archive.close())
	
	for f in files:
		print(f)
	
	get_tree().quit()



func _on_Button_toggled(button_pressed):
	console.set_console_opened(button_pressed)
