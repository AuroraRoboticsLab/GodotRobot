extends Node3D
# MovableCamera3D
# Using left click, move the camera around the origin
# TODO:
#   Add logic for zooming
#   Add default starting location capabilities

var camrot_h: float = 0.0
var camrot_v: float = 0.0
var cam_v_max = 75 # Max vertical camera angle (lower bound)
var cam_v_min = -75 # Min vertical camera angle (upper bound)
@onready var h_sens = 0.1 # Horizontal sensitivity
@onready var v_sens = 0.1 # Vertical sensitivity
var h_accel = 10
var v_accel = 10
@onready var cam_h = $Horizontal
@onready var cam_v = $Horizontal/Vertical
@onready var cam_locked: bool = false # Can the camera be rotated?
	
func _input(event):
	if Input.is_action_pressed("right_click") and event is InputEventMouseMotion and not cam_locked:
		camrot_h -= event.relative.x * h_sens
		camrot_v -= event.relative.y * v_sens

func _physics_process(delta):
	# Camera movement logic
	camrot_v = clamp(camrot_v, cam_v_min, cam_v_max)
	cam_h.rotation_degrees.y = lerp(cam_h.rotation_degrees.y, camrot_h, delta * h_accel)
	cam_v.rotation_degrees.x = lerp(cam_v.rotation_degrees.x, camrot_v, delta * v_accel)
