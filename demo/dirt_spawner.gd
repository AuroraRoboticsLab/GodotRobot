# Keeps a set of dirtballs as children
extends Marker3D

@export var spawn_rate = 1  # dirtballs created per physics frame
@export var spawn = self
@export var is_spawning = false
@export var terrain : Node3D

@onready var spawn_start_pos = spawn.global_position

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

@rpc("any_peer","call_local")
func toggle_spawning():
	is_spawning = !is_spawning

func _physics_process(_delta):
	if not is_spawning:
		return

	for i in range(spawn_rate):
		# Spray new dirtballs
		var pos = spawn_start_pos + terrain.create_random_Vector3(0.2)
		var vel = terrain.create_random_Vector3(0.02)
		terrain.spawn_dirtball(pos,vel)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("action1"):
		toggle_spawning()
	#if Input.is_action_just_pressed("down_arrow") and spawn_rate > 0:
	#	spawn_rate -= 1
	#if Input.is_action_just_pressed("up_arrow"):
	#	spawn_rate += 1

