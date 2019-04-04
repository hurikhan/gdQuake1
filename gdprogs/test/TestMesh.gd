extends MeshInstance

func _process(delta):
	self.rotate_y(delta)

func _ready():
	set_process(true)
