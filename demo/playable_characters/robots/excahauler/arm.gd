extends Node3D

@onready var boom  = $Boom3D
@onready var stick = $Boom3D/Stick3D
@onready var tilt  = $Boom3D/Stick3D/Tilt3D

@onready var boom_joint  = $FrameToBoomJoint
@onready var stick_joint = $Boom3D/BoomToStickJoint
@onready var tilt_joint  = $Boom3D/Stick3D/StickToTiltJoint

@onready var tool_coupler_component = %ToolCouplerComponent

func _ready() -> void:
	GameManager.network_process.connect(_network_process)

func _network_process(_delta):
	var curr_attach_path = null
	var joint_data = null
	if not get_parent().player_component.is_multiplayer_authority():
		var player_data = GameManager.get_player_data(str(get_parent().name).to_int())
		if not player_data:
			return
		
		curr_attach_path = player_data["curr_attach_path"]
		tool_coupler_component.current_attachment_path = curr_attach_path
		
		joint_data = player_data["joint_data"]
		boom_joint.angle_limit = lerp(boom_joint.angle_limit, joint_data[0], 0.5)
		stick_joint.angle_limit = lerp(stick_joint.angle_limit, joint_data[1], 0.5)
		tilt_joint.angle_limit = lerp(tilt_joint.angle_limit, joint_data[2], 0.5)
		return
	
	curr_attach_path = tool_coupler_component.current_attachment_path
	joint_data = [boom_joint.angle_limit, stick_joint.angle_limit, tilt_joint.angle_limit]
	var new_player_data = {
		"curr_attach_path": curr_attach_path,
		"joint_data": joint_data
	}
	GameManager.add_new_player_data(new_player_data)

func _physics_process(_delta: float) -> void:
	if GameManager.using_multiplayer and not get_parent().player_component.is_multiplayer_authority():
		return
	#print("Boom: ", rad_to_deg(boom_joint.get_angle()))
	#print("Stick: ", rad_to_deg(stick_joint.get_angle()))
	#print("Tilt: ", rad_to_deg(tilt_joint.get_angle()))
	
	if (Input.is_action_just_pressed("generic_action")): 
		tool_coupler_component.try_toggle_attach()
	
	const MOTOR_MULT = 1.2
	
	var boom_force =  0
	var stick_force = 0
	var tilt_force =  0
	#if can_input and not is_dead:
	var boom_input = Input.get_axis("arm_up", "arm_down")
	var stick_input = Input.get_axis("bollard_curl", "bollard_dump")
	var tilt_input = Input.get_axis("tilt_left", "tilt_right")
	
	#if ext_input:
	#	boom_input = -ext_input.y
	#	stick_input = ext_input.x
	
	boom_force  = boom_input * MOTOR_MULT * 0.8
	stick_force = stick_input * MOTOR_MULT * 0.8
	tilt_force  = tilt_input * MOTOR_MULT
	
	boom_joint.move_motor(boom_force) if abs(boom_force) > 0 else boom_joint.stop_motor()
	stick_joint.move_motor(stick_force) if abs(stick_force) > 0 else stick_joint.stop_motor()
	tilt_joint.move_motor(tilt_force) if abs(tilt_force) > 0 else tilt_joint.stop_motor()

func _on_tool_coupler_component_add_joint(curr_joint: Generic6DOFJoint3D) -> void:
	$Boom3D/Stick3D.add_child(curr_joint)
