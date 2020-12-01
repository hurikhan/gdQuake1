extends Node

func _ready():
	console.register_cvar("client_fullscreen", {
		node = self,
		description = "Switches Fullscreen mode on/off",
		type = "int",
		default_value = 0,
		min_value = 0,
		max_value = 1
	})
	console.register_cvar("client_maximized", {
		node = self,
		description = "Switches Window Maximized on/off",
		type = "int",
		default_value = 0,
		min_value = 0,
		max_value = 1
	})

#      ___ ___  _ ____   ____ _ _ __   
#     / __/ _ \| '_ \ \ / / _` | '__|  
#    | (_| (_) | | | \ V / (_| | |     
# ____\___\___/|_| |_|\_/ \__,_|_|____ 
#|_____|                        |_____|

func _convar_client_fullscreen(value):
	if value == 1:
		OS.set_window_fullscreen(true)
	else:
		OS.set_window_fullscreen(false)


func _convar_client_maximized(value):
	if value == 1:
		OS.set_window_maximized(true)
	else:
		OS.set_window_maximized(false)
