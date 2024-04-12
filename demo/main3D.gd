extends Node3D

@onready var camera_external = $DemoRobot3D/RobotExternalView
const camera_external_id = 0
@onready var camera_onboard = $DemoRobot3D/RobotOnboardView
const camera_onboard_id = 1
@onready var spawn = $DirtSpawner
@onready var despawn = $DirtballDespawn
@onready var terrain = $TerrainScript

var curr_camera: int = 0
var time = 0
func _physics_process(delta):
	time += delta
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
	
	$UI.ball_count = spawn.get_child_count()
	$UI.fps = $"FPS Counter".fps
	$UI.spawn_rate = spawn.spawn_rate
	$UI.charging = $DemoRobot3D.charge_component.charging
	$UI.charge_level = $DemoRobot3D.charge_component.charge_level
	

func _process(_delta):
	# Camera switching
	
	if Input.is_action_just_pressed("switch_view"):
		if curr_camera == camera_onboard_id:
			camera_external.current = true
			curr_camera = camera_external_id
		elif curr_camera == camera_external_id:
			camera_onboard.current = true
			curr_camera = camera_onboard_id

