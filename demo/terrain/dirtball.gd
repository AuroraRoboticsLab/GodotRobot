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
	
	if _can_despawn() and not waiting:
		waiting = true
		# Delay merging by a little. We don't want dirt
		# we are messing with to merge right away!
		$Timer.start()
	
	if global_position.y < -50.0 or linear_velocity.y<-20.0:
		queue_free() # Get rid of falling dirtballs (some fall through and go forever)

var prev_pos = null
func _can_despawn(): # Do we fit the criteria to merge?
	if not prev_pos:
		prev_pos = global_position
	if bucket_count <= 0 and hopper_count <= 0: # not inside a bucket or hopper
		if linear_velocity.length() < 0.2:  # low horizontal velocity (m/s)
			if abs(linear_velocity.y) < 0.02:  # very low vertical velocity (m/s)
				if angular_velocity.length() < 0.1: # not rotating much (rad/s)
					if (prev_pos-global_position).length_squared()<0.02: # Haven't moved far
						return true
					else:
						prev_pos = global_position
	return false

var despawn_attempts: int = 0
func _on_timer_timeout():
	if _can_despawn(): # If we fit merging criteria
		if terrain.try_merge(self):
			despawned = true
			collision_mask = 0 # fall down through terrain
			waiting = false
		else: 
			despawn_attempts += 1
			# More than 25 attempts?? We are probably stuck.
			if despawn_attempts >= 25:
				queue_free()
	else:
		despawn_attempts = 0
	waiting = false
