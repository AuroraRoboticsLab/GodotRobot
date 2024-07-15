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
			  ]

func _ready() -> void:
	# Connect the button pressed signals
	var keybind_grid_children = %KeybindGrid.get_children()
	for idx in range(int(%KeybindGrid.get_child_count())/2):
		var curr_button = keybind_grid_children[idx * 2]
		curr_button.pressed.connect(_on_button_pressed.bind(curr_button, idx*2))
	
	_update_labels()
	
# Whenever a button is pressed, do:
func _on_button_pressed(button: Button, button_idx: int) -> void:
	current_button = button
	current_idx = button_idx
	set_bind_panel.show()

func _input(event: InputEvent) -> void:
	if not current_button or not visible:
		return
	
	var curr_action = actions[int(current_idx)/2]
	
	if event is InputEventKey or event is InputEventMouseButton:
		
		# This part is for deleting duplicate assignments:
		# Add all assigned keys to a dictionary
		var all_ies : Dictionary = {}
		for ia in InputMap.get_actions():
			for iae in InputMap.action_get_events(ia):
				all_ies[iae.as_text()] = ia
		
		# check if the new key is already in the dict.
		# If yes, delete the old one.
		if all_ies.keys().has(event.as_text()):
			InputMap.action_erase_events(all_ies[event.as_text()])
		
		# This part is where the actual remapping occures:
		# Erase the event in the Input map
		InputMap.action_erase_events(curr_action)
		# And assign the new event to it
		InputMap.action_add_event(curr_action, event)
		
		# After a key is assigned, set current_button back to null
		current_button = null
		set_bind_panel.hide() # hide the info panel again
		
		_update_labels() # refresh the labels
		
func _update_labels() -> void:
	var keybind_grid_children = %KeybindGrid.get_children()
	
	for idx in range(int(%KeybindGrid.get_child_count())/2):
		var button_idx = idx * 2
		var bind : Array[InputEvent] = InputMap.action_get_events(actions[idx])
		var label = keybind_grid_children[button_idx + 1]
		if !bind.is_empty():
			label.text = bind[0].as_text()
		else:
			label.text = ""

func _on_exit_button_pressed():
	GameManager.toggle_inputs.emit()
	hide()
