extends Node3D

@onready var fork  = $Fork3D
@onready var dump = $Fork3D/Dump3D

@onready var fork_joint  = $FrameToForkJoint
@onready var dump_joint = $Fork3D/ForkToDumpJoint

@export var move_scoop: GUIDEAction

func _physics_process(_delta: float) -> void:
	if GameManager.using_multiplayer and not get_parent().player_component.is_multiplayer_authority():
		return
	#print("fork: ", rad_to_deg(fork_joint.get_angle()))
	#print("dump: ", rad_to_deg(dump_joint.get_angle()))
	
	const MOTOR_MULT = 1.2
	
	var fork_force =  0
	var dump_force = 0
	#if can_input and not is_dead:
	var fork_input = move_scoop.value_axis_2d.x
	var dump_input = move_scoop.value_axis_2d.y
	
	#if ext_input:
	#	fork_input = -ext_input.y
	#	dump_input = ext_input.x
	
	fork_force  = fork_input * MOTOR_MULT * 0.8
	dump_force = dump_input * MOTOR_MULT * 0.8
	
	fork_joint.move_motor(fork_force) if abs(fork_force) > 0 else fork_joint.stop_motor()
	dump_joint.move_motor(dump_force) if abs(dump_force) > 0 else dump_joint.stop_motor()
