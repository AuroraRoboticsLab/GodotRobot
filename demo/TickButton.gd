extends Control

@export var value: int = 0

signal value_changed(value)

func _ready():
	$HBoxContainer/ValueLabel.text = str(value)

func _on_button_up_pressed():
	value += 1
	$HBoxContainer/ValueLabel.text = str(value)
	value_changed.emit(value)

func _on_button_down_pressed():
	value -= 1
	$HBoxContainer/ValueLabel.text = str(value)
	value_changed.emit(value)
