extends Node

var sync_data = {"players":{}}

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

signal new_player_info(id, username)
signal self_disconnected
signal toggle_inputs
signal network_process(delta)

var time: float = 0
const network_process_interval = 0.1
var last_network_process = 0
var network_process_delta = time - last_network_process

var new_player_data = {}

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
	if new_player_data == {}:
		return # No new data, no need to update!
	
	print(new_player_data["arm_data"])
	if multiplayer.is_server():
		GameManager.set_player_data(multiplayer.get_unique_id(), new_player_data)
	else:
		GameManager.set_player_data.rpc_id(1, multiplayer.get_unique_id(), new_player_data)
	new_player_data = {}

func add_new_player_data(new_data):
	new_player_data.merge(new_data)

# Do everything on our side to show the game has ended
func end_game():
	game_in_progress = false
	sync_data = {"players":{}}

# Return the dictionary of all players
func get_players():
	return sync_data.players

func get_player_ids():
	return get_players().keys()

# Return the number of players connected
func get_num_players():
	return len(get_players())

# Add a new player to the players dictionary
func add_player(id: int, username):
	sync_data.players[id] = {
		"username": username,
		"global_position": Vector3.ZERO,
		"quaternion": Quaternion.IDENTITY,
		"remaining_amp_hours": 100.0,
		"arm_data": [Transform3D.IDENTITY, Transform3D.IDENTITY, Transform3D.IDENTITY],
		"joint_data": [0.0, 0.0, 0.0]
	}

# Remove a player from the players dictionary
func remove_player(id):
	sync_data.players.erase(id)

# Return the username of a given player
func get_player_username(id):
	return get_players()[id].username

# Returns a player's in-game data dictionary (which has position, rotation, etc.)
func get_player_data(id):
	return get_players()[id]

# Update player id's data with datapoints in new_data
@rpc("any_peer")
func set_player_data(id, new_data):
	for datapoint in new_data.keys():
		sync_data.players[id][datapoint] = new_data[datapoint]
	
	# The server must inform all other players of the updated information.
	if multiplayer.is_server():
		for pid in get_player_ids():
			# Tell everyone but the player and ourselves
			if pid != id and pid != 1:
				set_player_data.rpc_id(pid, id, new_data)



