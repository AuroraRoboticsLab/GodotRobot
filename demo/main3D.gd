extends Node3D

@onready var spawn = $DirtSpawner
@export var robot_scene: PackedScene = preload("res://astra/astra_3d.tscn")
var robot = null

func _ready():
	if GameManager.using_multiplayer:
		var index = 0
		for pid in GameManager.players:
			var curr_player = robot_scene.instantiate()
			curr_player.name = str(pid)
			add_child(curr_player)
			if pid == multiplayer.get_unique_id():
				robot = curr_player
			
			curr_player.nametag_text = GameManager.players[pid]["username"]
			
			for spawnpoint in $PlayerSpawnpoints.get_children():
				if spawnpoint.name == str(index%GameManager.num_spawns):
					curr_player.global_transform = spawnpoint.global_transform
			index += 1
			
		GameManager.new_player_info.connect(_on_new_player_info)
	else:
		robot = robot_scene.instantiate()
		robot.global_transform = $PlayerSpawnpoints.get_children()[0].global_transform
		add_child(robot)

@rpc("any_peer")
func _on_new_player_info(id, username):
	if not GameManager.players.has(id):
		GameManager.players[id] = {
			"username": username
		}
		print("New player joined: ", username)
		var curr_player = robot_scene.instantiate()
		curr_player.name = str(id)
		add_child(curr_player)
		curr_player.nametag_text = username

func _physics_process(_delta):
	if GameManager.using_multiplayer:
		if multiplayer.get_unique_id() == 1 and GameManager.is_console_host:
			return # We don't have a UI to update if we are a console host.
		if not robot:
			return # We don't have a UI if we aren't in the game!
	
	$UI.ball_count = spawn.get_child_count()
	$UI.fps = $"FPS Counter".fps
	spawn.spawn_rate = $UI.spawn_rate
	$UI.charging = robot.charge_component.charging
	$UI.charge_level = robot.charge_component.charge_level
	$UI.stalling = robot.stuck_stalling
	$UI.can_attach = robot.arm.tool_coupler_component.can_attach
	robot.cam_scene.h_sens = $UI.h_cam_sens
	robot.cam_scene.v_sens = $UI.v_cam_sens
	robot.cam_scene.zoom_sens = $UI.cam_zoom_sens
	robot.tp_height = $UI.tp_height
	if robot.arm.tool_coupler_component.current_attachment:
		if robot.arm.tool_coupler_component.current_attachment.attachment_type == "bucket":
			$UI.dirtballs_in_bucket = robot.arm.tool_coupler_component.current_attachment.in_bucket.num_dirtballs
	else:
		$UI.dirtballs_in_bucket = -1
