extends Node3D

@onready var spawn = $DirtSpawner
@onready var despawn = $DirtballDespawn
@onready var terrain = $TerrainScript

@export var robot_scene: PackedScene = load("res://astra/astra_3d.tscn")
var robot = null

func _ready():
	var index = 0
	for pid in GameManager.players:
		var curr_player = robot_scene.instantiate()
		curr_player.name = str(pid)
		add_child(curr_player)
		print("pid: ", pid, "; unique_id: ", multiplayer.get_unique_id())
		if pid == multiplayer.get_unique_id():
			robot = curr_player
		
		curr_player.nametag_text = GameManager.players[pid]["username"]
		
		for spawnpoint in $PlayerSpawnpoints.get_children():
			if spawnpoint.name == str(index%GameManager.num_spawns):
				curr_player.global_transform = spawnpoint.global_transform
		index += 1
		
	GameManager.new_player_info.connect(_on_new_player_info)

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
		
		# Assign a spawn point
		var index = GameManager.players.keys().size() - 1
		for spawnpoint in $PlayerSpawnpoints.get_children():
			if spawnpoint.name == str(index % GameManager.num_spawns):
				curr_player.global_transform = spawnpoint.global_transform

func _physics_process(_delta):
	if multiplayer.get_unique_id() == 1:
		return
	
	# Despawn oldest dirtballs (that have fallen through terrain)
	for dirtball in despawn.get_children():
		if dirtball.linear_velocity.y<-1.0: # has fallen for a while
			dirtball.queue_free()
	
	# Check for stationary dirtballs and consider terrain merge
	for dirtball in spawn.get_children():
		if dirtball.linear_velocity.length() < 0.2:  # low horizontal velocity (m/s)
			if abs(dirtball.linear_velocity.y) < 0.02:  # very low vertical velocity (m/s)
				if dirtball.angular_velocity.length() < 0.1: # not rotating much (rad/s)
					if terrain.dirtball_merge(dirtball):
						var pos = dirtball.global_position
						spawn.remove_child(dirtball)
						dirtball.collision_mask = 0 # fall down through terrain
						despawn.add_child(dirtball)
						dirtball.global_position=pos # preserve position
		
		# A few tend to break through terrain and just plummet
		if dirtball.linear_velocity.y<-10.0: 
			dirtball.queue_free()
	
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
	

