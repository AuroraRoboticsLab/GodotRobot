extends Node3D

@onready var camera_external = $DemoRobot3D/CameraPivot/RobotExternalView
const camera_external_id = 0
@onready var camera_onboard = $DemoRobot3D/RobotOnboardView
const camera_onboard_id = 1
@onready var camera_pivot = $DemoRobot3D/CameraPivot
@onready var robot = $DemoRobot3D

var curr_camera: int = 0
var look_at_point: Vector3

# Called when the node enters the scene tree for the first time.
func _ready():
	look_at_point = robot.global_position

func _process(_delta):
	# Camera switching
	if Input.is_action_just_pressed("switch_view"):
		if curr_camera == camera_onboard_id:
			camera_external.current = true
			curr_camera = camera_external_id
		elif curr_camera == camera_external_id:
			camera_onboard.current = true
			curr_camera = camera_onboard_id

