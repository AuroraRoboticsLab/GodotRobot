extends VehicleBody3D

const DRIVE_FORCE_MULT = 1200

@onready var left_front_wheel   = $FrontLeft
@onready var left_back_wheel    = $BackLeft
@onready var right_front_wheel  = $FrontRight
@onready var right_back_wheel   = $BackRight

@onready var arm    = $AstraArm3D
@onready var hopper = $AstraHopper3D

@onready var charge_component = $ChargeComponent
@onready var rear_connector =   $ConnectorComponent

@onready var stuck_stalling: bool = false
@onready var stalling: bool = false
@onready var start_stall: float = 0

@onready var ext_input = null

@onready var tp_height: float = 1.0

@onready var auto_component = $AutonomyComponent

@onready var cam_load = preload("res://components/movable_camera_3d.tscn")
@onready var cam_scene = null

var spawn_trans = null

var can_input: bool = true

@export var nametag_text: String = "unnamed robot":
	get:
		return $Nametag.text
	set(value):
		$Nametag.text = value

func _ready():
	arm.auto_component = auto_component
	
	GameManager.network_process.connect(_network_process)
	GameManager.toggle_inputs.connect(toggle_inputs)
	
	center_of_mass = $CenterOfMass.position
	
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

func toggle_inputs(in_bool = null):
	if in_bool == null:
		can_input = !can_input
	else:
		can_input = in_bool

func _network_process(_delta):
	# This client is a player we do not control
	if not $MultiplayerSynchronizer.is_multiplayer_authority():
		var player_data = GameManager.get_player_data(str(name).to_int())
		if not player_data:
			return
		global_position = global_position.lerp(player_data.global_position, 0.5)
		linear_velocity = linear_velocity.lerp(player_data.linear_velocity, 0.5)
		angular_velocity = angular_velocity.lerp(player_data.angular_velocity, 0.5)
		set_quaternion(get_quaternion().slerp(player_data.quaternion, 0.5))
		charge_component.remaining_amp_hours = player_data.remaining_amp_hours
		return
	
	var new_player_data = {
		"global_position": global_position,
		"linear_velocity": linear_velocity,
		"angular_velocity": angular_velocity,
		"quaternion": get_quaternion(),
		"remaining_amp_hours": charge_component.remaining_amp_hours,
	}
	GameManager.add_new_player_data(new_player_data)

func _physics_process(delta):
	if GameManager.using_multiplayer and not $MultiplayerSynchronizer.is_multiplayer_authority():
		return
	
	#*** DRIVING LOGIC ***#
	var engine_force_multiplier: float
	var steering_force_multiplier: float
	
	# Forces are determined as an inverse square of movement speed to
	# put a cap on acceleration (and avoid insanely high speeds).
	const max_move_force = 40.0 # Starting (and max) move force
	const move_amp = 5.0 # How quickly does move force fall off with speed?
	var movement_speed = linear_velocity.length()
	
	engine_force_multiplier = 2.0/((move_amp*movement_speed**2) + (1.0/max_move_force))
	
	# Turbo ultra racing mode
	if Input.is_action_pressed("shift") and can_input:
		engine_force_multiplier = 4.0*(sqrt(abs(movement_speed)) + 2)
	
	const max_turn_force = 30.0 # Starting (and max) turn force
	const turn_amp = 3.0 # How quickly does turn force fall off with speed?
	var rotation_speed = angular_velocity.length()
	steering_force_multiplier = 1.0 / ((turn_amp*rotation_speed**2) + (1.0/max_turn_force))

	# Calculate drive and steer forces.
	var drive_force = 0
	var steer_force = 0
	var drive_input = Input.get_axis("forward", "backward")
	var steer_input = Input.get_axis("right", "left")
	
	if ext_input:
		drive_input = ext_input.y
		steer_input = -ext_input.x
	elif GameManager.is_npc:
		# Let player have priority over controls
		if drive_input == 0 or not can_input:
			drive_input = auto_component.get_drive()
		if steer_input == 0 or not can_input:
			steer_input = auto_component.get_steer()
		
	if (can_input or GameManager.is_npc) and not charge_component.is_dead:
		drive_force = drive_input * 2 * DRIVE_FORCE_MULT * delta * engine_force_multiplier
		steer_force = steer_input * 2 * DRIVE_FORCE_MULT * delta * steering_force_multiplier
	
	var my_dir = -transform.basis.z.normalized()
	var my_vel = linear_velocity.normalized()
	if not linear_velocity.length_squared() < 0.01 and my_dir.dot(my_vel) < -0.9 and drive_input < 0:
		# We're trying to go forwards but are moving backwards
		drive_force = 0
	if not linear_velocity.length_squared() < 0.01 and my_dir.dot(my_vel) > 0.9 and drive_input > 0:
		# We're trying to go backwards but are moving forwards
		drive_force = 0
	
	left_front_wheel.engine_force  = drive_force + steer_force
	left_back_wheel.engine_force = drive_force + steer_force
	right_front_wheel.engine_force = drive_force - steer_force
	right_back_wheel.engine_force = drive_force - steer_force
	
	# This value should be revised; what is a better total force approximation?
	var total_drive_force = abs(drive_force + steer_force/2)
	
	# If we're applying force, we're spending energy!
	var power_spent = 0
	const stall_torque = 0.161 * 500
	var total_torque = 0.161 * total_drive_force
	power_spent = 100 * (total_torque / stall_torque) * 4 # four wheels
	# Stalling logic
	if total_torque > stall_torque:
		if not stalling:
			start_stall = GameManager.time
			stalling = true
		if GameManager.time - start_stall > 1.0:
			stuck_stalling = true
	else:
		stalling = false
		stuck_stalling = false
	
	arm.is_dead = charge_component.is_dead
	hopper.is_dead = charge_component.is_dead
	
	#power_spent += (abs(arm_force) + abs(bollard_force) + abs(tilt_force) + abs(hopper_force))
	
	charge_component.change_charge(-power_spent * delta)
	
	# Fly away when pressing space
	if Input.is_action_just_pressed("jump") and can_input and not GameManager.is_npc:
		linear_velocity = Vector3.ZERO
		global_position += Vector3(0, tp_height, 0)

# Rear connector sees another connector nearby. What happens?
func _on_connector_component_can_connect(area):
	# For now, automatically connect to any chargeable connector.
	if area is Connector and area.charge_component:
		area.do_connect(rear_connector)
		rear_connector.do_connect()

# Connected connector exits range, so what things happen
# when we disconnect?
func _on_connector_component_must_disconnect(area):
	# Disconnect right now.
	if rear_connector.connected:
		area.do_disconnect(rear_connector)
		rear_connector.do_disconnect(area)
