extends Node3D

@onready var spawn = $DirtSpawner
@export var robot_scene: PackedScene = load("res://astra/astra_3d.tscn")
var robot = null
@onready var objects = $Objects

func _ready():
	GameManager.network_process.connect(_network_process)
	GameManager.new_player_info.connect(_on_new_player_info)
	GameManager.new_object.connect(_on_new_object)
	if GameManager.using_multiplayer:
		# Add all connected players to client
		var sorted_pids = GameManager.get_player_ids()
		sorted_pids.sort()
		
		var idx = 0
		for pid in sorted_pids:
			var curr_player = robot_scene.instantiate()
			curr_player.name = str(pid)
			add_child(curr_player)
			if pid == multiplayer.get_unique_id():
				robot = curr_player
			
			curr_player.nametag_text = GameManager.get_player_username(pid)
			
			if curr_player.arm.tool_coupler_component.current_attachment_path:
				curr_player.arm.tool_coupler_component.try_toggle_attach()
			
			var spawnpoint = get_node("PlayerSpawnpoints/"+str(idx%GameManager.num_spawns))
			curr_player.global_transform = spawnpoint.global_transform
			curr_player.spawn_trans = spawnpoint.global_transform
			
			idx += 1
		
		# Add all objects that exist when loading in.
		for body in objects.get_children():
			GameManager.add_object(body, body.path, body.global_transform)
		
		for body in get_children():
			if body is StaticBody3D:
				GameManager.add_static_body(body)
	else:
		robot = robot_scene.instantiate()
		var spawnpoint = $PlayerSpawnpoints.get_children()[0]
		robot.global_transform = spawnpoint.global_transform
		robot.spawn_trans = spawnpoint.global_transform
		add_child(robot)

@rpc("any_peer")
func _on_new_player_info(id, username, version):
	if not version == GameManager.version:
		return # Don't make a new player if they are on the wrong version!
	if not GameManager.get_players().has(id):
		var spawn_pos = $PlayerSpawnpoints.get_children()[0].global_position
		GameManager.add_player(id, username, version, spawn_pos)
		print("New player joined: ", username)
		var curr_player = robot_scene.instantiate()
		curr_player.name = str(id)
		curr_player.global_position = spawn_pos
		add_child(curr_player)
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
			var body = objects.get_node(body_name)
			body.linear_velocity = object_data[body_name].linear_velocity
			body.angular_velocity = object_data[body_name].angular_velocity
			if body is ToolAttachment and body.connector.connected:
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
		if not robot:
			return # We don't have a UI if we aren't in the game!
	
	$UI.ball_count = $"Terrain/Dirtballs".get_child_count()
	$UI.fps = $"FPS Counter".fps
	spawn.spawn_rate = $UI.spawn_rate
	$UI.charging = robot.charge_component.charging
	$UI.charge_level = robot.charge_component.charge_level
	$UI.stalling = robot.stuck_stalling
	$UI.can_attach = robot.arm.tool_coupler_component.can_attach
	robot.cam_scene.h_sens = $UI.h_cam_sens
	robot.cam_scene.v_sens = $UI.v_cam_sens
	robot.cam_scene.zoom_sens = $UI.cam_zoom_sens
	robot.cam_scene.invert_cam = $UI.invert_cam
	robot.tp_height = $UI.tp_height
	if robot.arm.tool_coupler_component.current_attachment:
		if robot.arm.tool_coupler_component.current_attachment is Bucket:
			$UI.dirtballs_in_bucket = robot.arm.tool_coupler_component.current_attachment.in_bucket.num_dirtballs
	else:
		$UI.dirtballs_in_bucket = 0
	$UI.dirtballs_in_hopper = robot.hopper.inside_hopper.num_dirtballs
	
	if OS.get_name() == "Android":
		robot.cam_scene.cam_locked = $UI.cam_locked
		robot.ext_input = $UI.left_joystick.get_axis()
		robot.arm.ext_input = $UI.right_joystick.get_axis()

func _on_fallen_area_3d_body_entered(body):
	body.global_transform = $"PlayerSpawnpoints/0".global_transform
	body.linear_velocity = Vector3.ZERO
	body.angular_velocity = Vector3.ZERO