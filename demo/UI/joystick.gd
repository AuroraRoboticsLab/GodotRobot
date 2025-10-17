extends Control

@onready var knob = $Knob
var pos_vector: Vector2:
	set(value):
		pos_vector = value
		axis_changed.emit(value)

signal axis_changed(new_vector: Vector2)

func get_axis():
	return pos_vector
