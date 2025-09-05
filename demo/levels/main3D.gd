extends Node3D

@onready var spawn = $LandingSite/DirtSpawner

@onready var astra_scene:   PackedScene = load("res://playable_characters/robots/astra/astra_3d.tscn")
@onready var excah_scene:   PackedScene = load("res://playable_characters/robots/excahauler/excahauler_3d.tscn")
@onready var astro_scene:   PackedScene = load("res://playable_characters/astronaut/astronaut_character_3d.tscn")
@onready var freecam_scene: PackedScene = load("res://components/freecam.tscn")

var player = null
@onready var objects = $Objects

func get_player_scene(in_player_choice = null, in_pid = null):
	var player_choice = GameManager.get_player_choice(in_pid) if in_player_choice == null else in_player_choice
	if player_choice == GameManager.Character.ASTRO:
		return astro_scene
	elif player_choice == GameManager.Character.ASTRA:
		return astra_scene
	elif player_choice == GameManager.Character.EXCAH:
		return excah_scene
	elif player_choice == GameManager.Character.SPECT:
		if (in_pid == null and not GameManager.using_multiplayer) or in_pid == multiplayer.get_unique_id():
			return freecam_scene
		else:
			return null

func _ready():
	GameManager.network_process.connect(_network_process)
	GameManager.new_player_info.connect(_on_new_player_info)
	GameManager.new_object.connect(_on_new_object)
	GameManager.add_local_object.connect(_add_local_object)
	
	if GameManager.using_multiplayer:
		# Add all connected players to client
		var sorted_pids = GameManager.get_player_ids()
		sorted_pids.sort()
		
		var idx = 0
		for pid in sorted_pids:
			var curr_player_scene = get_player_scene(null, pid)
			if not curr_player_scene:
				continue
			var curr_player = curr_player_scene.instantiate()
			
			curr_player.name = str(pid)
			curr_player.nametag_text = GameManager.get_player_username(pid)
			
			var spawnpoint = get_node("PlayerSpawnpoints/"+str(idx%GameManager.num_spawns))
			curr_player.global_transform = spawnpoint.global_transform
			curr_player.spawn_trans = spawnpoint.global_transform
			
			if pid == multiplayer.get_unique_id():
				player = curr_player
			
			add_child(curr_player)
			idx += 1
		
		# Add all objects that exist when loading in.
		for body in objects.get_children():
			GameManager.add_object(body, body.path, body.global_transform)
		
		for body in $LandingSite.get_children():
			if body is StaticBody3D:
				GameManager.add_static_body(body)
	else:
		var curr_player_scene = get_player_scene(GameManager.player_choice)
		if not curr_player_scene:
			print("WARN: Invalid player scene!")
			return
		player = curr_player_scene.instantiate()
		var spawnpoint = $PlayerSpawnpoints.get_children()[0]
		player.global_transform = spawnpoint.global_transform
		player.spawn_trans = spawnpoint.global_transform
		add_child(player)

@rpc("any_peer")
func _on_new_player_info(id, username, version, player_choice):
	if not version == GameManager.version:
		return # Don't make a new player if they are on the wrong version!
	if not GameManager.get_players().has(id):
		var spawn_pos = $PlayerSpawnpoints.get_children()[0].global_position
		GameManager.add_player(id, username, version, player_choice, spawn_pos)
		print("New player joined: ", username)
		if player_choice == GameManager.Character.SPECT:
			return # Spectators do not need to be updated at all!
		var curr_player_scene = get_player_scene(player_choice)
		if not curr_player_scene:
			return
		var curr_player = curr_player_scene.instantiate()
		curr_player.name = str(id)
		add_child(curr_player, true)
		curr_player.global_position = spawn_pos
		curr_player.nametag_text = username

@rpc("any_peer")
func _on_new_object(sender_id, body_path, body_name, body_trans=Transform3D.IDENTITY):
	if not GameManager.get_objects().has(body_name):
		var loaded_body = load(body_path)
		var body = loaded_body.instantiate()
		body.name = body_name
		body.global_transform = body_trans
		GameManager.add_object(body, body_path, body_trans)
		objects.add_child(body)
	if multiplayer.is_server():
		for pid in GameManager.get_player_ids():
			if pid != sender_id and pid != 1:
				_on_new_object.rpc_id(pid, sender_id, body_path, body_name)
	else:
		_check_for_server_object.rpc_id(1, sender_id, body_path, body_name)

