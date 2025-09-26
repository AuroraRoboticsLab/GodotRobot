extends Node3D

const SPEED := 3.0
@onready var h_sens := 0.2
@onready var v_sens := 0.2
const cam_v_max := 90
const cam_v_min := -90
var camrot_h := 0.0
var camrot_v := 0.0
var invert_mult := 1

var _invert_cam := false
var invert_cam: bool:
	set(value):
		_invert_cam = value
		if value:
			invert_mult = -1
		else:
			invert_mult = 1
	get:
		return _invert_cam

@export var is_freecam := false
var spawn_trans = null

@export var exit: GUIDEAction
@export var move: GUIDEAction
@export var rotate_camera: GUIDEAction
@export var fast: GUIDEAction
@export var slow: GUIDEAction

func _ready():
	exit.triggered.connect(_on_exit_triggered)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	process_mode = Node.PROCESS_MODE_ALWAYS

	if GameManager.using_multiplayer and not is_freecam:
		set_multiplayer_authority(str(name).to_int())
		if is_multiplayer_authority():
			var cam := Camera3D.new()
			add_child(cam)
			cam.current = true
	else:
		var cam := Camera3D.new()
		add_child(cam)
		cam.current = true

func _on_exit_triggered() -> void:
	if GameManager.player_choice != GameManager.Character.SPECT:
		InputManager.activate_move_mode()
		queue_free()
	else:
		if GameManager.using_multiplayer:
			multiplayer.multiplayer_peer.close()
		GameManager.self_disconnected.emit()
		GameManager.exit_main_scene.emit()

const SENS_MULT := 5

func _process(delta):
	if not is_freecam and GameManager.using_multiplayer and not is_multiplayer_authority():
		return

	# integrate mouse input
	camrot_v += v_sens * SENS_MULT * invert_mult * rotate_camera.value_axis_2d.y
	camrot_h += h_sens * SENS_MULT * rotate_camera.value_axis_2d.x
	camrot_v = clamp(camrot_v, cam_v_min, cam_v_max)

	# absolute assignment (no delta)
	rotation_degrees.y = camrot_h
	rotation_degrees.x = camrot_v

	var direction := (transform.basis * move.value_axis_3d).normalized()

	var speed_mult := 1.0
	if fast.is_triggered() and slow.is_triggered():
		speed_mult = 100.0
	elif slow.is_triggered():
		speed_mult = 0.5
	elif fast.is_triggered():
		speed_mult = 3.0

	global_position += direction * delta * SPEED * speed_mult
