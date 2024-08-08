extends Node3D
# ClippedCamera
# A Camera3D with collision logic to keep the camera in front of bodies

@onready var cam_col = $RayCast3D
@onready var cam = $Camera3D
@onready var marker = $Node3D

# How far ahead does the camera look for bodies?
@export var clip_length: float = 2.5:
	get:
		return -$RayCast3D.target_position.y
	set(value):
		$RayCast3D.target_position.y = -value
		$RayCast3D.position.z = -value

func _ready():
	cam_col.target_position.y = -clip_length
	cam_col.position.z = -clip_length

func _physics_process(_delta):
	if cam_col.is_colliding() and (global_position-cam_col.get_collision_point()).length() < clip_length:
		cam.global_transform.origin = lerp(cam.global_transform.origin, cam_col.get_collision_point(), 0.9)
	else:
		cam.transform.origin = marker.transform.origin
