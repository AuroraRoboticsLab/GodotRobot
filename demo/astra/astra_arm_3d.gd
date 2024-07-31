extends Node3D
# Expects to be the child of a PhysicsBody3D

@onready var arm =     $Arm3D
@onready var bollard = $Arm3D/Bollard3D
@onready var tilt =    $Arm3D/Bollard3D/ToolCoupler3D

@onready var arm_joint =     $FrameToArmJoint
@onready var bollard_joint = $Arm3D/ArmToBollardJoint
@onready var tilt_joint =    $Arm3D/Bollard3D/BollardToCouplerJoint

@onready var ext_input = null

@onready var tool_coupler_component = $Arm3D/Bollard3D/ToolCoupler3D/ToolCouplerComponent
@onready var is_dead: bool = false

@onready var unsafe_mode: bool = false
var can_input: bool = true

func _ready():
	if GameManager.using_multiplayer:
		$MultiplayerSynchronizer.set_multiplayer_authority(str(get_parent().name).to_int())
	
	GameManager.network_process.connect(_network_process)
	GameManager.toggle_inputs.connect(toggle_inputs)

func toggle_inputs(in_bool = null):
	if in_bool != null:
		can_input = !can_input
	else:
		can_input = in_bool

func _network_process(_delta):
	var curr_attach_path = null
	var joint_data = null
	if not $MultiplayerSynchronizer.is_multiplayer_authority():
		var player_data = GameManager.get_player_data(str(get_parent().name).to_int())
		if not player_data:
			return
		
		curr_attach_path = player_data["curr_attach_path"]
		tool_coupler_component.current_attachment_path = curr_attach_path
		
		joint_data = player_data["joint_data"]
		arm_joint.angle_limit = lerp(arm_joint.angle_limit, joint_data[0], 0.5)
		bollard_joint.angle_limit = lerp(bollard_joint.angle_limit, joint_data[1], 0.5)
		tilt_joint.angle_limit = lerp(tilt_joint.angle_limit, joint_data[2], 0.5)
		return
	
	curr_attach_path = tool_coupler_component.current_attachment_path
	joint_data = [arm_joint.angle_limit, bollard_joint.angle_limit, tilt_joint.angle_limit]
	var new_player_data = {
		"curr_attach_path": curr_attach_path,
		"joint_data": joint_data
	}
	GameManager.add_new_player_data(new_player_data)

func _physics_process(delta):
	if GameManager.using_multiplayer and not $"MultiplayerSynchronizer".is_multiplayer_authority():
		return
	
	const MOTOR_MULT = 0.8
	
	var arm_force = 0
	var bollard_force = 0
	var tilt_force = 0
	if can_input and not is_dead:
		var arm_input = Input.get_axis("arm_up", "arm_down")
		var bollard_input = Input.get_axis("bollard_curl", "bollard_dump")
		
		if ext_input:
			arm_input = -ext_input.y
			bollard_input = ext_input.x
		
		arm_force = arm_input * MOTOR_MULT * 1.5
		bollard_force = bollard_input * MOTOR_MULT * 1.5
		if not arm_joint.stopped: # Auto-level bollard
			bollard_force = clamp(bollard_force-arm_force, -MOTOR_MULT * 1.5, MOTOR_MULT * 1.5)
			if bollard_force == 0: # We must be moving opposite the arm movement
				bollard_force = bollard_input * MOTOR_MULT * 1.5
		tilt_force = Input.get_axis("tilt_left", "tilt_right") * MOTOR_MULT
	
		# Some tools will want to move slower for more precision
		var tool = tool_coupler_component.current_attachment
		if not unsafe_mode and tool and tool.has_method("get_speed_mod"):
			var speed_mod = tool.get_speed_mod()
			arm_force *= speed_mod
			bollard_force *= speed_mod
			tilt_force *= speed_mod
	
	arm_joint.move_motor(arm_force) if abs(arm_force) > 0 else arm_joint.stop_motor()
	bollard_joint.move_motor(bollard_force) if abs(bollard_force) > 0 else bollard_joint.stop_motor()
	tilt_joint.move_motor(tilt_force) if abs(tilt_force) > 0 else tilt_joint.stop_motor()
	
	var power_spent = (arm_force + bollard_force + tilt_force) * 3
	get_parent().charge_component.change_charge(-power_spent * delta)
	
	# Tool attachment/detachment
	if (Input.is_action_just_pressed("generic_action")) and can_input: 
		tool_coupler_component.try_toggle_attach()
