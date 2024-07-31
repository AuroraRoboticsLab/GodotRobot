extends ToolAttachment
class_name Forks

func _ready():
	center_of_mass = $CenterOfMass.position

func get_speed_mod():
	return 0.5 # Move half as quickly with the forks
