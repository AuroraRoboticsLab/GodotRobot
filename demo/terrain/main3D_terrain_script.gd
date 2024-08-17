@tool   #<- allows you to see terrain in editor, though has weird side effects
extends NavigationRegion3D

@onready var spawn = $Dirtballs
@onready var terrain = $TerrainSim # Source of height data
@export var shader : ShaderMaterial # renders the terrain
@export var max_balls = 1500   # <- limited by physics framerate

# Load dirtball 
var ball: PackedScene = preload("res://terrain/dirtball.tscn")

func _ready():
	terrain.add_mesh(shader,true)
	terrain.add_static_collider();
	terrain.fill_heights(128,128,40);

# Create a random 3D velocity vector in this range
#   (Surprising there isn't a builtin Godot utility function for this)
func create_random_Vector3(vrange):
	return Vector3(randf_range(-vrange,+vrange),randf_range(-vrange,+vrange),randf_range(-vrange,+vrange))

# Create a new dirtball at this global position & velocity
func spawn_dirtball(pos, vel):
	if spawn.get_child_count() <= max_balls: # ignore requests over cap
		var new_ball = ball.instantiate()
		new_ball.top_level = true # dirt position independent of spawner position
		new_ball.terrain = terrain
		spawn.add_child(new_ball) 
		new_ball.global_position = pos # override its global position
		new_ball.linear_velocity = vel

# Signal from terrain (perhaps should be linked directly to spawn_dirtball?)
func _on_terrain_sim_spawn_dirtball(spawn_pos,spawn_vel):
	var random_vel = create_random_Vector3(0.05)
	spawn_dirtball(spawn_pos,spawn_vel + random_vel)
