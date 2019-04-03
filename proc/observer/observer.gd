extends KinematicBody

# Member variables
var r_pos = Vector2()

func direction(vector):
	var v = $Camera.get_global_transform().basis * vector
	v = v.normalized()
	return v


func _physics_process(delta):
	if (console.is_console_opened()):
		return
	
	var dir = Vector3()
	if (Input.is_action_pressed("q1_move_forward")):
		dir += direction(Vector3(0, 0, -1))
	if (Input.is_action_pressed("q1_move_backwards")):
		dir += direction(Vector3(0, 0, 1))
	if (Input.is_action_pressed("q1_move_left")):
		dir += direction(Vector3(-1, 0, 0))
	if (Input.is_action_pressed("q1_move_right")):
		dir += direction(Vector3(1, 0, 0))
	
	dir = dir.normalized()
	
	move_and_collide(dir * 500 * delta)
	var d = delta * 0.1
	
	# set yaw
	rotate(Vector3(0, 1, 0), d*r_pos.x)
	
	# set pitch
	var pitch = $Camera.get_transform().rotated(Vector3(1, 0, 0), d * r_pos.y)
	$Camera.set_transform(pitch)
	
	r_pos = Vector2()


func _input(event):
	if (event is InputEventMouseMotion):
		r_pos = -event.relative
