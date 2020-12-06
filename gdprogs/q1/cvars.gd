extends Node



func _ready():
	console.register_cvar("sv_gravity", {
		node = self,
		description = "sv_gravity is a console variable that sets the amount of gravity in the current game.",
		type = "int",
		default_value = 800,
		min_value = 0,
		max_value = 10000
	})



func _convar_sv_gravity(value):
	pass
