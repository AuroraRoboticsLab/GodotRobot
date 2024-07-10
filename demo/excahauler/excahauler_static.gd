extends VehicleBody3D

const ENGINE_FORCE = 1200
const STEERING_FORCE = 600

var left_front_wheel   : VehicleWheel3D
var left_middle_wheel  : VehicleWheel3D
var left_back_wheel    : VehicleWheel3D
var right_front_wheel  : VehicleWheel3D
var right_middle_wheel : VehicleWheel3D
var right_back_wheel   : VehicleWheel3D

@onready var charge_component = $ChargeComponent

func _ready():
	# Identify which components we have
	add_to_group("chargeable")
	
	left_front_wheel   = $VehicleWheel3D4
	left_middle_wheel  = $VehicleWheel3D5
	left_back_wheel    = $VehicleWheel3D6
	right_front_wheel  = $VehicleWheel3D3
	right_middle_wheel = $VehicleWheel3D2
	right_back_wheel   = $VehicleWheel3D1
	
	center_of_mass = $CenterOfMass.position


func _physics_process(delta):
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
	if charge_component.is_dead:
		steer_force = 0
		drive_force = 0
	
	left_front_wheel.engine_force  = drive_force + steer_force
	left_middle_wheel.engine_force = drive_force + steer_force
	left_back_wheel.engine_force = drive_force + steer_force
	right_front_wheel.engine_force = drive_force - steer_force
	right_middle_wheel.engine_force = drive_force - steer_force
	right_back_wheel.engine_force = drive_force - steer_force
	
	# This value should be revised; what is a better total force approximation?
	var total_force = abs(drive_force + steer_force)
	
	# If we're applying force, we're spending energy!
	# This needs to be modified; currently, massive power
	# is drawn on beginning motion, and close to none when
	# driving.
	if abs(total_force) > 0:
		charge_component.change_charge(-total_force * delta)
	else:
		charge_component.change_charge(-total_force * delta)
	
	# Fly away when pressing space
	if Input.is_action_pressed("jump"):
		linear_velocity += Vector3(0, 5, 0) * delta
		
	

