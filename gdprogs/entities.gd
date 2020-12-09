extends Node

var entities = Dictionary()



# -----------------------------------------------------
# spawn
# -----------------------------------------------------
func spawn() -> Spatial:
	var node = $"/root/world/map/origin/entities"
	
	var entity = Spatial.new()
	var id = entity.get_instance_id()
	entity.name = str(id)
	#entity.owner = node
	
	var entvars = load(console.cvars["path_prefix"].value + "/cache/entvars.gd").new()
	
	entity.set_meta("entvars", entvars)
	
	node.add_child(entity)
	
	entities[id] = entity
	
	return entity



# -----------------------------------------------------
# remove
# -----------------------------------------------------
func remove(id):
#	entities[id].queue_free()
#	entites.erase(id)
	pass



func _ready():
	pass # Replace with function body.

