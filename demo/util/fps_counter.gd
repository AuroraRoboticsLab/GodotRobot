extends Node3D

# From  https://www.reddit.com/r/godot/comments/8p3lm0/fps_counter_in_game/
const PRINT_TIME = 2.0
var timer = 0.0
@export var fps = 0

func _process(delta):
	timer += delta
	if timer > PRINT_TIME: # Prints every 2 seconds
		timer = 0.0
		fps = Engine.get_frames_per_second()
		print("fps: ",fps,"    ",1000.0/fps,"  ms/frame")