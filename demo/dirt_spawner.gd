# Keeps a set of dirtballs as children
extends Marker3D

@export var spawn_rate = 1  # dirtballs created per physics frame
@export var spawn = self
@export var max_balls = 1500   # <- limited by physics framerate
@export var is_spawning = false

@onready var spawn_start_pos = spawn.global_position
var ball: PackedScene = preload("res://terrain/dirtball.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

@rpc("any_peer","call_local")
func toggle_spawning():
	is_spawning = !is_spawning

# Create a random 3D velocity vector in this range
#   (Surprising there isn't a utility function for this)
func create_random_Vector3(vrange):
	return Vector3(randf_range(-vrange,+vrange),randf_range(-vrange,+vrange),randf_range(-vrange,+vrange))

# Create a new dirtball at this global position
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


func _physics_process(_delta):
	if not is_spawning:
		return

	for i in range(spawn_rate):
		# Spray new dirtballs
		var pos = spawn_start_pos + create_random_Vector3(0.2)
		var vel = create_random_Vector3(0.02)
		spawn_dirtball(pos,vel)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("action1"):
		toggle_spawning()
	#if Input.is_action_just_pressed("down_arrow") and spawn_rate > 0:
	#	spawn_rate -= 1
	#if Input.is_action_just_pressed("up_arrow"):
	#	spawn_rate += 1

