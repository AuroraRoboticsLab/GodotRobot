extends Control

var current_button : Button
var current_idx: int
@onready var set_bind_panel : PanelContainer = $PanelContainer/SetBindOverlay

var actions = ["arm_up",
			   "arm_down",
			   "bollard_curl",
			   "bollard_dump",
			   "tilt_left",
			   "tilt_right",
			   "hopper_open",
			   "hopper_close",
			   "forward",
			   "backward",
			   "left",
			   "right",
			   "generic_action",
			   "action1",
			   "jump",
			   "shift",
			   "dpad_up",
			   "dpad_down",
			   "dpad_left",
			   "dpad_right",
			  ]
var keyboard_buttons   = []
var controller_buttons = []

func _ready() -> void:
	# Connect the button pressed signals
	var keybind_grid_children = %KeybindGrid.get_children()
	for idx in range((int(%KeybindGrid.get_child_count())-3)/3):
		# Keyboard assign buttons
		var curr_button_key = keybind_grid_children[idx*3+4]
		keyboard_buttons.append(curr_button_key) # Add to list of keyboard buttons
		curr_button_key.pressed.connect(_on_button_pressed.bind(curr_button_key, idx))
		# Controller assign buttons
		var curr_button_cont = keybind_grid_children[idx*3+5]
		controller_buttons.append(curr_button_cont) # Add to list of controller buttons
		curr_button_cont.pressed.connect(_on_button_pressed.bind(curr_button_cont, idx))
	
	_update_labels()
	
# Whenever a button is pressed, do:
func _on_button_pressed(button: Button, button_idx: int) -> void:
	current_button = button
	current_idx = button_idx
	set_bind_panel.show()

func _input(event: InputEvent) -> void:
	if not current_button or not visible:
		return
	
	if event is InputEventMouse:
		return
	
	if event.as_text() == "Escape":
		current_button = null
		set_bind_panel.hide()
		return
	
	if current_button in keyboard_buttons and not event is InputEventKey:
		return
	if current_button in controller_buttons and not (event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return
	
	var curr_action = actions[current_idx]
	# This part is for deleting duplicate assignments:
	# Add all assigned keys to a dictionary
	var all_input_events = {}
	for input_action in InputMap.get_actions():
		for input_action_event in InputMap.action_get_events(input_action):
			all_input_events[input_action_event.as_text()] = input_action
	
	# check if the new key is already in the dict.
	# If yes, delete the old one.
	if all_input_events.keys().has(event.as_text()):
		InputMap.action_erase_event(all_input_events[event.as_text()], event)
	
	# We are binding on a keyboard
	if current_button in keyboard_buttons and event is InputEventKey:
		var curr_event = null
		for set_event in InputMap.action_get_events(curr_action):
			if set_event is InputEventKey:
				curr_event = set_event
				print("Event changed from: ", curr_event.as_text())
		if curr_event:
			InputMap.action_erase_event(curr_action, curr_event)
		# Assign the new event to it
		InputMap.action_add_event(curr_action, event)
		print("to: ", event.as_text())
	# We are binding on a controller
	elif current_button in controller_buttons and (event is InputEventJoypadButton or event is InputEventJoypadMotion):
		if event is InputEventJoypadMotion and abs(event.axis_value) < 0.5:
			return # Controller binding deadzone for joysticks
		if event is InputEventJoypadMotion:
			event.axis_value = 1.0 if event.axis_value > 0 else -1.0 # Make sure we bind with full strenght
		var curr_event = null
		for set_event in InputMap.action_get_events(curr_action):
			if set_event is InputEventJoypadButton or set_event is InputEventJoypadMotion:
				curr_event = set_event
				print("Event changed from: ", curr_event.as_text())
				break
		if curr_event:
			InputMap.action_erase_event(curr_action, curr_event)
		# Assign the new event to it
		InputMap.action_add_event(curr_action, event)
		print("to: ", event.as_text())
	
	current_button = null
	set_bind_panel.hide()
	_update_labels()
		
func _update_labels() -> void:
	for idx in range(len(actions)):
		var binds : Array[InputEvent] = InputMap.action_get_events(actions[idx])
		
		# Set keyboard button labels
		var bind = null
		for set_bind in binds:
			if set_bind is InputEventKey:
				bind = set_bind
		if bind:
			keyboard_buttons[idx].text = bind.as_text()
		else:
			keyboard_buttons[idx].text = "Unbound"
		
		# Set controller button labels
		bind = null
		for set_bind in binds:
			if set_bind is InputEventJoypadButton or set_bind is InputEventJoypadMotion:
				bind = set_bind
				#print("Set bind to ", bind.as_text(), "!")
		if bind:
			#print("Setting controller bind to ", bind.as_text())
			controller_buttons[idx].text = bind.as_text()
		else:
			controller_buttons[idx].text = "Unbound"
		
func _on_exit_button_pressed():
	GameManager.toggle_inputs.emit(true)
	hide()
