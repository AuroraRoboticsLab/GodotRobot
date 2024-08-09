#@tool
extends Node3D

@onready var animation_player = $AnimationPlayer

@onready var foot_r_cast = $metarig/RayCastR
@onready var foot_r = $metarig/RayCastR/FootIK_R
@onready var foot_l_cast = $metarig/RayCastL
@onready var foot_l = $metarig/RayCastL/FootIK_L

@onready var foot_l_start_pos = foot_l.position
@onready var foot_r_start_pos = foot_r.position

@onready var body = $metarig/Body_IK

var walking = false
var walk_dir = Vector2.ZERO
var walk_speed: float = 0.0

var jumping = false

@onready var time: float = 0.0
var foot_l_pos = false
var foot_r_pos = false

var stride_height = 0.17
var stride_length = 0.3
var stride_mid = Vector3(0.0, -0.55, 0.0) 

var body_z_bob_max = deg_to_rad(3)
var body_lean = deg_to_rad(3)
var body_sway = deg_to_rad(1)
var body_bounce_width = 0.02
var body_bounce_height = 0.03

func _physics_process(delta: float):
	time += delta
	
	if not foot_r_cast.has_method("is_colliding"):
		return
	
	if walking:
		var walk_calc = walk_dir.y*PI*time*1.8
		
		# Lean and sway
		rotation.x = lerp(rotation.x, -walk_dir.y*body_lean, 0.2)
		rotation.z = lerp(rotation.z, -walk_dir.y*body_sway*cos(walk_calc), 0.2)
		# Bounce with walking
		position.x = lerp(position.x, body_bounce_width*cos(walk_calc), 0.2)
		position.y = lerp(position.y, body_bounce_height*sin(walk_calc*2) - 0.1, 0.2)
		# Tilt body
		body.rotation.z = lerp(body.rotation.z, body_z_bob_max*sin(walk_calc + PI), 0.2)
		
		foot_r.position.y = stride_height*sin(walk_calc) + stride_mid.y
		if foot_r_cast.is_colliding() and foot_r_cast.get_collision_point().y >= foot_r.global_position.y:
			if not foot_r_pos:
				foot_r_pos = foot_r.global_position
			else:
				foot_r.global_position = foot_r_pos
		else:
			foot_r_pos = null
			foot_r.position.x = lerp(foot_r.position.x, 0.0, 0.15)
			foot_r.position.z = lerp(foot_r.position.z, stride_length*cos(walk_calc), 0.15) + stride_mid.z
		
		foot_l.position.y = stride_height*sin(walk_calc + PI) + stride_mid.y
		if foot_l_cast.is_colliding() and foot_l_cast.get_collision_point().y >= foot_l.global_position.y:
			if not foot_l_pos:
				foot_l_pos = foot_l.global_position
			else:
				foot_l.global_position = foot_l_pos
		else:
			foot_l_pos = null
			foot_l.position.x = lerp(foot_l.position.x, 0.0, 0.15)
			foot_l.position.z = lerp(foot_l.position.z, stride_length*cos(walk_calc + PI), 0.15) + stride_mid.z
	elif not walking and not jumping:
		position.x = lerp(position.x, 0.0, 0.15)
		position.y = lerp(position.y, -0.1, 0.15)
		body.rotation.z = lerp(body.rotation.z, 0.0, 0.15)
		foot_l_cast.position.z = lerp(foot_l_cast.position.z, 0.0, 0.15)
		foot_r_cast.position.z = lerp(foot_r_cast.position.z, 0.0, 0.15)
		rotation.x = lerp(rotation.x, 0.0, 0.15)
		ground_feet()
	elif jumping:
		foot_r.position.y = lerp(foot_r.position.y, -0.3, 0.15)
		foot_l.position.y = lerp(foot_l.position.y, -0.3, 0.15)

# Try to stick our feet to the ground
func ground_feet(do_left=true, do_right=true):
	if not (do_left or do_right):
		return # Nothing to do then! 
	
	if do_left:
		if foot_l_cast.is_colliding():
			foot_l.global_position = lerp(foot_l.global_position, foot_l_cast.get_collision_point(), 0.15)
		else:
			foot_l.position = lerp(foot_l.position, foot_l_start_pos, 0.15)
	if do_right:
		if foot_r_cast.is_colliding():
			foot_r.global_position = lerp(foot_r.global_position, foot_r_cast.get_collision_point(), 0.15)
		else:
			foot_r.position = lerp(foot_r.position, foot_r_start_pos, 0.15)

func move_feet(dir): # Walk feet in a given direction
	walking = true
	walk_dir = dir

func stop_feet(): # Stop walking feet
	walking = false
	walk_dir = Vector2.ZERO
	foot_l_pos = false
	foot_r_pos = false
