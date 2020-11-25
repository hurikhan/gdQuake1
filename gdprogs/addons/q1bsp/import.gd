# import.gd
tool
extends EditorImportPlugin

func get_importer_name():
	return "gdquake1.bsp"
	
func get_visible_name():
	return "Quake 1 BSP Import"
	
func get_recognized_extensions():
	return ["bsp"]
	
func get_save_extension():
	return "scn"
	
func get_resource_type():
	return "PackedScene"
	
enum Presets {  }

func get_preset_count():
	return 0
	
func get_import_options(preset):
	return []
	
func import(source_file, save_path, options, r_platform_variants, r_gen_files):
	return PackedScene.new()
