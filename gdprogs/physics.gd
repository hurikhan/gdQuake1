extends Node

const MOVETYPE_NONE				:= 0		# never moves
const MOVETYPE_ANGLENOCLIP		:= 1
const MOVETYPE_ANGLECLIP		:= 2
const MOVETYPE_WALK				:= 3		# gravity
const MOVETYPE_STEP				:= 4		# gravity, special edge handling
const MOVETYPE_FLY				:= 5
const MOVETYPE_TOSS				:= 6		# gravity
const MOVETYPE_PUSH				:= 7		# no clip to world, push and crush
const MOVETYPE_NOCLIP			:= 8
const MOVETYPE_FLYMISSILE		:= 9		# extra size to monsters
const MOVETYPE_BOUNCE			:= 10



var box_hull : hull_t
var box_clipnodes : Array	# [6]
var box_planes : Array		# [6]


class mplane_t:
	var normal : Vector3 = Vector3()
	var dist : float = 0.0
	var type : int = 0
	var signbits : int = 0


class dclipnode_t:
	var planenum : int = 0
	var children : PoolIntArray
	
	func _init():
		children.resize(2)


class hull_t:
	var clipnodes : Array
	var planes : Array
	var firstclipnode : int
	var lastclipnode : int
	var clip_mins : Vector3
	var clip_maxs : Vector3


#	===================
#	SV_InitBoxHull
#
#	Set up the planes and clipnodes so that the six floats of a bounding box
#	can just be stored out and get a proper hull_t structure.
#	===================
func SV_InitBoxHull() -> void:
	
	box_hull = hull_t.new()
	box_clipnodes.resize(6)
	box_planes.resize(6)
	
	for i in range(6):
		box_clipnodes[i] = dclipnode_t.new()
		box_planes[i] = mplane_t.new()
	
	box_hull.clipnodes = box_clipnodes
	box_hull.planes = box_planes
	
	box_hull.firstclipnode = 0
	box_hull.lastclipnode = 5
	
	var side : int
	
	for i in range(6):
		
		box_clipnodes[i].planenum = i
		
		side &= i
		
		box_clipnodes[i].children[side] = bsp.CONTENTS_EMPTY
		
		if i !=5:
			#XOR 1
			if side == 1:
				side = 0
			else:
				side = 1	
				
				
			box_clipnodes[i].children[side] = i + 1
		else:
			box_clipnodes[i].children[side] = bsp.CONTENTS_EMPTY
		
		box_planes[i].type = i>>1
		box_planes[i].normal[i>>1] = 1



#	===================
#	SV_HullForBox
#
#	To keep everything totally uniform, bounding boxes are turned into small
#	BSP trees instead of being compared directly.
#	===================
func SV_HullForBox(mins : Vector3, maxs : Vector3) -> hull_t:
	
	box_planes[0].dist = maxs[0]
	box_planes[1].dist = mins[0]
	box_planes[2].dist = maxs[1]
	box_planes[3].dist = mins[1]
	box_planes[4].dist = maxs[2]
	box_planes[5].dist = mins[2]
	
	return box_hull


#	================
#	SV_HullForEntity
#
#	Returns a hull that can be used for testing or clipping an object of mins/maxs
#	size.
#	Offset is filled in to contain the adjustment that must be added to the
#	testing object's origin to get a point to use with the returned hull.
#	================
func SV_HullForEntity(ent : Spatial, mins : Vector3, maxs : Vector3, offset : Vector3 ) -> hull_t:
	
	var entvars = ent.get_meta("entvars")
	
	if entvars["movetype"] != MOVETYPE_PUSH:
		console.con_print_error("SOLID_BSP without MOVETYPE_PUSH")
	
	##FIXME
	#if (!model || model->type != mod_brush)
	#        Sys_Error ("MOVETYPE_PUSH with a non bsp model");
	
	return box_hull



func _ready():
	SV_InitBoxHull()



