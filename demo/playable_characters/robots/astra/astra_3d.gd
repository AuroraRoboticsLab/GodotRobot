extends BaseRobot

const DRIVE_FORCE_MULT = 1200

@onready var left_front_wheel   = $FrontLeft
@onready var left_back_wheel    = $BackLeft
@onready var right_front_wheel  = $FrontRight
@onready var right_back_wheel   = $BackRight

@onready var arm    = $AstraArm3D
@onready var hopper = $AstraHopper3D

@onready var rear_connector =   $ConnectorComponent

@onready var stuck_stalling: bool = false
@onready var stalling: bool = false
@onready var start_stall: float = 0

func _physics_process(delta):
	if GameManager.using_multiplayer and not $PlayerComponent.is_multiplayer_authority():
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
	if Input.is_action_pressed("shift") and InputManager.get_can_input():
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
	
	if GameManager.is_npc:
		# Let player have priority over controls
		if drive_input == 0 or not InputManager.get_can_input():
			drive_input = auto_component.get_drive()
		if steer_input == 0 or not InputManager.get_can_input():
			steer_input = auto_component.get_steer()
		
	if (InputManager.get_can_input() or GameManager.is_npc) and not charge_component.is_dead:
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
	
	charge_component.change_charge(-power_spent * delta)
	
	# Flip over by holding space
	if Input.is_action_pressed("jump") and InputManager.get_can_input() and not GameManager.is_npc:
		angular_velocity += transform.basis * Vector3(0,0,10)*delta
		linear_velocity.y += 1.62 * delta
		#global_position += Vector3(0, tp_height, 0)

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
