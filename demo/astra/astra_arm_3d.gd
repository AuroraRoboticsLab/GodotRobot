extends Node3D
# Expects to be the child of a PhysicsBody3D

@onready var arm =     $Arm3D
@onready var bollard = $Arm3D/Bollard3D
@onready var tilt =    $Arm3D/Bollard3D/ToolCoupler3D

@onready var arm_joint =     $FrameToArmJoint
@onready var bollard_joint = $Arm3D/ArmToBollardJoint
@onready var tilt_joint =    $Arm3D/Bollard3D/BollardToCouplerJoint

@onready var tool_coupler_component = $Arm3D/Bollard3D/ToolCoupler3D/ToolCouplerComponent
@onready var is_dead: bool = false

# Arm PID control constants
const KP = 50.0
const KI = 5.0
const KD = 0.02
var arm_target_angle: float
var arm_integral: float
var arm_previous_error: float
var has_set_arm_angle: bool = false

var bollard_target_angle: float
var has_set_bollard_angle: bool = false

func _ready():
	arm_target_angle = arm.get_rotation()[0]
	bollard_target_angle = bollard.get_rotation()[0]
	$MultiplayerSynchronizer.set_multiplayer_authority(str(get_parent().name).to_int())

func _physics_process(delta):
	if not $"MultiplayerSynchronizer".is_multiplayer_authority():
		return
	
	var arm_angle = arm.get_rotation()[0]
	
	const MOTOR_MULT = 0.8
	# Arm PID
	var arm_move_vec = Input.get_axis("arm_up", "arm_down")
	var arm_force = 0
	var arm_angle_diff = arm_target_angle - arm_angle
	if arm_move_vec == 0:
		if not has_set_arm_angle:
			arm_target_angle = arm_angle
			has_set_arm_angle = true
			arm_integral = 0.0  # Reset integral when target angle is set
			arm_previous_error = 0.0  # Reset previous error when target angle is set
		elif abs(arm_angle_diff) > deg_to_rad(0.1):
			# Proportional term
			var p_term = KP * arm_angle_diff
			# Integral term (with clamping to prevent windup)
			arm_integral += arm_angle_diff * delta
			arm_integral = clamp(arm_integral, -10.0, 10.0)
			var i_term = KI * arm_integral
			# Derivative term
			var d_term = KD * (arm_angle_diff - arm_previous_error) / delta
			# Compute total force
			arm_force = -(p_term + i_term + d_term)
			# Update previous error
			arm_previous_error = arm_angle_diff
			
			# Debug prints to check values
			#print("P:", p_term, " I:", i_term, " D:", d_term, " Force:", arm_force)
	else:
		has_set_arm_angle = false
		arm_force = arm_move_vec * MOTOR_MULT
	#var arm_force = Input.get_axis("arm_up", "arm_down") * MOTOR_MULT * 2
	# Bollard and Tilt F
	var bollard_force = Input.get_axis("bollard_curl", "bollard_dump") * MOTOR_MULT * 2
	var tilt_force = Input.get_axis("tilt_left", "tilt_right") * MOTOR_MULT
	
	if is_dead:
		arm_force = 0
		bollard_force = 0
		tilt_force = 0
	
	arm_joint.move_motor(arm_force) if abs(arm_force) > 0 else arm_joint.stop_motor()
	bollard_joint.move_motor(bollard_force) if abs(bollard_force) > 0 else bollard_joint.stop_motor()
	tilt_joint.move_motor(tilt_force) if abs(tilt_force) > 0 else tilt_joint.stop_motor()
	
	# Tool attachment/detachment
	if Input.is_action_just_pressed("generic_action"): 
		tool_coupler_component.try_toggle_attach()
