extends StaticBody3D

const dirtball_t = preload("res://terrain/dirtball.gd")
const brick_path = "res://objects/madsen_cinderblock.tscn"
const brick_t = preload(brick_path)
const brick_mass = 10.0

func _ready():
	GameManager.network_process.connect(_network_process)

func _network_process(_delta):
	if not multiplayer.is_server():
		var static_data = GameManager.get_static_data(name)
		if not static_data:
			return
		curr_mass = GameManager.get_static_data(name)["curr_mass"]
		return
	
	var new_static_data = {}
	new_static_data[name] = {
		"curr_mass": curr_mass
	}
	
	GameManager.add_new_static_data(new_static_data)

@onready var curr_mass: float = 9.0:
	set(value):
		if value >= brick_mass and GameManager.using_multiplayer and multiplayer.is_server():
			value -= brick_mass
			var new_brick = brick_t.instantiate()
			new_brick.global_transform = $BrickSpawnpoint.global_transform
			get_parent().objects.add_child(new_brick, true)
			GameManager.add_object(new_brick, brick_path)
			GameManager.new_object.emit(multiplayer.get_unique_id(), brick_path, new_brick.name)
		elif value >= brick_mass and not GameManager.using_multiplayer:
			value -= brick_mass
			var new_brick = brick_t.instantiate()
			new_brick.global_transform = $BrickSpawnpoint.global_transform
			get_parent().objects.add_child(new_brick)
		
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
