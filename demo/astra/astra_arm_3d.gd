extends Node3D
# Expects to be the child of a PhysicsBody3D

@onready var arm =     $Arm3D
@onready var bollard = $Arm3D/Bollard3D
@onready var tilt =    $Arm3D/ToolCoupler3D

@onready var arm_joint =     $FrameToArmJoint
@onready var bollard_joint = $Arm3D/ArmToBollardJoint
@onready var tilt_joint =    $Arm3D/BollardToCouplerJoint

@onready var tool_coupler_component = $Arm3D/ToolCoupler3D/ToolCouplerComponent
@onready var is_dead: bool = false

var arm_target_angle: float
var has_set_arm_angle: bool = false

var bollard_target_angle: float
var has_set_bollard_angle: bool = false

func _ready():
	arm_target_angle = arm.get_rotation()[0]
	bollard_target_angle = bollard.get_rotation()[0]
	$MultiplayerSynchronizer.set_multiplayer_authority(str(get_parent().name).to_int())

func _physics_process(delta):
	if not $"MultiplayerSynchronizer".is_multiplayer_authority():
	#if not is_multiplayer_authority():
		return
	
	var arm_angle = arm.get_rotation()[0]
	var bollard_angle = bollard.get_rotation()[0]
	
	# Arm PID
	const MOTOR_MULT = 0.8
	var arm_move_vec = Input.get_axis("arm_up", "arm_down")
	var arm_force = 0
	var arm_angle_diff = arm_target_angle - arm_angle
	if arm_move_vec == 0:
		if not has_set_arm_angle:
			arm_target_angle = arm_angle
			has_set_arm_angle = true
		elif abs(arm_angle_diff) > deg_to_rad(0.1):
			arm_force = -arm_angle_diff * 250 * delta
	else:
		has_set_arm_angle = false
		arm_force = arm_move_vec * MOTOR_MULT
		
	# Bollard PID
	var bollard_move_vec = Input.get_axis("bollard_curl", "bollard_dump")
	var bollard_force = 0
	#var bollard_angle_diff = bollard_target_angle - bollard_angle
	#if bollard_move_vec == 0:
	#	if not has_set_bollard_angle:
	#		bollard_target_angle = bollard_angle
	#		has_set_bollard_angle = true
	#	elif abs(bollard_angle_diff) > deg_to_rad(1):
	#		bollard_force = -bollard_angle_diff * 100 * delta
	#else:
	#has_set_bollard_angle = false
	bollard_force = bollard_move_vec * MOTOR_MULT * 2
		
	# Probably don't need PID for tilt
	var tilt_force = Input.get_axis("tilt_left", "tilt_right") * MOTOR_MULT
	
	if is_dead:
		arm_force = 0
		bollard_force = 0
		tilt_force = 0
	
	#print("Target bollard angle:", rad_to_deg(bollard_target_angle))
	#print("Bollard angle:", rad_to_deg(bollard_angle))
	#print("Bollard force:", rad_to_deg(bollard_force))
	move_motor(arm_joint, arm_force) if abs(arm_force) > 0 else stop_motor(arm_joint)
	bollard_joint.move_motor(bollard_force, bollard_angle) if abs(bollard_force) > 0 else bollard_joint.stop_motor(bollard_angle)
	move_motor(tilt_joint, tilt_force) if abs(tilt_force) > 0 else stop_motor(tilt_joint)
	
	# Tool attachment/detachment
	if Input.is_action_just_pressed("generic_action"): 
		tool_coupler_component.try_toggle_attach()

func move_motor(motor, force):
	motor.set("motor/target_velocity", force)
	
func stop_motor(motor):
	# Somehow stop the joints from moving due to gravity
	motor.set("motor/target_velocity", 0)
