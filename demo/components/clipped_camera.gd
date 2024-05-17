extends Node3D
# ClippedCamera
# A Camera3D with collision logic to keep the camera in front of bodies

@onready var cam_col = $RayCast3D
@onready var cam = $Camera3D
@onready var marker = $Node3D

func _physics_process(_delta):
	if cam_col.is_colliding():
		cam.global_transform.origin = lerp(cam.global_transform.origin, cam_col.get_collision_point(), 0.9)
	else:
		cam.global_transform.origin = marker.global_transform.origin
