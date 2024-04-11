extends VehicleBody3D

const ENGINE_FORCE = 1200
const STEERING_FORCE = 600

var left_front_wheel   : VehicleWheel3D
var left_middle_wheel  : VehicleWheel3D
var left_back_wheel    : VehicleWheel3D
var right_front_wheel  : VehicleWheel3D
var right_middle_wheel : VehicleWheel3D
var right_back_wheel   : VehicleWheel3D

func can_charge():
	pass
@onready var charge_component = $ChargeComponent

func _ready():
	# Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	left_front_wheel   = $VehicleWheel3D4
	left_middle_wheel  = $VehicleWheel3D5
	left_back_wheel    = $VehicleWheel3D6
	right_front_wheel  = $VehicleWheel3D3
	right_middle_wheel = $VehicleWheel3D2
	right_back_wheel   = $VehicleWheel3D1
	
	center_of_mass = $CenterOfMass.position


func _physics_process(delta):
	var movement_speed = linear_velocity.length()
	var engine_force_multiplier: float
	var steering_force_multiplier: float
	
	if movement_speed > 0.01:
		engine_force_multiplier = 10.0 / ((12*movement_speed)**2)
	else:
		engine_force_multiplier = 500
	
	var rotation_speed = angular_velocity.length()
	if rotation_speed > 0.01:
		steering_force_multiplier = 3.0 / (6*rotation_speed**2)
	else:
		steering_force_multiplier = 15
	
	var drive_force = Input.get_axis("forward", "backward") * ENGINE_FORCE * delta * engine_force_multiplier
	var steer_force = Input.get_axis("right", "left") * STEERING_FORCE * delta * steering_force_multiplier
	
	if charge_component.is_dead:
		steer_force = 0
		drive_force = 0
	
	left_front_wheel.engine_force  = drive_force + steer_force
	left_middle_wheel.engine_force = drive_force + steer_force
	left_back_wheel.engine_force = drive_force + steer_force
	right_front_wheel.engine_force = drive_force - steer_force
	right_middle_wheel.engine_force = drive_force - steer_force
	right_back_wheel.engine_force = drive_force - steer_force
	
	if abs(drive_force) > 0 or abs(steer_force) > 0:
		charge_component.moving = true
	else:
		charge_component.moving = false
	
	if Input.is_action_pressed("jump"):
		linear_velocity += Vector3(0, 5, 0) * delta
		
	

