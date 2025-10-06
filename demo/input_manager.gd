# res://singletons/InputManager.gd
extends Node

enum InputSource { KEY_MOUSE, CONTROLLER, TOUCH, AI }
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
var elapsed := 0.0
var change := 0.5
func _process(delta: float) -> void:
	if debugging:
		elapsed += delta
		if elapsed >= change:
			elapsed = 0.0
			print(_input_mode)

func _ready() -> void:
	controller_input.triggered.connect(_on_controller_triggered)
	key_and_mouse_input.triggered.connect(_on_key_and_mouse_triggered)
	touch_input.triggered.connect(_on_touch_triggered)
	#GUIDE.enable_mapping_context.call_deferred(switch_input_source) # Enable when doing key mapping!

func _on_controller_triggered() -> void:
	if debugging:
		print("Controller!")

func _on_key_and_mouse_triggered() -> void:
	if debugging:
		print("Mouse!")

func _on_touch_triggered() -> void:
	if debugging:
		print("Touch!")

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

func set_source_key_mouse() -> void:
	_input_source = InputSource.KEY_MOUSE

func set_source_controller() -> void:
	_input_source = InputSource.CONTROLLER

func set_source_touch() -> void:
	_input_source = InputSource.TOUCH

func set_source_ai() -> void:
	_input_source = InputSource.AI
