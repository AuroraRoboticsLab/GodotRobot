extends Node3D

const SPEED = 3.0 # m/s

@onready var h_sens = 0.2 # Horizontal sensitivity
@onready var v_sens = 0.2 # Vertical sensitivity
const cam_v_max = 50 # Max vertical camera angle (lower bound)
const cam_v_min = -50 # Min vertical camera angle (upper bound)
var camrot_h: float = 0.0
var camrot_v: float = 0.0
var invert_mult = 1
@onready var invert_cam: bool = false:
	set(value):
		if value:
			invert_mult = -1
		else:
			invert_mult = 1
		invert_cam = value
@onready var ext_input = null

var spawn_trans = null

func _input(event):
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("right_click") or (OS.get_name() == "Android" and Input.is_action_pressed("left_click")):
			camrot_h -= event.relative.x * h_sens
			camrot_v -= event.relative.y * v_sens * invert_mult

func _ready():
	if GameManager.using_multiplayer:
		$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
		if $MultiplayerSynchronizer.is_multiplayer_authority():
			var cam = Camera3D.new()
			add_child(cam)
			cam.current = true
	else:
		var cam = Camera3D.new()
		add_child(cam)
		cam.current = true

const SENS_MULT = 5
func _physics_process(delta):
	if GameManager.using_multiplayer and not $MultiplayerSynchronizer.is_multiplayer_authority():
		return
	
	if Input.is_action_pressed("escape"):
		if GameManager.player_choice != GameManager.Character.SPECTATOR:
			GameManager.toggle_inputs.emit(true)
			queue_free()
	
	if Input.is_action_pressed("dpad_up"):
		camrot_v -= v_sens * SENS_MULT * invert_mult
	if Input.is_action_pressed("dpad_down"):
		camrot_v += v_sens * SENS_MULT * invert_mult
	if Input.is_action_pressed("dpad_left"):
		camrot_h -= h_sens * SENS_MULT
	if Input.is_action_pressed("dpad_right"):
		camrot_h += h_sens * SENS_MULT
	
	var input = Input.get_vector("left", "right", "forward", "backward")
	if ext_input:
		input = ext_input
	var direction = (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	
	# Camera movement logic
	camrot_v = clamp(camrot_v, cam_v_min, cam_v_max)
	rotation_degrees.y = camrot_h * delta * 150
	rotation_degrees.x = camrot_v * delta * 150
	
	var speed_mult = 1
	if Input.is_action_pressed("down"):
		speed_mult = 0.5
	if Input.is_action_pressed("shift"):
		speed_mult = 3
	
	global_position += direction * delta * SPEED * speed_mult
