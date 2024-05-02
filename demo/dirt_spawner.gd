extends Marker3D

@export var spawn_rate = 1
@export var spawn = self
@export var max_balls = 1500
@export var is_spawning = false

@onready var spawn_start_pos = spawn.global_position
var ball: PackedScene = preload("res://terrain/dirtball.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _physics_process(_delta):
	if not is_spawning:
		return

	for i in range(spawn_rate):
		# Spray new dirtballs
		if spawn.get_child_count() <= max_balls:
			var new_ball = ball.instantiate()
			new_ball.top_level = true # dirt position independent of spawner position
			spawn.add_child(new_ball) # appears at spawn origin

		var radius = 0.3 * randf()
		var spawn_x = spawn_start_pos.x + radius*cos(randf())
		var spawn_y = spawn_start_pos.y
		var spawn_z = spawn_start_pos.z + radius*sin(randf())
		spawn.position = Vector3(spawn_x, spawn_y, spawn_z)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("action1"):
		is_spawning = !is_spawning
	#if Input.is_action_just_pressed("down_arrow") and spawn_rate > 0:
	#	spawn_rate -= 1
	#if Input.is_action_just_pressed("up_arrow"):
	#	spawn_rate += 1
