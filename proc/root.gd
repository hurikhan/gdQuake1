extends Node


func _ready():
	print("------------------------------------------------------")
	#pak.load_pak("PAK0.PAK")
	#pallete.load_pallete()
	#wad.load_wad("gfx.wad")
	mdl.load_mdl("progs/armor.mdl")
	mdl.load_mdl("progs/backpack.mdl")
	mdl.load_mdl("progs/zombie.mdl")
	
	get_tree().quit()