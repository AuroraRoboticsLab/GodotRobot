extends VehicleBody3D

const ENGINE_FORCE = 1200
const STEERING_FORCE = 1200

var left_front_wheel   : VehicleWheel3D
var left_back_wheel: VehicleWheel3D
var right_front_wheel  : VehicleWheel3D
var right_back_wheel   : VehicleWheel3D

@onready var charge_component = $ChargeComponent
@onready var rear_connector = $ConnectorComponent

@onready var stuck_stalling: bool = false
@onready var stalling: bool = false
@onready var start_stall: float = 0

func _ready():
	# Identify which components we have
	add_to_group("chargeable")
	add_to_group("connectable")
	
	left_front_wheel   = $FrontLeft
	left_back_wheel= $BackLeft
	right_front_wheel  = $FrontRight
	right_back_wheel   = $BackRight
	
	center_of_mass = $CenterOfMass.position

var time = 0
func _physics_process(delta):
	# TODO: Map inputs from numpad to motors of joints.
	time += delta
	
	var engine_force_multiplier: float
	var steering_force_multiplier: float
	
	# Forces are determined as an inverse square of movement speed to
	# put a cap on acceleration (and avoid insanely high speeds).
	
	const max_move_force = 300.0 # Starting (and max) move force
	const move_amp = 15.0 # How quickly does move force fall off with speed?
	var movement_speed = linear_velocity.length()
	engine_force_multiplier = 1.0/((move_amp*movement_speed**2) + (1.0/max_move_force))
	
	const max_turn_force = 15.0 # Starting (and max) turn force
	const turn_amp = 8.0 # How quickly does turn force fall off with speed?
	var rotation_speed = angular_velocity.length()
	steering_force_multiplier = 1.0 / ((turn_amp*rotation_speed**2) + (1.0/max_turn_force))

	# Calculate drive and steer forces.
	var drive_force = Input.get_axis("forward", "backward") * ENGINE_FORCE * delta * engine_force_multiplier
	var steer_force = Input.get_axis("right", "left") * STEERING_FORCE * delta * steering_force_multiplier
	
	# If we have no battery, we can't apply any force!
	#if charge_component.is_dead:
	#	steer_force = 0
	#	drive_force = 0
	
	left_front_wheel.engine_force  = drive_force + steer_force
	left_back_wheel.engine_force = drive_force + steer_force
	right_front_wheel.engine_force = drive_force - steer_force
	right_back_wheel.engine_force = drive_force - steer_force
	
	# This value should be revised; what is a better total force approximation?
	var total_force = abs(drive_force + steer_force/2)
	
	# If we're applying force, we're spending energy!
	var power_spent = 0
	print("force: ", total_force)
	print("move speed: ", movement_speed)
	if movement_speed < 0.03 and total_force > 0.01:
		# We are stalling our motor!
		if not stalling:
			stalling = true
			start_stall = time
			power_spent = 0.4
		else:
			var time_stalling = time - start_stall
			if time_stalling > 4.0:
				stuck_stalling = true
			power_spent = 0.2*time_stalling**2 + 1*time_stalling + 1
			if power_spent >= 32.0:
				power_spent = 32.0
	elif movement_speed >= 0.01:
		stuck_stalling = false
		stalling = false
		power_spent = (total_force * movement_speed) + 0.2
	
	# Elliott's Idea
	#var power_to_velo = total_force / (movement_speed+5)
	#print("Ratio: ", power_to_velo)
	#print("Time: ", time)
	#power_spent = 0.01*(power_to_velo)**2 + 0.01*power_to_velo + 0.2
	#print("Power spent: ", power_spent)
	
	charge_component.change_charge(-power_spent * delta)
	
	# Fly away when pressing space
	if Input.is_action_pressed("jump"):
		linear_velocity += Vector3(0, 5, 0) * delta

# Connector sees another connector nearby
func _on_connector_component_can_connect(area):
	# For now, automatically connect.
	area.do_connect(rear_connector)
	rear_connector.do_connect()

# Connected connector exits range
func _on_connector_component_must_disconnect(area):
	# Disconnect right now.
	area.do_disconnect(rear_connector)
	rear_connector.do_disconnect(area)
