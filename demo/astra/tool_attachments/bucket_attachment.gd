extends RigidBody3D

@onready var connector = $ConnectorComponent
@onready var attachment_type = "bucket"
@onready var cutter = $CuttingEdge

@export var terrain : Node3D # terrain to excavate with our cutting edge
var rigid = self  # rigid body to grab velocity & forces

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("attachment")

# Excavate along cutting edge
func _physics_process(_delta):
	# Only cut if moving forward into the terrain
	var xf = cutter.global_transform
	var forward = rigid.linear_velocity.dot(-xf.basis.z)
	if forward>0.0:
		var pushback = 0.0
		var pushpoint = Vector3(0,0,0)
		for xi in range(0,8):
			var x = xi * 0.125
			var world = xf * Vector3(x,0,0)
			var weight = terrain.excavate_point(world)
			pushback += weight
			pushpoint += weight*world
		if pushback > 0.0:
			var avgpoint = pushpoint / pushback
			var local_pushback = Vector3(0,0,+1.0) # pushback direction (local coords)
			rigid.apply_central_force(pushback * local_pushback) # , avgpoint)
