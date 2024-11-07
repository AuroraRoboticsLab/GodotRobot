extends Node3D

@onready var boom  = $Boom3D
@onready var stick = $Boom3D/Stick3D
@onready var tilt  = $Boom3D/Stick3D/Tilt3D

@onready var boom_joint  = $FrameToBoomJoint
@onready var stick_joint = $Boom3D/BoomToStickJoint
@onready var tilt_joint  = $Boom3D/Stick3D/StickToTiltJoint

func _physics_process(delta: float) -> void:
	const MOTOR_MULT = 0.8
	
	var boom_force = 0
	var stick_force = 0
	var tilt_force = 0
	#if can_input and not is_dead:
	var boom_input = Input.get_axis("arm_up", "arm_down")
	var stick_input = Input.get_axis("bollard_curl", "bollard_dump")
	
	#if ext_input:
	#	boom_input = -ext_input.y
	#	stick_input = ext_input.x
	
	boom_force = boom_input * MOTOR_MULT * 1.5
	stick_force = stick_input * MOTOR_MULT * 1.5
	tilt_force = Input.get_axis("tilt_left", "tilt_right") * MOTOR_MULT
	
	boom_joint.move_motor(boom_force) if abs(boom_force) > 0 else boom_joint.stop_motor()
	stick_joint.move_motor(stick_force) if abs(stick_force) > 0 else stick_joint.stop_motor()
	tilt_joint.move_motor(tilt_force) if abs(tilt_force) > 0 else tilt_joint.stop_motor()
