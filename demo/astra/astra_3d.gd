extends VehicleBody3D

const DRIVE_FORCE_MULT = 1200

@onready var left_front_wheel   = $FrontLeft
@onready var left_back_wheel    = $BackLeft
@onready var right_front_wheel  = $FrontRight
@onready var right_back_wheel   = $BackRight

@onready var arm =       $ArmNode3D/FrameToArmJoint
@onready var bollard =   $ArmNode3D/ArmToBollardJoint
@onready var tilt =      $ArmNode3D/BollardToCouplerJoint
@onready var hopper_1 =  $HopperNode3D/HingeJoint3D
@onready var hopper_2 =  $HopperNode3D/HingeJoint3D2

@onready var charge_component = $ChargeComponent
@onready var rear_connector =   $ConnectorComponent

@onready var stuck_stalling: bool = false
@onready var stalling: bool = false
@onready var start_stall: float = 0

@onready var tool_coupler = $ArmNode3D/ToolCoupler3D

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
	
	const MOTOR_MULT = 0.8
	var arm_force = Input.get_axis("arm_up", "arm_down") * MOTOR_MULT
	var bollard_force = Input.get_axis("bollard_curl", "bollard_dump") * MOTOR_MULT
	var tilt_force = Input.get_axis("tilt_left", "tilt_right") * MOTOR_MULT
	var hopper_force = Input.get_axis("hopper_open", "hopper_close") * MOTOR_MULT
	
	if charge_component.is_dead:
		arm_force = 0
		bollard_force = 0
		tilt_force = 0
		hopper_force = 0
	
	move_motor(arm, arm_force) if abs(arm_force) > 0 else stop_motor(arm)
	move_motor(bollard, bollard_force) if abs(bollard_force) > 0 else stop_motor(bollard)
	move_motor(tilt, tilt_force) if abs(tilt_force) > 0 else stop_motor(tilt)
	move_motor(hopper_1, hopper_force) if abs(hopper_force) > 0 else stop_motor(hopper_1)
	move_motor(hopper_2, -hopper_force) if abs(hopper_force) > 0 else stop_motor(hopper_2)
	
	power_spent += (abs(arm_force) + abs(bollard_force) + abs(tilt_force) + abs(hopper_force))
	
	#print(power_spent)
	charge_component.change_charge(-power_spent * delta)
	
	if Input.is_action_just_pressed("generic_action"): 
		if tool_coupler.can_attach and not tool_coupler.tool_connector.connected:
			tool_coupler.attach()
		elif tool_coupler.tool_connector.nearby_connector:
			tool_coupler.detach()
			
	
	# Fly away when pressing space
	if Input.is_action_just_pressed("jump"):
		linear_velocity = Vector3.ZERO
		global_position += Vector3(0, 1, 0)

func move_motor(motor, force):
	motor.set("motor/target_velocity", force)
	
func stop_motor(motor):
	# Somehow stop the joints from moving due to gravity
	motor.set("motor/target_velocity", 0)


# Connector logic. Very simple, because the connector component
# handles most of it!

# Connector sees another connector nearby. What happens?
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
