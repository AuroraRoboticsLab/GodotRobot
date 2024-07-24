extends CanvasLayer

@export var spawn_rate: int = 1
@export var charge_level: float = 100.0
@export var v_cam_sens: float = 0.1
@export var h_cam_sens: float = 0.1
@export var cam_zoom_sens: float = 2.5
@export var tp_height: float = 1.0

@onready var can_attach: bool = false
@onready var stalling: bool = false
@onready var charging: bool = false
@onready var ball_count = 0
@onready var fps = 60
@onready var dirtballs_in_bucket: int = 0
@onready var dirtballs_in_hopper: int = 0
@onready var invert_cam: bool = false

# Code from Godot forums
func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)

func _ready():
	$VersionLabel.text = str(GameManager.version)
	if not GameManager.using_multiplayer:
		%ToggleChatButton.hide()
		$SettingsMenu/VBoxContainer/HBoxContainer2/VBoxContainer2/Control5.hide()
		$ChatContainer.hide()

func _process(_delta):
	$CenterContainer/PressToAttach.visible = can_attach
	
	$PanelContainer/VBoxContainer/GridContainer/FPS.text = str(fps)
	$PanelContainer/VBoxContainer/GridContainer/BallCount.text = str(ball_count)
	$PanelContainer/VBoxContainer/GridContainer/Charge.text = str(round_to_dec(charge_level, 2)) + "%"
	$PanelContainer/VBoxContainer/ChargingLabel.visible = charging
	$PanelContainer/VBoxContainer/StallingLabel.visible = stalling
	
	if dirtballs_in_bucket > 0:
		$PanelContainer/VBoxContainer/BucketDirtballsHBox.show()
		var kg_string = " (" + str(round_to_dec(dirtballs_in_bucket * 0.35, 2)) + " kg)"
		%BucketDirtballs.text = str(dirtballs_in_bucket) + kg_string
	else:
		$PanelContainer/VBoxContainer/BucketDirtballsHBox.hide()
		
	if dirtballs_in_hopper > 0:
		$PanelContainer/VBoxContainer/HopperDirtballsHBox.show()
		var kg_string = " (" + str(round_to_dec(dirtballs_in_hopper * 0.35, 2)) + " kg)"
		%HopperDirtballs.text = str(dirtballs_in_hopper) + kg_string
	else:
		$PanelContainer/VBoxContainer/HopperDirtballsHBox.hide()

func _on_tick_button_value_changed(value):
	spawn_rate = value
	
func _on_settings_button_pressed():
	$SettingsMenu.visible = !$SettingsMenu.visible

func _on_vert_sens_slider_value_changed(value):
	$SettingsMenu/VBoxContainer/HBoxContainer2/VBoxContainer/HBoxContainer/VertSensValLabel.text = str(value)
	v_cam_sens = value

func _on_horiz_sens_slider_value_changed(value):
	$SettingsMenu/VBoxContainer/HBoxContainer2/VBoxContainer/HBoxContainer2/HorizSensValLabel.text = str(value)
	h_cam_sens = value

# Invert camera checkbox
func _on_check_box_toggled(toggled_on):
	invert_cam = toggled_on
	
func _on_tp_height_tick_button_value_changed(value):
	tp_height = value

func _on_zoom_sens_slider_value_changed(value):
	$SettingsMenu/VBoxContainer/HBoxContainer2/VBoxContainer/HBoxContainer4/ZoomSensValLabel.text = str(value)
	cam_zoom_sens = value

func _on_leave_game_button_pressed():
	if GameManager.using_multiplayer:
		multiplayer.multiplayer_peer.close()
	GameManager.self_disconnected.emit()
	get_parent().queue_free()

func _on_keybind_menu_button_pressed():
	if not $KeybindsMenu.visible:
		GameManager.toggle_inputs.emit(false)
		$KeybindsMenu.show()

func _on_respawn_button_pressed():
	pass # Setting positions isn't working for some reason...
	#print("Resetting to spawn")
	#get_parent().robot.reset_to_spawn()

func _on_toggle_chat_button_pressed():
	$ChatContainer.visible = !$ChatContainer.visible
	if $ChatContainer.visible:
		%ToggleChatButton.text = "Hide Chat Window"
	else:
		%ToggleChatButton.text = "Show Chat Window"

var enter_pressed = false
func _on_chat_text_edit_text_submitted(new_text: String):
	if enter_pressed:
		return
	var username = GameManager.get_player_username(multiplayer.get_unique_id())
	if %ChatTextEdit.text != "":
		_send_chat_message.rpc(str(username)+": "+new_text)
		%ChatTextEdit.text = ""
	enter_pressed = true
	$ChatContainer/VBoxContainer/ChatTextEdit/SendMessageTimer.start()

@rpc("any_peer", "call_local")
func _send_chat_message(message):
	var new_message_label = Label.new()
	new_message_label.text = message
	%ChatVBox.add_child(new_message_label)
	await get_tree().process_frame
	await get_tree().process_frame
	%ScrollContainer.ensure_control_visible(new_message_label)

func _on_send_message_timer_timeout():
	enter_pressed = false

func _on_chat_text_edit_focus_entered():
	GameManager.toggle_inputs.emit(false)

func _on_chat_text_edit_focus_exited():
	GameManager.toggle_inputs.emit(true)

func _on_click_control_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		%ChatTextEdit.release_focus()
