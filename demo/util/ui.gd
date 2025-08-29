extends CanvasLayer

@export var spawn_rate: int = 1
@export var charge_level: float = 100.0
@export var v_cam_sens: float = 0.1
@export var h_cam_sens: float = 0.1
@export var cam_zoom_sens: float = 2.5
@export var tp_height: float = 1.0

@onready var player = null
@onready var can_attach: bool = false
@onready var stalling: bool = false
@onready var charging: bool = false
@onready var ball_count = 0
@onready var fps = 60
@onready var dirtballs_in_bucket: int = 0
@onready var dirtballs_in_hopper: int = 0
@onready var invert_cam: bool = false
@onready var left_joystick = $LeftJoystick
@onready var right_joystick = $RightJoystick
@onready var cam_locked: bool = false
@onready var unsafe_mode: bool = false

# Code from Godot forums
func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	for child in get_children():
		child.process_mode = Node.PROCESS_MODE_ALWAYS
	
	if OS.get_name() == "Android":
		left_joystick.show()
		right_joystick.show()
		$SettingsMenu/VBoxContainer/HBoxContainer2/VBoxContainer/MobileJoystickSizeLabel.show()
		$SettingsMenu/VBoxContainer/HBoxContainer2/VBoxContainer/HBoxContainer6.show()
		$MobileButton1.show()
	
	$VersionLabel.text = str(GameManager.version)
	
	if not GameManager.using_multiplayer:
		%ToggleChatButton.hide()
		$SettingsMenu/VBoxContainer/HBoxContainer2/VBoxContainer2/Control5.hide()
		$ChatContainer.hide()

	if GameManager.player_choice == GameManager.Character.ASTRO or GameManager.player_choice == GameManager.Character.SPECT:
		%ToggleUnsafeMode.hide()
		$SettingsMenu/VBoxContainer/HBoxContainer2/VBoxContainer2/Control7.hide()
		$SettingsMenu/VBoxContainer/HBoxContainer2/VBoxContainer/HBoxContainer3.hide()
	elif GameManager.player_choice == GameManager.Character.ASTRA:
		$PanelContainer/VBoxContainer/GridContainer/ChargeLabel.show()
		$PanelContainer/VBoxContainer/GridContainer/Charge.show()

func _process(_delta):
	# Toggle UI visibility
	if Input.is_action_just_pressed("f2"):
		visible = !visible
	
	# Handle pausing logic
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = !get_tree().paused
	
	if Input.is_action_just_pressed("escape") and freecamming:
		freecamming = false
		$FreecamLabel.hide()
	
	# Lock the camera when using joysticks in mobile
	if left_joystick.knob.pressing or right_joystick.knob.pressing:
		cam_locked = true
	else:
		cam_locked = false
	
	# Toggle command window
	if Input.is_action_just_pressed("f1"):
		$CommandLineEdit.visible = !$CommandLineEdit.visible
	
	$PanelContainer/VBoxContainer/GridContainer/FPS.text = str(fps)
	$PanelContainer/VBoxContainer/GridContainer/BallCount.text = str(ball_count)
	if GameManager.player_choice == GameManager.Character.ASTRA:
		$CenterContainer/PressToAttach.visible = can_attach
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

func _physics_process(_delta):
	if player:
		if GameManager.player_choice == GameManager.Character.ASTRA or GameManager.player_choice == GameManager.Character.EXCAH:
			$PanelContainer/VBoxContainer/GridContainer/Speed.text = str(round_to_dec(player.linear_velocity.length(), 2)) + " m/s"
		elif GameManager.player_choice == GameManager.Character.ASTRO:
			$PanelContainer/VBoxContainer/GridContainer/Speed.text = str(round_to_dec(player.velocity.length(), 2)) + " m/s"

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
		InputManager.set_can_input(false)
		$KeybindsMenu.show()

func _on_respawn_button_pressed():
	if not player:
		return
	await get_tree().physics_frame
	await get_tree().physics_frame
	if GameManager.player_choice == GameManager.Character.ASTRA:
		player.linear_velocity = Vector3.ZERO
		player.angular_velocity = Vector3.ZERO
	elif GameManager.player_choice == GameManager.Character.ASTRO:
		player.velocity = Vector3.ZERO
	player.global_transform = player.spawn_trans

