extends CharacterBody3D

const SPEED = 2.0
const JUMP_VELOCITY = 1.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var cam_load = preload("res://components/movable_camera_3d.tscn")
@onready var cam_scene = null

@onready var ext_input = null

@onready var suit = $suit_maxgrueter

var spawn_trans = null

var can_input: bool = true

var nametag_text: String = "unnamed astronaut":
	get:
		return $Nametag.text
	set(value):
		$Nametag.text = value

func _ready():
	GameManager.network_process.connect(_network_process)
	GameManager.toggle_inputs.connect(toggle_inputs)
	
	if GameManager.using_multiplayer:
		$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
		if $MultiplayerSynchronizer.is_multiplayer_authority():
			cam_scene = cam_load.instantiate()
			add_child(cam_scene)
			$Nametag.visible = false # We don't want to see our own nametag
	else:
		cam_scene = cam_load.instantiate()
		add_child(cam_scene)
		$Nametag.visible = false
	
	if not GameManager.using_multiplayer or (GameManager.using_multiplayer and $MultiplayerSynchronizer.is_multiplayer_authority()):
		await get_tree().physics_frame
		await get_tree().physics_frame
		cam_scene.lock_horiz = true
		cam_scene.position = $CameraPosition.position
		global_transform = spawn_trans

func toggle_inputs(in_bool = null):
	if in_bool != null:
		can_input = !can_input
	else:
		can_input = in_bool

func _network_process(_delta):
	if not $MultiplayerSynchronizer.is_multiplayer_authority():
		var player_data = GameManager.get_player_data(str(name).to_int())
		if not player_data:
			return
		global_position = global_position.lerp(player_data.global_position, 0.5)
		set_quaternion(get_quaternion().slerp(player_data.quaternion, 0.5))
		return
	
	var new_player_data = {
		"global_position": global_position,
		"quaternion": get_quaternion(),
	}
	GameManager.add_new_player_data(new_player_data)

func _physics_process(delta):
	if GameManager.using_multiplayer and not $MultiplayerSynchronizer.is_multiplayer_authority():
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		#suit.animation_player.play("BounceTrack")
		velocity.y = JUMP_VELOCITY
	
	rotation_degrees.y = cam_scene.camrot_h * delta * 150
	
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	if ext_input:
		input_dir = ext_input
	
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if global_position.y > 40.0:
		velocity.y = 0 # Undo escape velocity
	
	move_and_slide()
