extends RigidBody3D

@export var bucket_count = 0  # number of buckets that we are currently inside (0 == free on terrain)
@export var hopper_count = 0 # number of hoppers that we are currently inside

var terrain = null # Set by spawner upon creation
var despawned: bool = false

func _ready():
	$Timer.wait_time = 0.25 # Wait a little before really despawning

var time: float = 0
const dirt_process_interval = 0.25
var last_dirt_process = 0
var dirt_process_delta = time - last_dirt_process

func _process(delta):
	time += delta
	dirt_process_delta = time - last_dirt_process
	if dirt_process_delta >= dirt_process_interval:
		_dirt_process(delta)
		last_dirt_process = time

var waiting = false
func _dirt_process(_delta): # We don't need to check dirt every frame!
	if not terrain:
		return
	
	if waiting:
		return
	
	if despawned and linear_velocity.y<-1.0: # has fallen for a while
		queue_free()
	
	if _can_despawn():
		waiting = true
		# Delay merging by a little. We don't want dirt
		# we are messing with to merge right away!
		$Timer.start()
		
	
	if global_position.y < -50.0 or linear_velocity.y<-20.0:
		queue_free() # Get rid of falling dirtballs (some fall through and go forever)

func _can_despawn():
	if bucket_count <= 0 and hopper_count <= 0: # not inside a bucket or hopper
		if linear_velocity.length() < 0.2:  # low horizontal velocity (m/s)
			if abs(linear_velocity.y) < 0.02:  # very low vertical velocity (m/s)
				if angular_velocity.length() < 0.1: # not rotating much (rad/s)
					return true
	return false

func _on_timer_timeout():
	if _can_despawn() and terrain.try_merge(self): # If we can merge
		despawned = true
		collision_mask = 0 # fall down through terrain
	
	waiting = false
