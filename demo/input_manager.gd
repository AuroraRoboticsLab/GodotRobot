# res://singletons/InputManager.gd
extends Node

enum InputSource { HUMAN, AI }
var _input_source: InputSource = InputSource.HUMAN

enum InputMode { NONE, MOVE, FREECAM }
var _input_mode: InputMode = InputMode.NONE

@export var move_mode: GUIDEMappingContext = preload("res://guide_actions/move_mode/move_mode.tres")
@export var freecam_mode: GUIDEMappingContext = preload("res://guide_actions/freecam_mode/freecam_mode.tres")

# -------- Input Modes --------
func set_relevant_mode() -> void:
	match _input_mode:
		InputMode.MOVE:
			print("Moving!")
			disable_input_modes()
			GUIDE.enable_mapping_context(move_mode)
		InputMode.FREECAM:
			print("Freecamming!")
			disable_input_modes()
			GUIDE.enable_mapping_context(freecam_mode)
		InputMode.NONE:
			print("Nothing!")
			disable_input_modes()

func activate_freecam_mode() -> void:
	match _input_mode:
		InputMode.MOVE:
			_prev_mode = _input_mode
			_input_mode = InputMode.FREECAM
			set_relevant_mode()
		InputMode.NONE:
			_prev_mode = _input_mode
			_input_mode = InputMode.FREECAM
			set_relevant_mode()

func in_freecam_mode() -> bool:
	return _input_mode == InputMode.FREECAM

func activate_move_mode() -> void:
	match _input_mode:
		InputMode.FREECAM:
			_prev_mode = _input_mode
			_input_mode = InputMode.MOVE
			set_relevant_mode()
		InputMode.NONE:
			_prev_mode = _input_mode
			_input_mode = InputMode.MOVE
			set_relevant_mode()

func in_move_mode() -> bool:
	print(_input_mode)
	return _input_mode == InputMode.MOVE

func disable_input_modes() -> void:
	GUIDE.disable_mapping_context(freecam_mode)
	GUIDE.disable_mapping_context(move_mode)
	_input_mode = InputMode.NONE

var _prev_mode: InputMode = InputMode.NONE
func activate_prev_mode() -> void:
	if _prev_mode == InputMode.NONE:
		return
	var prev_prev_mode = _input_mode
	_input_mode = _prev_mode
	_prev_mode = prev_prev_mode
	set_relevant_mode()

# -------- AI / Autonomy --------

func set_source_human() -> void:
	_input_source = InputSource.HUMAN

func set_source_ai() -> void:
	_input_source = InputSource.AI
