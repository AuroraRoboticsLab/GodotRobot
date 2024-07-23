extends Node
const version="v0.2.6-alpha"

var sync_data = {
	"players":{},
	"objects":{},
	"static_bodies":{},
}

var max_players: int = 4:
	set(value):
		if value > 32:
			print("Server player limit is 32 (received ", value, "). Setting max players to 32.")
			max_players = 32
		elif value <= 0:
			print("Server must have at least one player (received ", value, "). Setting max players to 1.")
			max_players = 1
		else:
			max_players = value
var num_spawns = 4
var game_in_progress: bool = false
var is_console_host: bool = false
var using_multiplayer: bool = false
var is_npc: bool = false

signal new_player_info(id, username, version)
signal new_object(sender_id, body_path, body_name)
signal self_disconnected
signal toggle_inputs(in_bool)
signal network_process(delta)

var time: float = 0
const network_process_interval = 0.04
var last_network_process = 0
var network_process_delta = time - last_network_process

var new_player_data = {} # Players
var new_object_data = {} # Rigid bodies
var new_static_data = {} # Static bodies

func _ready():
	# Connect the network process signal and function
	network_process.connect(_network_process)

func _process(delta):
	# Handle network process intervals
	if not using_multiplayer:
		return
	time += delta
	network_process_delta = time - last_network_process
	if network_process_delta >= network_process_interval:
		network_process.emit(network_process_delta)
		last_network_process = time
	

func _network_process(_delta):
	var new_sync_data = {
		"players": new_player_data, 
		"objects": new_object_data,
		"static_bodies": new_static_data
	}
	
	if game_in_progress:
		if multiplayer.is_server():
			set_data(multiplayer.get_unique_id(), new_sync_data)
		else:
			set_data.rpc_id(1, multiplayer.get_unique_id(), new_sync_data)
	new_player_data = {}
	new_object_data = {}
	new_static_data = {}

# Update player id's data with datapoints in new_data
@rpc("any_peer")
func set_data(sender_id, new_data):
	# Handle player data
	for datapoint in new_data.players.keys():
		sync_data.players[sender_id][datapoint] = new_data.players[datapoint]
	
	# Handle instantiated object data
	for object_name in new_data.objects.keys(): # Get object names
		if sync_data.objects.has(object_name):
			for datapoint in new_data.objects[object_name].keys():
				sync_data.objects[object_name][datapoint] = new_data.objects[object_name][datapoint]
		else: # If we don't have the object, make it!
			new_object.emit(sender_id, new_data.objects[object_name].body_path, object_name, new_data.objects[object_name].global_transform)
	
	# Handle static bodies
	for body_name in new_data.static_bodies.keys(): # Get each static body
		if sync_data.static_bodies.has(body_name):# If we don't have the object, we must be loading in.
			for datapoint in new_data.static_bodies[body_name].keys(): # Get each property of static body
				sync_data.static_bodies[body_name][datapoint] = new_data.static_bodies[body_name][datapoint]
	
	# The server must inform all other players of the updated information.
	if multiplayer.is_server():
		for pid in get_player_ids():
			# Tell everyone but the player and ourselves
			if pid != sender_id and pid != 1:
				set_data.rpc_id(pid, sender_id, new_data)

func add_new_player_data(new_data):
	new_player_data.merge(new_data)

func add_new_object_data(new_data):
	new_object_data.merge(new_data)

func add_new_static_data(new_data):
	new_static_data.merge(new_data)

# Do everything on our side to show the game has ended
func end_game():
	game_in_progress = false
	sync_data = {
		"players":{},
		"objects":{},
		"static_bodies":{},
	}

# Return the dictionary of all players
func get_players():
	return sync_data.players

func get_player_ids():
	return get_players().keys()

# Return the number of players connected
func get_num_players():
	return len(get_players())

# Add a new player to the players dictionary
func add_player(id: int, username, in_version, pos=Vector3.ZERO):
	if not sync_data.players.has(id):
		sync_data.players[id] = {
			"username": username,
			"version": in_version,
			"global_position": pos,
			"linear_velocity": Vector3.ZERO,
			"angular_velocity": Vector3.ZERO,
			"quaternion": Quaternion.IDENTITY,
			"remaining_amp_hours": 100.0,
			"curr_attach_path": "",
			"joint_data": [0.0, 0.0, 0.0]
		}

# Remove a player from the players dictionary
func remove_player(id):
	sync_data.players.erase(id)

# Return the username of a given player
func get_player_username(id):
	if get_players().has(id):
		return get_players()[id].username
	else:
		return null

func get_player_version(id):
	if get_players().has(id):
		return get_players()[id].version
	else:
		return null

# Returns a player's in-game data dictionary (which has position, rotation, etc.)
func get_player_data(id):
	if get_players().has(id):
		return get_players()[id]
	else:
		return null # Player must have disconnected.

func get_objects():
	return sync_data.objects

func get_object_names():
	return get_objects().keys()

func add_object(body, body_path, trans=Transform3D.IDENTITY):
	if not sync_data.objects.has(body.name):
		sync_data.objects[body.name] = {
			"global_transform": trans,
			"linear_velocity": Vector3.ZERO,
			"angular_velocity": Vector3.ZERO,
			"body_path": body_path,
		}

func remove_object(body):
	sync_data.objects.erase(body.name)

func get_object_data(body_name):
	return get_objects()[body_name]

func add_static_body(body):
	if not sync_data.static_bodies.has(body.name):
		sync_data.static_bodies[body.name] = {
			"curr_mass": 0.0,
			"remaining_amp_hours": 0.0,
		}

func get_static_bodies():
	return sync_data.static_bodies

func get_static_data(body_name):
	if get_static_bodies().has(body_name):
		return get_static_bodies()[body_name]
	else:
		return null

