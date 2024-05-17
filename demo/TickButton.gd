extends Control

@export var value: int = 0
@export var max_value: int = 10
@export var min_value: int = 0

signal value_changed(value)

func _ready():
	$HBoxContainer/ValueLabel.text = str(value)

func _on_button_up_pressed():
	if value >= max_value:
		value = max_value
		return
	value += 1
	$HBoxContainer/ValueLabel.text = str(value)
	value_changed.emit(value)

func _on_button_down_pressed():
	if value <= min_value:
		value = min_value
		return
	value -= 1
	$HBoxContainer/ValueLabel.text = str(value)
	value_changed.emit(value)
