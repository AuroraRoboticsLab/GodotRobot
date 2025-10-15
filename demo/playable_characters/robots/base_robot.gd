extends VehicleBody3D
class_name BaseRobot

@export var drive_force_mult = 1200

@export var auto_component: AutonomyComponent

# Helper variables from PlayerComponent
@export var charge_component: ChargeComponent
@onready var spawn_trans: Transform3D = $PlayerComponent.spawn_trans:
	set(value):
		spawn_trans = value
		$PlayerComponent.spawn_trans = value

@export var player_component: PlayerComponent

@export var nametag_text: String = "unnamed robot":
	get:
		return nametag_text
	set(value):
		nametag_text = value

@export var tool_coupler: ToolCoupler

# Inputs
@export var move: GUIDEAction
@export var sprint: GUIDEAction
@export var jump: GUIDEAction
@export var move_arm: GUIDEAction
@export var move_extra: GUIDEAction
@export var interact: GUIDEAction

func _ready() -> void:
	center_of_mass = $CenterOfMass.position
	GameManager.network_process.connect(_network_process)
	jump.triggered.connect(trigger_jump)
	interact.triggered.connect(trigger_interact)

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

# -------- Outputs (Set on Robot) --------

# Flip over by pressing space
func trigger_jump() -> void:
	angular_velocity = lerp(angular_velocity, angular_velocity + transform.basis * Vector3(0,0,10), 0.5)
	linear_velocity.y = lerpf(linear_velocity.y, linear_velocity.y+1.62, 0.5)

# Tool attachment/detachment; Can be overwritten for other purposes in other robots.
func trigger_interact() -> void:
	if tool_coupler:
		tool_coupler.try_toggle_attach()

# -------- Inputs (Get from Robot) --------

func is_sprinting() -> bool:
	if auto_component and auto_component.is_autonomous():
		# Maybe `return auto_component.is_sprinting()`?
		return false # Placeholder
	return sprint.is_triggered()

func get_move_arm_values() -> Vector3:
	if auto_component and auto_component.is_autonomous():
		# Maybe `return auto_component.get_move_arm_values()`?
		return Vector3.ZERO # Placeholder
	return move_arm.value_axis_3d

func get_drive_values() -> Vector3:
	if auto_component and auto_component.is_autonomous():
		return auto_component.get_drive_values()
	return move.value_axis_3d
