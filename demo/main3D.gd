extends Node3D

@onready var camera_external = $DemoRobot3D/RobotExternalView
const camera_external_id = 0
@onready var camera_onboard = $DemoRobot3D/RobotOnboardView
const camera_onboard_id = 1
@onready var spawn = $DirtballSpawn
@onready var despawn = $DirtballDespawn
@onready var terrain = $TerrainScript

var ball: PackedScene = preload("res://terrain/dirtball.tscn")

var curr_camera: int = 0
const max_balls = 500 # global cap on total number of dirtballs (for performance)

func _physics_process(delta):
	# Despawn oldest dirtballs (that have fallen through terrain)
	for dirtball in despawn.get_children():
		if dirtball.linear_velocity.y<-1.0: # has fallen for a while
			dirtball.queue_free()
	
	# Check for stationary dirtballs and consider terrain merge
	for dirtball in spawn.get_children():
		if dirtball.linear_velocity.length() < 0.2:  # low horizontal velocity (m/s)
			if abs(dirtball.linear_velocity.y) < 0.02:  # very low vertical velocity (m/s)
				if dirtball.angular_velocity.length() < 0.1: # not rotating much (rad/s)
					if terrain.dirtball_merge(dirtball):
						spawn.remove_child(dirtball)
						dirtball.collision_mask = 0 # fall down through terrain
						despawn.add_child(dirtball)
		# A few tend to break through terrain and just plummet
		if dirtball.linear_velocity.y<-10.0: 
			dirtball.queue_free()
	
	# Spray new dirtballs
	if spawn.get_child_count() <= max_balls:
		var new_ball = ball.instantiate()
		spawn.add_child(new_ball) # appears at spawn origin

	$UI.ball_count = spawn.get_child_count()
	$UI.fps = $"FPS Counter".fps
	
	# Add ficticious forces to pull balls toward robot
	if false:
		for dirtball in spawn.get_children():
			var to_robot_vec = $DemoRobot3D.global_position - dirtball.global_position
			dirtball.linear_velocity +=  to_robot_vec.normalized() * delta * 2
			
			if dirtball.linear_velocity.length() > 10:
				dirtball.linear_velocity = dirtball.linear_velocity.normalized() * 10
				

func _process(_delta):
	# Camera switching
	
	if Input.is_action_just_pressed("switch_view"):
		if curr_camera == camera_onboard_id:
			camera_external.current = true
			curr_camera = camera_external_id
		elif curr_camera == camera_external_id:
			camera_onboard.current = true
			curr_camera = camera_onboard_id