func _on_toggle_chat_button_pressed():
	$ChatContainer.visible = !$ChatContainer.visible
	GameManager.using_chat = $ChatContainer.visible # Disable chat if invisible
	if $ChatContainer.visible:
		%ToggleChatButton.text = "Disable Chat Window"
	else:
		%ToggleChatButton.text = "Enable Chat Window"

var enter_pressed = false
func _on_chat_text_edit_text_submitted(new_text: String):
	if enter_pressed:
		return
	var username = GameManager.get_player_username(multiplayer.get_unique_id())
	if %ChatTextEdit.text != "":
		if multiplayer.is_server():
			if GameManager.using_chat:
				_send_chat_message.rpc(str(username)+": "+new_text)
		else: # All chat messages go through the server.
			_try_send_chat_message.rpc_id(1, multiplayer.get_unique_id(), str(username)+": "+new_text)
		%ChatTextEdit.text = ""
	enter_pressed = true
	$ChatContainer/VBoxContainer/ChatTextEdit/SendMessageTimer.start()

@rpc("any_peer")
func _try_send_chat_message(sender_id, message):
	if multiplayer.is_server():
		if GameManager.using_chat:
			_send_chat_message.rpc(message)
		else:
			_send_chat_message.rpc_id(sender_id, "Host has disabled chat!")

@rpc("any_peer", "call_local")
func _send_chat_message(message):
	if not GameManager.using_chat:
		return # No messages for those who have disabled chat!
	var new_message_label = Label.new()
	new_message_label.text = message
	%ChatVBox.add_child(new_message_label)
	await get_tree().process_frame
	await get_tree().process_frame
	print(message) # Print the chat in the console
	%ScrollContainer.ensure_control_visible(new_message_label)

func _on_send_message_timer_timeout():
	enter_pressed = false

func _on_chat_text_edit_focus_entered():
	InputManager.set_can_input(false)

func _on_chat_text_edit_focus_exited():
	InputManager.set_can_input(true)

func _on_click_control_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		%ChatTextEdit.release_focus()
		$CommandLineEdit.release_focus()

func _on_mobile_ui_slider_value_changed(value):
	$SettingsMenu/VBoxContainer/HBoxContainer2/VBoxContainer/HBoxContainer6/MobileUILabel.text = str(value)
	var scale_val = 0.08 * value
	left_joystick.scale = Vector2(scale_val, scale_val)
	right_joystick.scale = Vector2(scale_val, scale_val)

