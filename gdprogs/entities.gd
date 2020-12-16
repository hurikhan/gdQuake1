extends Node

var entities = Dictionary()

var entvars_script : GDScript = null

# -----------------------------------------------------
# spawn
# -----------------------------------------------------
func spawn() -> Spatial:
	
	if entvars_script == null:
		entvars_script = load(console.cvars["path_prefix"].value + "/cache/entvars.gd")
	
	var node = $"/root/world/map/origin/entities"
	
	var entity = Spatial.new()
	var id = entity.get_instance_id()
	entity.name = str(id)
	#entity.owner = node
	
	var entvars = entvars_script.new()
	
	entity.set_meta("entvars", entvars)
	
	node.add_child(entity)
	
	entities[id] = entity
	
	return entity



# -----------------------------------------------------
# remove
# -----------------------------------------------------
func remove(ent : Spatial):
#	
	ent.remove_and_skip()

	pass



func _ready():
	pass # Replace with function body.

