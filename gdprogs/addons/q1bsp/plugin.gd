tool
extends EditorPlugin


var import


func _enter_tree():
	import = preload("res://addons/q1bsp/import.gd").new()
	add_import_plugin(import)


func _exit_tree():
	remove_import_plugin(import)
	import = null
