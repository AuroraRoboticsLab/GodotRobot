extends Control

@onready var knob = $Knob
var pos_vector: Vector2

func get_axis():
	return pos_vector
