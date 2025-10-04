# res://singletons/InputManager.gd
extends Node

enum InputSource { HUMAN, AI }
var _input_source: InputSource = InputSource.HUMAN

enum InputMode { NONE, MOVE, FREECAM }
var _input_mode: InputMode = InputMode.NONE

@export var move_mode: GUIDEMappingContext = preload("res://guide_actions/move_mode/move_mode.tres")
@export var freecam_mode: GUIDEMappingContext = preload("res://guide_actions/freecam_mode/freecam_mode.tres")

var elapsed = 0.0
var change = 0.5
func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= change:
		elapsed = 0.0
		print(_input_mode)

# -------- Input Modes --------
func set_relevant_mode() -> void:
	_clear_mapping_contexts()
	match _input_mode:
		InputMode.MOVE:
			print("Moving!")
			GUIDE.enable_mapping_context(move_mode)
		InputMode.FREECAM:
			print("Freecamming!")
			GUIDE.enable_mapping_context(freecam_mode)
		InputMode.NONE:
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

# -------- AI / Autonomy --------

func set_source_human() -> void:
	_input_source = InputSource.HUMAN

func set_source_ai() -> void:
	_input_source = InputSource.AI
