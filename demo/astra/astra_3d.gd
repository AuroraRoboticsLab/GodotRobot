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

@onready var tp_height: float = 1.0
@export var is_npc: bool = false

@onready var cam_load = preload("res://components/movable_camera_3d.tscn")
@onready var cam_scene = null

var sync_pos = Vector3.ZERO
var sync_rot = Quaternion.IDENTITY

var can_input: bool = true

var nametag_text: String = "unnamed robot":
	get:
		return $Nametag.text
	set(value):
		$Nametag.text = value

func _ready():
	# Identify which components we have
	add_to_group("chargeable")
	add_to_group("connectable")
	add_to_group("player")
	
	GameManager.toggle_inputs.connect(toggle_inputs)
	
	center_of_mass = $CenterOfMass.position
	
	if GameManager.using_multiplayer:
		$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
		if not is_npc and $MultiplayerSynchronizer.is_multiplayer_authority():
			cam_scene = cam_load.instantiate()
			add_child(cam_scene)
			$Nametag.visible = false # We don't want to see our own nametag
	else:
		cam_scene = cam_load.instantiate()
		add_child(cam_scene)
		$Nametag.visible = false

func toggle_inputs():
	can_input = !can_input

var time = 0
func _physics_process(delta):
	if GameManager.using_multiplayer and not $MultiplayerSynchronizer.is_multiplayer_authority():
		global_position = global_position.lerp(sync_pos, 0.5)
		set_quaternion(get_quaternion().slerp(sync_rot, 0.5))
		return
	
	time += delta
	sync_pos = global_position
	sync_rot = get_quaternion()
	
	#*** DRIVING LOGIC ***#
	var engine_force_multiplier: float
	var steering_force_multiplier: float
	
	# Forces are determined as an inverse square of movement speed to
	# put a cap on acceleration (and avoid insanely high speeds).
	const max_move_force = 20.0 # Starting (and max) move force
	const move_amp = 15.0 # How quickly does move force fall off with speed?
	var movement_speed = linear_velocity.length()
	
	engine_force_multiplier = 2.0/((move_amp*movement_speed**2) + (1.0/max_move_force))
	
	# Turbo ultra racing mode
	if Input.is_action_pressed("shift") and can_input:
		engine_force_multiplier = sqrt(abs(movement_speed))/1.5 + 2
	
	const max_turn_force = 15.0 # Starting (and max) turn force
	const turn_amp = 8.0 # How quickly does turn force fall off with speed?
	var rotation_speed = angular_velocity.length()
	steering_force_multiplier = 1.0 / ((turn_amp*rotation_speed**2) + (1.0/max_turn_force))

	# Calculate drive and steer forces.
	var drive_force = 0
	var steer_force = 0
	if can_input and not charge_component.is_dead:
		drive_force = Input.get_axis("forward", "backward") * DRIVE_FORCE_MULT * delta * engine_force_multiplier
		steer_force = Input.get_axis("right", "left") * 2 * DRIVE_FORCE_MULT * delta * steering_force_multiplier
		
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
			start_stall = time
			stalling = true
		if time - start_stall > 1.0:
			stuck_stalling = true
	else:
		stalling = false
		stuck_stalling = false
	
	arm.is_dead = charge_component.is_dead
	hopper.is_dead = charge_component.is_dead
	
	#power_spent += (abs(arm_force) + abs(bollard_force) + abs(tilt_force) + abs(hopper_force))
	
	charge_component.change_charge(-power_spent * delta)
	
	# Fly away when pressing space
	if Input.is_action_just_pressed("jump") and can_input:
		linear_velocity = Vector3.ZERO
		global_position += Vector3(0, tp_height, 0)

# Rear connector sees another connector nearby. What happens?
func _on_connector_component_can_connect(area):
	# For now, automatically connect to any chargeable connector.
	if area.is_in_group("connector") and area.parent.is_in_group("chargeable"):
		area.do_connect(rear_connector)
		rear_connector.do_connect()

# Connected connector exits range, so what things happen
# when we disconnect?
func _on_connector_component_must_disconnect(area):
	# Disconnect right now.
	if rear_connector.connected:
		area.do_disconnect(rear_connector)
		rear_connector.do_disconnect(area)
