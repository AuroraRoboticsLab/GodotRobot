# res://singletons/InputManager.gd
extends Node

enum Source { HUMAN, AI }

var source: Source = Source.HUMAN
var _can_input: bool = true

# Continuous intents
var _move_vec := Vector2.ZERO
var _look_vec := Vector2.ZERO

# Button states (true while held)
var _jump := false
var _interact := false

func _physics_process(_dt: float) -> void:
	if not _can_input:
		_clear_intents()
		return

	if source == Source.HUMAN:
		_move_vec = Input.get_vector("left", "right", "forward", "backward")
		# _look_vec = Input.get_vector("look_left","look_right","look_up","look_down")
	elif source == Source.AI:
		pass

func _unhandled_input(event: InputEvent) -> void:
	if not _can_input or source != Source.HUMAN:
		return

	if event.is_action_pressed("up"):
		_jump = true
	elif event.is_action_released("up"):
		_jump = false

	if event.is_action_pressed("generic_action"):
		_interact = true
	elif event.is_action_released("generic_action"):
		_interact = false

	# If using mouse look, you could accumulate here:
	# if event is InputEventMouseMotion:
	# 	_look_vec += event.relative

# -------- AI / Autonomy --------

func set_source_human() -> void:
	source = Source.HUMAN

func set_source_ai() -> void:
	source = Source.AI

func ai_set_state(move: Vector2, look: Vector2, jump: bool, interact: bool) -> void:
	source = Source.AI
	if not _can_input:
		_clear_intents()
		return
	_move_vec = move
	_look_vec = look
	_jump = jump
	_interact = interact

# -------- Gate --------

func set_can_input(v: bool) -> void:
	_can_input = v
	if not v:
		_clear_intents()

# -------- Getters (poll from actors) --------

func get_move_vec() -> Vector2:
	return _move_vec if _can_input else Vector2.ZERO

func get_look_vec() -> Vector2:
	return _look_vec if _can_input else Vector2.ZERO

func is_jump_down() -> bool:
	return _can_input and _jump

func is_interact_down() -> bool:
	return _can_input and _interact

func get_can_input() -> bool:
	return _can_input

# -------- Utils --------

func _clear_intents() -> void:
	_move_vec = Vector2.ZERO
	_look_vec = Vector2.ZERO
	_jump = false
	_interact = false
