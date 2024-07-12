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

func _ready():
	if GameManager.using_multiplayer:
		$MultiplayerSynchronizer.set_multiplayer_authority(str(get_parent().name).to_int())

func _physics_process(delta):
	if GameManager.using_multiplayer and not $"MultiplayerSynchronizer".is_multiplayer_authority():
		if tool_coupler_component.tool_connector.connected and tool_coupler_component.current_attachment:
			tool_coupler_component.current_attachment.global_transform = tool_coupler_component.get_parent().global_transform
			tool_coupler_component.current_attachment.global_position = tool_coupler_component.global_position
		return
	
	const MOTOR_MULT = 0.8
	var arm_force = Input.get_axis("arm_up", "arm_down") * MOTOR_MULT * 2
	var bollard_force = Input.get_axis("bollard_curl", "bollard_dump") * MOTOR_MULT * 2
	var tilt_force = Input.get_axis("tilt_left", "tilt_right") * MOTOR_MULT
	
	if is_dead:
		arm_force = 0
		bollard_force = 0
		tilt_force = 0
	
	arm_joint.move_motor(arm_force) if abs(arm_force) > 0 else arm_joint.stop_motor()
	bollard_joint.move_motor(bollard_force) if abs(bollard_force) > 0 else bollard_joint.stop_motor()
	tilt_joint.move_motor(tilt_force) if abs(tilt_force) > 0 else tilt_joint.stop_motor()
	
	var power_spent = (arm_force + bollard_force + tilt_force) * 3
	get_parent().charge_component.change_charge(-power_spent * delta)
	
	# Tool attachment/detachment
	if Input.is_action_just_pressed("generic_action"): 
		tool_coupler_component.try_toggle_attach()
