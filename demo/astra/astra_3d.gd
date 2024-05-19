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

func _ready():
	# Identify which components we have
	add_to_group("chargeable")
	add_to_group("connectable")
	
	center_of_mass = $CenterOfMass.position

var time = 0
func _physics_process(delta):
	# TODO: Map inputs from numpad to motors of joints.
	time += delta
	
	#*** DRIVING LOGIC ***#
	var engine_force_multiplier: float
	var steering_force_multiplier: float
	
	# Forces are determined as an inverse square of movement speed to
	# put a cap on acceleration (and avoid insanely high speeds).
	const max_move_force = 20.0 # Starting (and max) move force
	const move_amp = 15.0 # How quickly does move force fall off with speed?
	var movement_speed = linear_velocity.length()
	
	engine_force_multiplier = 1.0/((move_amp*movement_speed**2) + (1.0/max_move_force))
	
	const max_turn_force = 15.0 # Starting (and max) turn force
	const turn_amp = 8.0 # How quickly does turn force fall off with speed?
	var rotation_speed = angular_velocity.length()
	steering_force_multiplier = 1.0 / ((turn_amp*rotation_speed**2) + (1.0/max_turn_force))

	# Calculate drive and steer forces.
	var drive_force = Input.get_axis("forward", "backward") * DRIVE_FORCE_MULT * delta * engine_force_multiplier
	var steer_force = Input.get_axis("right", "left") * DRIVE_FORCE_MULT * delta * steering_force_multiplier
	
	# If we have no battery, we can't apply any force!
	if charge_component.is_dead:
		steer_force = 0
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
	if Input.is_action_just_pressed("jump"):
		linear_velocity = Vector3.ZERO
		global_position += Vector3(0, tp_height, 0)


# Connector logic. Very simple, because the connector component
# handles most of it!

# Rear connector sees another connector nearby. What happens?
func _on_connector_component_can_connect(area):
	# For now, automatically connect to any connector.
	# Can do a check: Is the body for data? For power?
	# A new tool/attachment? Behavior can differ depending.
	area.do_connect(rear_connector)
	rear_connector.do_connect()

# Connected connector exits range, so what things happen
# when we disconnect?
func _on_connector_component_must_disconnect(area):
	# Disconnect right now.
	area.do_disconnect(rear_connector)
	rear_connector.do_disconnect(area)