@onready var freecam_scene = load("res://components/freecam.tscn")
var freecamming = false
func _on_command_line_edit_text_submitted(new_text):
	$CommandLineEdit.text = ""
	var args = new_text.strip_edges().split(" ")
	if args.size() > 0:
		var command = args[0].to_lower()
		match command:
			"goto": # Pathfind to a given location
				if not player:
					print("Error: No player to teleport!")
					return
				if GameManager.player_choice not in [GameManager.Character.ASTRA, GameManager.Character.EXCAH]:
					print("Error: Only a robot can pathfind!")
					return
				if args.size() == 4:
					var x = args[1].to_float()
					var y = args[2].to_float()
					var z = args[3].to_float()
					print("Going to (", x, ", ", y, ", ", z, ")")
					
					player.auto_component.pathfind_to(Vector3(x, y, z))
				else:
					print("Error: 'move' command requires x, y, and z coordinates.")
			"respawn": # Teleport back to spawn
				_on_respawn_button_pressed()
			"move": # Teleport relative to our current location
				if GameManager.using_multiplayer and not multiplayer.is_server():
					print("Error: Must be host to teleport!")
					return
				if not player:
					print("Error: No player to teleport!")
					return
				if args.size() == 4:
					var x = args[1].to_float()
					var y = args[2].to_float()
					var z = args[3].to_float()
					print("Moving to ", x, ", ", y, ", ", z)
					await get_tree().physics_frame
					await get_tree().physics_frame
					player.global_position += Vector3(x, y, z)
					if player is RigidBody3D:
						player.linear_velocity = Vector3.ZERO
						player.angular_velocity = Vector3.ZERO
					elif player is CharacterBody3D:
						player.velocity = Vector3.ZERO
				else:
					print("Error: 'move' command requires x, y, and z coordinates.")
			"grav": # Modify gravity!
				if GameManager.using_multiplayer and not multiplayer.is_server():
					print("Error: Must be host to modify gravity!")
					return
				if args.size() == 2:
					PhysicsServer3D.area_set_param(
						get_viewport().find_world_3d().space,
						PhysicsServer3D.AREA_PARAM_GRAVITY,
						args[1]
					)
				else:
					print("Error: 'grav' requires a float for gravity.")
			"tp": # Teleport to a location
				if GameManager.using_multiplayer and not multiplayer.is_server():
					print("Error: Must be host to teleport!")
					return
				if not player:
					print("Error: No player to teleport!")
					return
				if args.size() == 4:
					var x = args[1]
					if x == "~":
						x = player.global_position.x
					else:
						x = x.to_float()
					var y = args[2]
					if y == "~":
						y = player.global_position.y
					else:
						y = y.to_float()
					var z = args[3]
					if z == "~":
						z = player.global_position.z
					else:
						z = z.to_float()
					print("Teleporting to ", x, ", ", y, ", ", z)
					await get_tree().physics_frame
					await get_tree().physics_frame
					player.global_position = Vector3(x, y, z)
					if player is RigidBody3D:
						player.linear_velocity = Vector3.ZERO
						player.angular_velocity = Vector3.ZERO
					elif player is CharacterBody3D:
						player.velocity = Vector3.ZERO
				else:
					print("Error: 'tp' command requires x, y, and z coordinates (or ~ for current location)")
			"freecam":
				if args.size() == 1:
					if GameManager.player_choice != GameManager.Character.SPECT and not freecamming:
						InputManager.set_can_input(false)
						$FreecamLabel.show()
						freecamming = true
						var freecam = freecam_scene.instantiate()
						freecam.is_freecam = true # Indicate we are freecamming, not spectating.
						freecam.global_position = player.global_position
						get_parent().add_child(freecam)
					else:
						print("Error: Already spectating!")
				else:
					print("Error: 'spectator' command expects no arguments!")
			"simrate":
				if args.size() == 2:
					if GameManager.using_multiplayer:
						print("Error: Cannot change simulation rate in multiplayer!")
						return
					var sim_rate = args[1].to_float()
					if sim_rate > 1000.0:
						print("Sim rate too high; capped to 1000.0")
						sim_rate = 1000.0
					elif sim_rate < 0.1:
						print("Sim rate too low; limited to 0.1")
						sim_rate = 0.1
					# Account for integer division (make sure time scale (float) and TPS (int) are scaled the same!)
					var phys_tick_ratio: float = (Engine.physics_ticks_per_second*(sim_rate / Engine.time_scale))/Engine.physics_ticks_per_second
					if sim_rate != phys_tick_ratio*Engine.time_scale:
						print("Rate adjusted to ", phys_tick_ratio*Engine.time_scale, " due to integer division.")
					Engine.physics_ticks_per_second *= phys_tick_ratio
					Engine.time_scale *= phys_tick_ratio
				else:
					print("Error: 'simrate' command expects one argument!")
			"pause":
				if Input.is_action_just_pressed("pause"):
					get_tree().paused = !get_tree().paused
			_:
				print("Error: Unknown command: ", command)

func _on_command_line_edit_focus_entered():
	InputManager.set_can_input(false)

func _on_command_line_edit_focus_exited():
	if not freecamming:
		InputManager.set_can_input(true)

func _on_toggle_unsafe_mode_pressed():
	unsafe_mode = !unsafe_mode
	if unsafe_mode:
		%ToggleUnsafeMode.text = "Disable Unsafe Mode"
	else:
		%ToggleUnsafeMode.text = "Enable Unsafe Mode"

func _on_mobile_button_1_button_down():
	Input.action_press("generic_action")

func _on_mobile_button_1_button_up():
	Input.action_release("generic_action")
