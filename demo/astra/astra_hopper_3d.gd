extends Node3D
# Expects to be the child of a PhysicsBody3D

@onready var hopper_1 = $HingeJoint3D
@onready var hopper_2 = $HingeJoint3D2

@onready var is_dead: bool = false

func _physics_process(_delta):
	const MOTOR_MULT = 0.8
	var hopper_force = Input.get_axis("hopper_open", "hopper_close") * MOTOR_MULT
	
	if is_dead:
		hopper_force = 0
	
	move_motor(hopper_1, hopper_force) if abs(hopper_force) > 0 else stop_motor(hopper_1)
	move_motor(hopper_2, -hopper_force) if abs(hopper_force) > 0 else stop_motor(hopper_2)

func move_motor(motor, force):
	motor.set("motor/target_velocity", force)
	
func stop_motor(motor):
	# Somehow stop the joints from moving due to gravity
	motor.set("motor/target_velocity", 0)