@rpc("any_peer")
func _check_for_server_object(sender_id, body_path, body_name):
	if multiplayer.is_server() and not GameManager.get_objects().has(body_name):
		_on_new_object(sender_id, body_path, body_name)

func _network_process(_delta):
	if not multiplayer.is_server():
		# Sync objects according to host
		var object_data = GameManager.get_objects()
		for body_name in object_data:
			var body = objects.get_node_or_null(NodePath(body_name))
			if not body:
				continue
			body.linear_velocity = object_data[body_name].linear_velocity
			body.angular_velocity = object_data[body_name].angular_velocity
			if body is BaseTool and body.connector.connected:
				continue
			body.global_transform = body.global_transform.interpolate_with(object_data[body_name].global_transform, 0.2)
		return
	var new_object_data = {}
	for body in objects.get_children():
		new_object_data[body.name] = {
			"global_transform": body.global_transform,
			"linear_velocity": body.linear_velocity,
			"angular_velocity": body.angular_velocity,
			"body_path": GameManager.get_object_data(body.name)["body_path"],
		}
	GameManager.add_new_object_data(new_object_data)

func _physics_process(_delta):
	if GameManager.using_multiplayer:
		if multiplayer.get_unique_id() == 1 and GameManager.is_console_host:
			return # We don't have a UI to update if we are a console host.
	if not player or not player.player_component.cam_scene:
		return # We don't have a UI if we aren't in the game/don't have a camera!
	
	var UI = $Global/UI
	UI.player = player
	UI.ball_count = $"Terrain/Dirtballs".get_child_count()
	UI.fps = $Global/"FPS Counter".fps
	if GameManager.player_choice == GameManager.Character.SPECT:
		player.h_sens = UI.h_cam_sens
		player.v_sens = UI.v_cam_sens
		player.invert_cam = UI.invert_cam
	else:
		player.player_component.cam_scene.h_sens = UI.h_cam_sens
		player.player_component.cam_scene.v_sens = UI.v_cam_sens
		player.player_component.cam_scene.zoom_sens = UI.cam_zoom_sens
		player.player_component.cam_scene.invert_cam = UI.invert_cam
	
	if GameManager.player_choice == GameManager.Character.ASTRO:
		pass
	elif GameManager.player_choice == GameManager.Character.ASTRA or GameManager.player_choice == GameManager.Character.EXCAH:
		spawn.spawn_rate = UI.spawn_rate
		UI.charging = player.charge_component.charging
		UI.charge_level = player.charge_component.charge_level
		UI.can_attach = player.arm.tool_coupler_component.can_attach
		if player.arm.tool_coupler_component.current_attachment:
			if player.arm.tool_coupler_component.current_attachment is Bucket:
				UI.dirtballs_in_bucket = player.arm.tool_coupler_component.current_attachment.in_bucket.num_dirtballs
		else:
			UI.dirtballs_in_bucket = 0
		if GameManager.player_choice == GameManager.Character.ASTRA:
			UI.stalling = player.stuck_stalling
			UI.dirtballs_in_hopper = player.hopper.inside_hopper.num_dirtballs
			player.arm.unsafe_mode = UI.unsafe_mode
		
	if OS.get_name() == "Android":
		if not GameManager.player_choice == GameManager.Character.SPECT:
			player.player_component.cam_scene.cam_locked = UI.cam_locked
		player.ext_input = UI.left_joystick.get_axis()
		if GameManager.player_choice == GameManager.Character.ASTRA:
			player.arm.ext_input = UI.right_joystick.get_axis()

func _on_fallen_area_3d_body_entered(body):
	await get_tree().physics_frame
	await get_tree().physics_frame
	body.global_transform = $"PlayerSpawnpoints/0".global_transform
	if body is RigidBody3D or body is VehicleBody3D:
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
	elif body is CharacterBody3D:
		body.velocity = Vector3.ZERO

func _add_local_object(body, deferred=false):
	$Objects.add_child(body, deferred)
