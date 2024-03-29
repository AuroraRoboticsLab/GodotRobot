extends Node3D

@onready var camera_external = $DemoRobot3D/RobotExternalView
const camera_external_id = 0
@onready var camera_onboard = $DemoRobot3D/RobotOnboardView
const camera_onboard_id = 1
var ball: PackedScene = preload("res://ball.tscn")

var curr_camera: int = 0
const max_balls = 800

func _physics_process(delta):
	var new_ball = ball.instantiate()
	
	if $BallSpawn.get_child_count() <= max_balls:
		$BallSpawn.add_child(new_ball)
	$UI.ball_count = $BallSpawn.get_child_count()
	$UI.fps = $"FPS Counter".fps
	
	# Add ficticious forces to pull balls toward robot
	if false:
		for thing in $BallSpawn.get_children():
			var to_robot_vec = $DemoRobot3D.global_position - thing.global_position
			thing.linear_velocity +=  to_robot_vec.normalized() * delta * 2
			
			if thing.linear_velocity.length() > 10:
				thing.linear_velocity = thing.linear_velocity.normalized() * 10
				

func _process(delta):
	# Camera switching
	
	if Input.is_action_just_pressed("switch_view"):
		if curr_camera == camera_onboard_id:
			camera_external.current = true
			curr_camera = camera_external_id
		elif curr_camera == camera_external_id:
			camera_onboard.current = true
			curr_camera = camera_onboard_id

