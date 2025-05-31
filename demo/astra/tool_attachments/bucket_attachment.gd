extends ToolAttachment
class_name Bucket

@onready var cutter = $CuttingEdge
@onready var in_bucket = $InsideBucket

@export var pushback_scale = 4.0  # backward force per dirtball excavated
@export var terrain : Node3D # terrain to excavate with our cutting edge
var rigid = self  # rigid body to grab velocity & forces
var pushback_spread = 0.0 # spreads pushback over several physics frames

func _ready():
	center_of_mass = $CenterOfMass.position
	if not terrain:
		terrain = get_tree().root.get_node_or_null("main3D/Terrain/TerrainSim")

# Excavate along cutting edge
func _physics_process(_delta):
	if not connector.connected or terrain == null:
		return # Buckets shouldn't excavate if they are set down or have nothing to excavate.
		
	var xf = cutter.global_transform  # physics is mostly global coords
	pushback_spread *= exp(-10.0*_delta) # damp away the pushback over time
	if pushback_spread < 1.0:
		# Only cut if not pushed back, and moving forward into the terrain
		var forward = rigid.linear_velocity.dot(-xf.basis.z)
		if forward>0.1: # moving mostly forward, try to cut
			var pushback = 0.0
			#var pushpoint = Vector3(0,0,0)
			for xi in range(0,10):
				var x = xi * 0.1
				var world = xf * Vector3(x,0,0) # move along cutting edge 
				var spawn_offset = Vector3(0,0.15,0) # shift new dirtballs into bucket
				var spawn_vel = Vector3(0,0.2,0) # new dirtballs need to fly upward
				var weight = terrain.excavate_point(world,spawn_offset,spawn_vel)
				pushback += weight
				#pushpoint += weight*world
			pushback_spread += pushback
		elif forward<-0.1: # Bucket is moving backwards; we can flatten dirt.
			var _pushback = 0.0
			for xi in range(0,10):
				var x = xi * 0.1
				var world = xf * Vector3(x,0,0) # move along cutting edge 
				var spawn_offset = Vector3(0,-1,0) # for now, dirtballs go underground
				var spawn_vel = Vector3(0,-0.2,0) # new dirtballs can fly downward
				var weight = terrain.excavate_point(world,spawn_offset,spawn_vel)
				_pushback += weight
			#pushback_spread += pushback
			
	if pushback_spread > 0.0:
		var pushdir = xf.basis.z + 0.2*xf.basis.y # pushback direction (global coords)
		rigid.apply_central_force(pushback_scale * pushback_spread * pushdir) # <- bounces joints too strongly
