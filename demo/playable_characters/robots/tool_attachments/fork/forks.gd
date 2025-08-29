@tool
extends ToolAttachment
class_name Forks

func _ready():
	super._ready()

func get_speed_mod():
	return 0.5 # Move half as quickly with the forks
