extends VehicleBody3D
class_name RobotBase

@export var drive_force_mult = 1200

var cam_load = preload("res://components/movable_camera_3d.tscn")
var cam_scene = null

var can_input: bool = true
var ext_input = null
var spawn_trans = null
var tp_height: float = 1.0

@export var charge_component: ChargeComponent
@export var auto_component: AutonomyComponent

@export var nametag_text: String = "unnamed robot":
	get:
		return $Nametag.text
	set(value):
		$Nametag.text = value

func _ready() -> void:
	center_of_mass = $CenterOfMass.position
	
	GameManager.network_process.connect(_network_process)
	GameManager.toggle_inputs.connect(toggle_inputs)
	
	if GameManager.using_multiplayer:
		$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
		if $MultiplayerSynchronizer.is_multiplayer_authority():
			cam_scene = cam_load.instantiate()
			add_child(cam_scene)
			$Nametag.visible = false # We don't want to see our own nametag
	else:
		cam_scene = cam_load.instantiate()
		add_child(cam_scene)
		$Nametag.visible = false

func _network_process(_delta):
	# This client is a player we do not control
	if not $MultiplayerSynchronizer.is_multiplayer_authority():
		var player_data = GameManager.get_player_data(str(name).to_int())
		if not player_data:
			return
		global_position = global_position.lerp(player_data.global_position, 0.5)
		linear_velocity = linear_velocity.lerp(player_data.linear_velocity, 0.5)
		angular_velocity = angular_velocity.lerp(player_data.angular_velocity, 0.5)
		set_quaternion(get_quaternion().slerp(player_data.quaternion, 0.5))
		charge_component.remaining_amp_hours = player_data.remaining_amp_hours
		return
	
	var new_player_data = {
		"global_position": global_position,
		"linear_velocity": linear_velocity,
		"angular_velocity": angular_velocity,
		"quaternion": get_quaternion(),
		"remaining_amp_hours": charge_component.remaining_amp_hours,
	}
	GameManager.add_new_player_data(new_player_data)

func toggle_inputs(in_bool = null):
	if in_bool == null:
		can_input = !can_input
	else:
		can_input = in_bool
