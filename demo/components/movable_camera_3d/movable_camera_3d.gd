extends Node3D
class_name MovableCamera
# MovableCamera3D
# Using left click, move the camera around the origin
# Using mouse wheel, zoom camera in and out.

@export var rotate_camera: GUIDEAction
@export var zoom_camera: GUIDEAction
@export var activate_camera: GUIDEAction


var camrot_h: float = 0.0
var camrot_v: float = 0.0
var cam_v_max = 75 # Max vertical camera angle (lower bound)
var cam_v_min = -75 # Min vertical camera angle (upper bound)
@onready var h_sens = 0.1 # Horizontal sensitivity
@onready var v_sens = 0.1 # Vertical sensitivity
var invert_mult = 1
@onready var invert_cam: bool = false:
	set(value):
		if value:
			invert_mult = -1
		else:
			invert_mult = 1
		invert_cam = value
var h_accel = 10
var v_accel = 10
@onready var cam_h = $Horizontal
@onready var cam_v = $Horizontal/Vertical

@onready var cam_locked: bool = false # Can the camera be rotated?
@export var camera_distance: float = 2.5 # Distance of camera from rotation origin
@onready var clipped_cam = $Horizontal/Vertical/ClippedCamera
@onready var zoom_sens: float = 2.5 # Zoom sensitivity
@onready var min_zoom: float = 1
@onready var max_zoom: float = 10

var lock_horiz: bool = false
	
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	for child in get_children():
		child.process_mode = Node.PROCESS_MODE_ALWAYS
	clipped_cam.position.z = camera_distance
	clipped_cam.clip_length = camera_distance

#func _input(event):
#	if InputManager.get_can_input() and not cam_locked and event is InputEventMouseMotion:
#		if Input.is_action_pressed("right_click") or (OS.get_name() == "Android" and Input.is_action_pressed("left_click")):
#			camrot_h -= event.relative.x * h_sens
#			camrot_v -= event.relative.y * v_sens * invert_mult

const SENS_MULT = 8
var switch_pov = false
func _process(delta):
	if Input.is_action_just_pressed("switch_view"):
		switch_pov = !switch_pov
	
	if switch_pov:
		rotation.y = PI
	else:
		rotation.y = 0
	#if InputManager.get_can_input() and not cam_locked and 
	#print(zoom_camera.value_axis_1d)
	if activate_camera.is_triggered():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		camrot_h += rotate_camera.value_axis_2d.x * SENS_MULT * h_sens
		camrot_v += rotate_camera.value_axis_2d.y * invert_mult * SENS_MULT * v_sens
		camera_distance = clamp(lerp(camera_distance, camera_distance-2*zoom_camera.value_axis_1d*zoom_sens, delta*h_accel), min_zoom, max_zoom)
		clipped_cam.clip_length = camera_distance
		$Horizontal/Vertical/ClippedCamera.position.z = camera_distance
		
		#if Input.is_action_pressed("dpad_up"):
		#	camrot_v -= v_sens * SENS_MULT * invert_mult
		#if Input.is_action_pressed("dpad_down"):
		#	camrot_v += v_sens * SENS_MULT * invert_mult
		#if Input.is_action_pressed("dpad_left"):
		#	camrot_h -= h_sens * SENS_MULT
		#if Input.is_action_pressed("dpad_right"):
		#	camrot_h += h_sens * SENS_MULT
	elif InputManager.in_move_mode():
		print(":D")
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Camera movement logic
	camrot_v = clamp(camrot_v, cam_v_min, cam_v_max)
	if not lock_horiz:
		cam_h.rotation_degrees.y = lerp(cam_h.rotation_degrees.y, camrot_h, delta * h_accel)
	cam_v.rotation_degrees.x = lerp(cam_v.rotation_degrees.x, camrot_v, delta * v_accel)
