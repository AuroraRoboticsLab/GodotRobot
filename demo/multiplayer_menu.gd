extends Control
# NOTE: If hosting a server from the console, be sure to
# add the tags --host AND --headless.

@export var address   = "127.0.0.1"
@export var port: int = 31415 # Pi!

var peer: ENetMultiplayerPeer = null
var scene: Node = null
@onready var name_textbox = $PanelContainer/VBoxContainer/HBoxContainer2/NameTextEdit

func _ready():
	multiplayer.set_multiplayer_peer(null)
	multiplayer.peer_connected.connect(player_connected)
	multiplayer.peer_disconnected.connect(player_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	
	var arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
		else:
			# Options without an argument will be present in the dictionary,
			# with the value set to an empty string.
			arguments[argument.lstrip("--")] = ""
	
	if "port" in arguments:
		port = arguments["port"].to_int()
	if "address" in arguments:
		address = arguments["address"]
	if "host" in arguments:
		host_game(true)


func host_game(console_host=false):
	if host_exists():
		print("Host already exists!")
		return
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(port, GameManager.max_players)
	if err != OK:
		print("Unable to host: ", err)
		%AlertLabel.text = "Unable to host: Error #" + str(err)
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(peer)
	if console_host:
		print("Hosting game from console.")
		start_game()
	else:
		%ConnectLabel.text = "Hosting game. Press start game to begin the game."
		$PanelContainer/VBoxContainer/HBoxContainer/StartButton.disabled = false
		update_num_players()
	print("Waiting for players...")

@rpc("any_peer")
func send_player_info(id, username):
	if not GameManager.players.has(id):
		GameManager.new_player_info.emit(id, username)
		GameManager.players[id] = {
			"username": username
		}
		%AlertLabel.text = str(username) + " has connected."
	if multiplayer.is_server():
		for pid in GameManager.players:
			if pid != id:
				send_player_info.rpc(pid, GameManager.players[pid].username)
			else:
				# Notify the new player of all existing players
				for existing_id in GameManager.players:
					if existing_id != id:
						send_player_info.rpc(id, GameManager.players[existing_id].username)
	update_num_players()

# The function called when the host starts the game
@rpc("any_peer", "call_local")
func start_game():
	if not GameManager.game_in_progress:
		GameManager.game_in_progress = true
		scene = load("res://main3D.tscn").instantiate()
		get_tree().root.add_child(scene)
		hide_menu()
		

func player_connected(id):
	print("Player Connected (ID ", id, ")")
	update_num_players()
	
func player_disconnected(id):
	print("Player Disconnected (ID #", id, ")")
	%AlertLabel.text = str(GameManager.players[id]["username"]) + " has disconnected."
	GameManager.remove_player(id)
	var player_node = get_tree().root.get_node_or_null("main3D/" + str(id))
	if player_node:
		player_node.queue_free()
	
	update_num_players()
	
	if id == 1:
		on_host_disconnected.rpc()

func connected_to_server():
	print("Connected to server!")
	send_player_info.rpc_id(1, multiplayer.get_unique_id(), name_textbox.text)
	print("Checking for ongoing game...")
	start_if_ongoing_game.rpc_id(1, multiplayer.get_unique_id())
	update_num_players()

func connection_failed():
	print("Connection failed.")

@rpc("any_peer", "call_local")
func on_host_disconnected():
	print("Host has disconnected, returning to menu.")
	GameManager.end_game()
	multiplayer.set_multiplayer_peer(null)  # Disconnect the peer
	update_num_players()
	show_menu("The host has disconnected.")
	if scene:
		scene.queue_free()

func show_menu(message: String):
	self.show()
	%AlertLabel.text = message
	%ConnectLabel.text = ""
	$PanelContainer/VBoxContainer/HBoxContainer/StartButton.disabled = true
	
func hide_menu():
	self.hide()

func _on_host_button_pressed():
	if multiplayer.get_multiplayer_peer(): # Can't join if we have a peer already!
		print("Has peer!")
		%AlertLabel.text = "Cannot host: Already connected to a peer."
		return
	if not host_exists():
		host_game()
		send_player_info(multiplayer.get_unique_id(), name_textbox.text)
	else:
		print("Host already exists.")
		%AlertLabel.text = "Cannot host: Host already exists."

# TODO: Allow player to spawn into game when game has already started.
#       OR, notify the joining player that a game is in progress and
#       they must wait for a new game to begin (which is most desirable?)
func _on_join_button_pressed():
	if multiplayer.get_multiplayer_peer(): # Can't join if we have a peer already!
		print("Has peer!")
		%AlertLabel.text = "Cannot join: Already connected to a peer."
		return
	peer = ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	
	if host_exists(): # If server responded
		# If game is ongoing, start locally.
		%ConnectLabel.text = "Joined game. Waiting for game to start..."
	else:
		%AlertLabel.text = "Cannot join: Host not found."
		multiplayer.set_multiplayer_peer(null)

# Try to become a host. If we can, there isn't a host to be found.
func host_exists():
	var temp_peer = ENetMultiplayerPeer.new()
	var err = temp_peer.create_server(port, GameManager.max_players)
	if err != OK:
		return true
	else:
		return false

func _on_start_button_pressed():
	start_game.rpc()
	
func update_num_players():
	if GameManager.get_num_players() > 0:
		%NumPlayersContainer.show()
		%NumPlayers.text = str(GameManager.get_num_players()) + "/" + str(GameManager.max_players)
	else:
		%NumPlayersContainer.hide()
		
@rpc("any_peer")
func start_if_ongoing_game(querying_id):
	print("Checking for ongoing game in ", multiplayer.get_unique_id())
	if multiplayer.get_unique_id() == 1 and GameManager.game_in_progress:
		start_game.rpc_id(querying_id)
