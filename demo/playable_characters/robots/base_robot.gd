extends VehicleBody3D
class_name BaseRobot

@export var drive_force_mult = 1200

@onready var auto_component: AutonomyComponent = $AutonomyComponent

# Helper variables from PlayerComponent
@onready var charge_component: ChargeComponent = $ChargeComponent
@onready var spawn_trans: Transform3D = $PlayerComponent.spawn_trans:
	set(value):
		spawn_trans = value
		$PlayerComponent.spawn_trans = value

@onready var player_component: PlayerComponent = $PlayerComponent

@export var nametag_text: String = "unnamed robot":
	get:
		return nametag_text
	set(value):
		nametag_text = value

# Inputs
@export var move: GUIDEAction
@export var sprint: GUIDEAction
@export var jump: GUIDEAction

func _ready() -> void:
	center_of_mass = $CenterOfMass.position
	GameManager.network_process.connect(_network_process)

func _network_process(_delta):
	# This client is a player we do not control
	if not $PlayerComponent.is_multiplayer_authority():
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
