@tool
extends Node3D
class_name PlayerComponent

var cam_load = preload("res://components/movable_camera_3d.tscn")
var cam_scene: MovableCamera = null
@export var lock_cam_horiz: bool = false:
	set(value):
		lock_cam_horiz = value
		if cam_scene:
			cam_scene.lock_horiz = value
@export var cam_pos: Vector3 = Vector3.ZERO:
	set(value):
		$CameraPosition.position = value
		cam_pos = value
		if cam_scene:
			cam_scene.position = value

var spawn_trans: Transform3D = Transform3D.IDENTITY
var tp_height: float = 1.0

@onready var charge_component: ChargeComponent = $ChargeComponent
@export var nametag_text: String = "unnamed player":
	set(value):
		$Nametag.text = value
		nametag_text = value
@export var nametag_pos: Vector3 = Vector3.ZERO:
	set(value):
		nametag_pos = value
		$Nametag.position = value

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		return # Don't do multiplayer stuff yet
	
	if GameManager.using_multiplayer:
		set_multiplayer_authority(str(get_parent().name).to_int())
		if is_multiplayer_authority():
			setup_player_scene()
	else:
		setup_player_scene()

func setup_player_scene():
	cam_scene = cam_load.instantiate()
	add_child(cam_scene)
	cam_scene.position = cam_pos
	$Nametag.visible = false
	cam_scene.lock_horiz = lock_cam_horiz
