extends Node3D
# Expects to be the child of a PhysicsBody3D

@onready var arm =     $FrameToArmJoint
@onready var bollard = $ArmToBollardJoint
@onready var tilt =    $BollardToCouplerJoint

@onready var tool_coupler_component = $ToolCoupler3D/ToolCouplerComponent
@onready var is_dead: bool = false


func _physics_process(delta):
	const MOTOR_MULT = 0.8
	var arm_force = Input.get_axis("arm_up", "arm_down") * MOTOR_MULT
	var bollard_force = Input.get_axis("bollard_curl", "bollard_dump") * MOTOR_MULT
	var tilt_force = Input.get_axis("tilt_left", "tilt_right") * MOTOR_MULT
	var hopper_force = Input.get_axis("hopper_open", "hopper_close") * MOTOR_MULT
	
	if is_dead:
		arm_force = 0
		bollard_force = 0
		tilt_force = 0
		hopper_force = 0
	
	move_motor(arm, arm_force) if abs(arm_force) > 0 else stop_motor(arm)
	move_motor(bollard, bollard_force) if abs(bollard_force) > 0 else stop_motor(bollard)
	move_motor(tilt, tilt_force) if abs(tilt_force) > 0 else stop_motor(tilt)
	
	# Tool attachment/detachment
	if Input.is_action_just_pressed("generic_action"): 
		tool_coupler_component.try_toggle_attach()

func move_motor(motor, force):
	motor.set("motor/target_velocity", force)
	
func stop_motor(motor):
	# Somehow stop the joints from moving due to gravity
	motor.set("motor/target_velocity", 0)
