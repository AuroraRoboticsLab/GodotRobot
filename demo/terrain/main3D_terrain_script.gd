@tool   #<- allows you to see terrain in editor, though has weird side effects
extends Node3D

@onready var spawn = $Dirtballs
@onready var despawn = $DirtballDespawn
@onready var terrain = $TerrainSim # Source of height data
@export var shader : ShaderMaterial # renders the terrain
@export var max_balls = 1500   # <- limited by physics framerate

# Load dirtball 
var ball: PackedScene = preload("res://terrain/dirtball.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
	terrain.add_mesh(shader)
	terrain.add_static_collider();
	terrain.fill_heights(100,100,40);


func _physics_process(_delta):
	# Despawn oldest dirtballs (that have fallen through terrain)
	for dirtball in despawn.get_children():
		if dirtball.linear_velocity.y<-1.0: # has fallen for a while
			dirtball.queue_free()
	
	# Check for stationary dirtballs and consider terrain merge
	for dirtball in spawn.get_children():
		if dirtball.linear_velocity.length() < 0.2:  # low horizontal velocity (m/s)
			if abs(dirtball.linear_velocity.y) < 0.02:  # very low vertical velocity (m/s)
				if dirtball.angular_velocity.length() < 0.1: # not rotating much (rad/s)
					if terrain.try_merge(dirtball):
						var pos = dirtball.global_position
						spawn.remove_child(dirtball)
						dirtball.collision_mask = 0 # fall down through terrain
						despawn.add_child(dirtball)
						dirtball.global_position=pos # preserve position
		
		# A few tend to break through terrain and just plummet
		if dirtball.linear_velocity.y<-20.0: 
			dirtball.queue_free()


# Create a random 3D velocity vector in this range
#   (Surprising there isn't a builtin Godot utility function for this)
func create_random_Vector3(vrange):
	return Vector3(randf_range(-vrange,+vrange),randf_range(-vrange,+vrange),randf_range(-vrange,+vrange))

# Create a new dirtball at this global position & velocity
func spawn_dirtball(pos, vel):
		if spawn.get_child_count() <= max_balls: # ignore requests over cap
			var new_ball = ball.instantiate()
			new_ball.top_level = true # dirt position independent of spawner position
			spawn.add_child(new_ball) 
			new_ball.global_position = pos # override its global position
			new_ball.linear_velocity = vel

# Signal from terrain (perhaps should be linked directly to spawn_dirtball?)
func _on_terrain_sim_spawn_dirtball(spawn_pos):
	spawn_dirtball(spawn_pos,create_random_Vector3(0.05))

