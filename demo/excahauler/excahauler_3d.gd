extends RobotBase
# The movable excahauler

@onready var left_front_wheel   = $FrontLeft
@onready var left_middle_wheel  = $MiddleLeft
@onready var left_back_wheel    = $BackLeft
@onready var right_front_wheel  = $FrontRight
@onready var right_middle_wheel = $MiddleRight
@onready var right_back_wheel   = $BackRight

@onready var arm = $Arm
@onready var tool_coupler_component = %ToolCouplerComponent

func _physics_process(delta: float) -> void:
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
	if Input.is_action_pressed("shift"):
		engine_force_multiplier = 10000.0
	
	const max_turn_force = 30.0 # Starting (and max) turn force
	const turn_amp = 3.0 # How quickly does turn force fall off with speed?
	var rotation_speed = angular_velocity.length()
	steering_force_multiplier = 1.0 / ((turn_amp*rotation_speed**2) + (1.0/max_turn_force))

	# Calculate drive and steer forces.
	var drive_force = 0
	var steer_force = 0
	var drive_input = Input.get_axis("forward", "backward")
	var steer_input = Input.get_axis("right", "left")
		
	#if (can_input or GameManager.is_npc) and not charge_component.is_dead:
	drive_force = drive_input * drive_force_mult * delta * engine_force_multiplier
	steer_force = steer_input * drive_force_mult * delta * steering_force_multiplier
	
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
	#var total_drive_force = abs(drive_force + steer_force/2)
