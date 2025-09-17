extends CharacterBody3D

const SPEED = 1.5
const JUMP_VELOCITY = 1.25

# Helper variables from PlayerComponent
@onready var player_component: PlayerComponent = $PlayerComponent
#@onready var charge_component: ChargeComponent = $ChargeComponent
@onready var spawn_trans: Transform3D = $PlayerComponent.spawn_trans:
	set(value):
		spawn_trans = value
		$PlayerComponent.spawn_trans = value
@export var nametag_text: String = "unnamed astronaut":
	set(value):
		$PlayerComponent.nametag_text = value
		nametag_text = value
@onready var cam_scene = $PlayerComponent.cam_scene

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var suit = $suit_maxgrueter

func _ready():
	GameManager.network_process.connect(_network_process)

func _network_process(_delta):
	if not $PlayerComponent.is_multiplayer_authority():
		var player_data = GameManager.get_player_data(str(name).to_int())
		if not player_data:
			return
		global_position = global_position.lerp(player_data.global_position, 0.5)
		set_quaternion(get_quaternion().slerp(player_data.quaternion, 0.5))
		input_dir = input_dir.lerp(player_data.linear_velocity, 0.5)
		suit.jumping = player_data.jumping
		jumping = player_data.jumping
		suit.walking = player_data.walking
		return
	
	var new_player_data = {
		"global_position": global_position,
		"quaternion": get_quaternion(),
		"linear_velocity": input_dir,
		"walking": suit.walking,
		"jumping": suit.jumping
	}
	GameManager.add_new_player_data(new_player_data)

var input_dir = Vector3.ZERO
var jumping = false # Are we jumping?
func _physics_process(delta):
	if GameManager.using_multiplayer and not $PlayerComponent.is_multiplayer_authority():
		if input_dir != Vector3.ZERO:
			suit.move_feet(Vector2(0, input_dir.y))
		else:
			suit.stop_feet()
		return
	
	suit.jumping = jumping
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y <= 0:
		# We're not jumping if we're on the floor!
		jumping = false

	# Handle jump.
	if InputManager.get_can_input() and Input.is_action_just_pressed("jump") and is_on_floor():
		#suit.animation_player.play("BounceTrack")
		#suit.stop_feet()
		jumping = true
		velocity.y = JUMP_VELOCITY
	
	if InputManager.get_can_input():
		rotation_degrees.y = cam_scene.camrot_h * delta * 150
	
	var new_input_dir = Input.get_axis("forward", "backward")
	input_dir = Vector3(0, new_input_dir, 0)
	if jumping or not InputManager.get_can_input():
		input_dir = Vector3.ZERO
	
	# No input_dir.x; Astronauts don't seem to be able to strafe on the moon.
	var direction = (transform.basis * Vector3(0, 0, input_dir.y)).normalized()
	if direction:
		var speed_mult = 1
		if not input_dir.y < 0:
			speed_mult = 0.65 # Move slower when not going straight forwards.
		
		velocity.x = lerp(velocity.x, direction.x * SPEED * speed_mult, 0.1)
		velocity.z = lerp(velocity.z, direction.z * SPEED * speed_mult, 0.1)
		
		# Walk feet in direction of movement
		suit.move_feet(Vector3(0, input_dir.y, 0))
	elif not direction and not jumping:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if not direction:
		suit.stop_feet()
	
	move_and_slide()
