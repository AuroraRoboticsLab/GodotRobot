extends StaticBody3D

const dirtball_t = preload("res://terrain/dirtball.gd")
const brick_t = preload("res://objects/madsen_cinderblock.tscn")
const brick_mass = 10.0

func _ready():
	if GameManager.using_multiplayer:
		$MultiplayerSynchronizer.set_multiplayer_authority(1)

@onready var curr_mass: float = 9.0:
	set(value):
		if value >= brick_mass and GameManager.using_multiplayer and $MultiplayerSynchronizer.is_multiplayer_authority():
			value -= brick_mass
			var new_brick = brick_t.instantiate()
			new_brick.global_transform = $BrickSpawnpoint.global_transform
			get_parent().add_child(new_brick, true)
		
		var percent_string = str(round_to_dec(value/brick_mass, 2)*100) + "%"
		$Label3D.text = str(round_to_dec(curr_mass, 2))+"/10 kg (" + percent_string + ")"
		curr_mass = value

# Code from Godot forums
func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)

func _on_hopper_area_3d_body_entered(body):
	if body is dirtball_t:
		curr_mass += body.mass
		print("Dirtball entered: ", curr_mass)
		body.queue_free()
