tool
extends EditorPlugin

#const MainScreen = preload("res://addons/q1lmp/mainscreen.tscn")

var msi
var imp


func _enter_tree():
#	msi = MainScreen.instance()
#	get_editor_interface().get_editor_viewport().add_child(msi)
#	make_visible(false)
	
	imp = preload("res://addons/q1lmp/import.gd").new()
	add_import_plugin(imp)


func _exit_tree():
	remove_import_plugin(imp)
	imp = null
	
#	if msi:
#		msi.queue_free()


#func has_main_screen():
#	return true


#func make_visible(visible):
#	if msi:
#		msi.visible = visible


#func get_plugin_name():
#	return "lmp"


#func get_plugin_icon():
#	return get_editor_interface().get_base_control().get_icon("Node", "EditorIcons")
