extends Node3D
# Expects to be the child of a PhysicsBody3D

@onready var hopper_1 = $BetterHingeJoint3D
@onready var hopper_2 = $BetterHingeJoint3D2
@onready var inside_hopper = $InsideHopper

@onready var is_dead: bool = false

func _physics_process(_delta):
	const MOTOR_MULT = 0.8
	var hopper_force = Input.get_axis("hopper_open", "hopper_close") * MOTOR_MULT
	
	if is_dead:
		hopper_force = 0
	
	hopper_1.move_motor(hopper_force) if abs(hopper_force) > 0 else hopper_1.stop_motor()
	hopper_2.move_motor(-hopper_force) if abs(hopper_force) > 0 else hopper_2.stop_motor()
