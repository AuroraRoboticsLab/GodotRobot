extends CanvasLayer

@export var spawn_rate: int = 1
@export var charge_level: float = 100.0
@export var v_cam_sens: float = 0.1
@export var h_cam_sens: float = 0.1
@export var cam_zoom_sens: float = 2.5
@export var tp_height: float = 1.0

@onready var num_dirtballs: int = 0
@onready var can_attach: bool = false
@onready var stalling: bool = false
@onready var charging: bool = false
@onready var ball_count = 0
@onready var fps = 60
@onready var dirtballs_in_bucket: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Code from Godot forums
func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)

func _process(_delta):
	$CenterContainer/PressToAttach.visible = can_attach
	
	$PanelContainer/VBoxContainer/GridContainer/FPS.text = str(fps)
	$PanelContainer/VBoxContainer/GridContainer/BallCount.text = str(ball_count)
	$PanelContainer/VBoxContainer/GridContainer/Charge.text = str(round_to_dec(charge_level, 2)) + "%"
	$PanelContainer/VBoxContainer/ChargingLabel.visible = charging
	$PanelContainer/VBoxContainer/StallingLabel.visible = stalling
	if dirtballs_in_bucket >= 0:
		$PanelContainer/VBoxContainer/BucketDirtballsHBox.show()
		var kg_string = " (" + str(round_to_dec(dirtballs_in_bucket * 0.35, 2)) + " kg)"
		%BucketDirtballs.text = str(dirtballs_in_bucket) + kg_string
	else:
		$PanelContainer/VBoxContainer/BucketDirtballsHBox.hide()

func _on_tick_button_value_changed(value):
	spawn_rate = value
	
func _on_settings_button_pressed():
	$SettingsMenu.visible = !$SettingsMenu.visible

func _on_vert_sens_slider_value_changed(value):
	$SettingsMenu/HBoxContainer2/VBoxContainer/HBoxContainer/VertSensValLabel.text = str(value)
	v_cam_sens = value

func _on_horiz_sens_slider_value_changed(value):
	$SettingsMenu/HBoxContainer2/VBoxContainer/HBoxContainer2/HorizSensValLabel.text = str(value)
	h_cam_sens = value
	
func _on_tp_height_tick_button_value_changed(value):
	tp_height = value

func _on_zoom_sens_slider_value_changed(value):
	$SettingsMenu/HBoxContainer2/VBoxContainer/HBoxContainer4/ZoomSensValLabel.text = str(value)
	cam_zoom_sens = value
