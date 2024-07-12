extends RigidBody3D

@export var bucket_count = 0  # number of buckets that we are currently inside (0 == free on terrain)
@export var hopper_count = 0 # number of hoppers that we are currently inside

func _physics_process(_delta):
	if global_position.y < -50.0:
		queue_free() # Get rid of falling dirtballs (some fall through and go forever)
