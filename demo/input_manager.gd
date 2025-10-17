# res://singletons/InputManager.gd
extends Node

enum InputSource { KEY_MOUSE, CONTROLLER }
var _input_source: InputSource = InputSource.KEY_MOUSE

enum InputMode { NONE, MOVE, FREECAM }
var _input_mode: InputMode = InputMode.NONE

@export var move_mode: GUIDEMappingContext = preload("res://guide_actions/move_mode/move_mode.tres")
@export var freecam_mode: GUIDEMappingContext = preload("res://guide_actions/freecam_mode/freecam_mode.tres")
@export var switch_input_source: GUIDEMappingContext = preload("res://guide_actions/switch_input_source.tres")

@export var controller_input: GUIDEAction = preload("res://guide_actions/global_controller.tres")
@export var key_and_mouse_input: GUIDEAction = preload("res://guide_actions/global_keyboard_and_mouse.tres")
@export var touch_input: GUIDEAction = preload("res://guide_actions/global_touch.tres")

var debugging := false
var input_mode_elapsed := 0.0
var input_mode_change := 0.5
var sim_move_elapsed := 0.0
var sim_move_change := 2.0
func _process(delta: float) -> void:
	if debugging:
		input_mode_elapsed += delta
		sim_move_elapsed += delta
		if input_mode_elapsed >= input_mode_change and false:
			input_mode_elapsed = 0.0
			print(_input_mode)
		if sim_move_elapsed >= sim_move_change and false:
			print("press!")
			sim_move_elapsed = 0.0
			simulate_key_press(KEY_W, 1.0)
		

func _ready() -> void:
	controller_input.triggered.connect(_on_controller_triggered)
	key_and_mouse_input.triggered.connect(_on_key_and_mouse_triggered)
	touch_input.triggered.connect(_on_touch_triggered)
	GUIDE.enable_mapping_context.call_deferred(switch_input_source)

# -------- Game Modes --------

func set_relevant_mode() -> void:
	_clear_mapping_contexts()
	match _input_mode:
		InputMode.MOVE:
			if debugging:
				print("Moving!")
			GUIDE.enable_mapping_context(move_mode)
		InputMode.FREECAM:
			if debugging:
				print("Freecamming!")
			GUIDE.enable_mapping_context(freecam_mode)
		InputMode.NONE:
			if debugging:
				print("Nothing!")

func activate_freecam_mode() -> void:
	if _input_mode == InputMode.FREECAM:
		return
	var previous_mode := _input_mode
	_input_mode = InputMode.FREECAM
	if previous_mode != InputMode.NONE:
		_prev_mode = previous_mode
	set_relevant_mode()

func in_freecam_mode() -> bool:
	return _input_mode == InputMode.FREECAM

func activate_move_mode() -> void:
	if _input_mode == InputMode.MOVE:
		return
	var previous_mode := _input_mode
	_input_mode = InputMode.MOVE
	if previous_mode != InputMode.NONE:
		_prev_mode = previous_mode
	set_relevant_mode()

func in_move_mode() -> bool:
	return _input_mode == InputMode.MOVE

func _clear_mapping_contexts() -> void:
	GUIDE.disable_mapping_context(freecam_mode)
	GUIDE.disable_mapping_context(move_mode)

func disable_input_modes() -> void:
	if _input_mode != InputMode.NONE:
		_prev_mode = _input_mode
	_clear_mapping_contexts()
	_input_mode = InputMode.NONE

var _prev_mode: InputMode = InputMode.NONE
func activate_prev_mode() -> void:
	if _prev_mode == InputMode.NONE:
		return
	var previous_mode := _input_mode
	_input_mode = _prev_mode
	set_relevant_mode()
	_prev_mode = previous_mode

# -------- Input Sources --------

signal new_input_source(input_source: InputSource)

func _on_controller_triggered() -> void:
	if _input_source != InputSource.CONTROLLER:
		set_source_controller()
		if debugging:
			print("Controller!")
func is_using_controller() -> bool:
	return _input_source == InputSource.CONTROLLER

func _on_key_and_mouse_triggered() -> void:
	if _input_source != InputSource.KEY_MOUSE:
		set_source_key_mouse()
		if debugging:
			print("Mouse!")
func is_using_key_and_mouse() -> bool:
	return _input_source == InputSource.KEY_MOUSE

signal touch_detected
func _on_touch_triggered() -> void:
	touch_detected.emit()

func get_input_source_type() -> InputSource:
	return _input_source

func set_source_key_mouse() -> void:
	_input_source = InputSource.KEY_MOUSE
	new_input_source.emit(_input_source)

func set_source_controller() -> void:
	_input_source = InputSource.CONTROLLER
	new_input_source.emit(_input_source)

# -------- Simulated Inputs --------

func simulate_key_press(key: Key, press_time: float = 0.25) -> void:
	simulate_key_down(key) # press
	await get_tree().create_timer(press_time).timeout # wait
	simulate_key_up(key) # release

func simulate_key_down(key: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = key
	ev.physical_keycode = key
	ev.pressed = true
	ev.device = -1
	Input.parse_input_event(ev)

func simulate_joystick(in_axis: Vector2, left_stick: bool) -> void:
	var ev_x := InputEventJoypadMotion.new()
	var ev_y := InputEventJoypadMotion.new()
	ev_x.axis_value = in_axis.x
	ev_y.axis_value = in_axis.y
	ev_x.axis = JOY_AXIS_LEFT_X if left_stick else JOY_AXIS_RIGHT_X
	ev_y.axis = JOY_AXIS_LEFT_Y if left_stick else JOY_AXIS_RIGHT_Y
	Input.parse_input_event(ev_x)
	Input.parse_input_event(ev_y)

func simulate_key_up(key: Key) -> void:
	var ev_up := InputEventKey.new()
	ev_up.physical_keycode = key
	ev_up.pressed = false
	Input.parse_input_event(ev_up)
