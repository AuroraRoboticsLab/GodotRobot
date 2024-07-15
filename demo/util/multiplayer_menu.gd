extends Control
# NOTE: If hosting a server from the console, be sure to
# add the tags --host AND --headless.

@export var address   = "127.0.0.1"
@export var port: int = 31415 # Pi!

var peer: ENetMultiplayerPeer = null
var scene: Node = null
@onready var main_scene: PackedScene = load("res://levels/main3D.tscn")

func _ready():
	multiplayer.set_multiplayer_peer(null)
	multiplayer.peer_connected.connect(player_connected)
	multiplayer.peer_disconnected.connect(player_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	GameManager.self_disconnected.connect(on_self_disconnected)
	
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
	peer.set_bind_ip(address)
	var err = peer.create_server(port, GameManager.max_players)
	if err != OK:
		print("Unable to host: ", err)
		%AlertLabel.text = "Unable to host: Error #" + str(err)
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(peer)
	if console_host:
		print("Hosting game from console.")
		GameManager.using_multiplayer = true
		GameManager.is_console_host = true
		start_game()
	else:
		%ConnectLabel.text = "Hosting game. Press start game to begin the game."
		$PanelContainer/VBoxContainer/HBoxContainer/StartButton.disabled = false
		update_num_players()
	print("Successfully hosting on ", address, " at port ", port)
	print("Waiting for players...")

@rpc("any_peer")
func send_player_info(id, username):
	if not GameManager.get_players().has(id):
		GameManager.new_player_info.emit(id, username)
		GameManager.add_player(id, username)
		%AlertLabel.text = GameManager.get_player_username(id) + " has connected."
	if multiplayer.is_server():
		for pid in GameManager.get_player_ids():
			if pid != id:
				send_player_info.rpc(pid, GameManager.get_player_username(pid))
			else:
				# Notify the new player of all existing players
				for existing_id in GameManager.get_players():
					if existing_id != id:
						send_player_info.rpc(id, username)
	update_num_players()

# The function called when the host starts the game
@rpc("any_peer", "call_local")
func start_game():
	if not GameManager.game_in_progress:
		GameManager.game_in_progress = true
		scene = main_scene.instantiate()
		get_tree().root.add_child(scene)
		hide_menu()

func player_connected(id):
	print("Player Connected (ID ", id, ")")
	update_num_players()
	
func player_disconnected(id):
	print("Player Disconnected (ID #", id, ")")
	%AlertLabel.text = str(GameManager.get_player_username(id)) + " has disconnected."
	GameManager.remove_player(id)
	var player_node = get_tree().root.get_node_or_null("main3D/" + str(id))
	if player_node:
		player_node.queue_free()
	
	update_num_players()
	
	if id == 1:
		on_host_disconnected.rpc()

func connected_to_server():
	print("Connected to server!")
	send_player_info(multiplayer.get_unique_id(), %NameTextEdit.text)
	send_player_info.rpc_id(1, multiplayer.get_unique_id(), %NameTextEdit.text)
	start_if_ongoing_game.rpc_id(1, multiplayer.get_unique_id())
	update_num_players()

func connection_failed():
	multiplayer.set_multiplayer_peer(null)
	print("Connection failed.")
	%ConnectLabel.text = ""
	%AlertLabel.text = "Connection failed."

@rpc("any_peer", "call_local")
func on_host_disconnected():
	print("Host has disconnected, returning to menu.")
	leave_game("The host has disconnected.")

func on_self_disconnected():
	print("Disconnected, returning to menu.")
	leave_game("You have disconnected.")
		
func leave_game(message):
	GameManager.end_game()
	multiplayer.set_multiplayer_peer(null)  # Disconnect the peer
	update_num_players()
	show_menu(message)
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
	GameManager.using_multiplayer = true
	address = %AddressTextEdit.text
	port = %PortTextEdit.text.to_int()
	print("Attempting to become host at ", address, " on port ", port)
	if multiplayer.get_multiplayer_peer(): # Can't join if we have a peer already!
		print("Already connected to a peer.")
		%AlertLabel.text = "Cannot host: Already connected to a peer."
		return
	if not host_exists():
		host_game()
		send_player_info(multiplayer.get_unique_id(), %NameTextEdit.text)
	else:
		print("Host already exists.")
		%AlertLabel.text = "Cannot host: Host already exists."

func _on_join_button_pressed():
	GameManager.using_multiplayer = true
	address = %AddressTextEdit.text
	port = %PortTextEdit.text.to_int()
	print("Attempting to join host at ", address, " on port ", port)
	if multiplayer.get_multiplayer_peer(): # Can't join if we have a peer already!
		print("Already connected to a peer.")
		%AlertLabel.text = "Cannot join: Already connected to a peer."
		return
	peer = ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	#peer.set_bind_ip(address)
	
	if host_exists(): # If server responded
		# If game is ongoing, start locally.
		%ConnectLabel.text = "Attempting to join game..."
	else:
		%AlertLabel.text = "Cannot join: Host not found."
		multiplayer.set_multiplayer_peer(null)

# Try to become a host. If we can, there isn't a host to be found.
func host_exists():
	var temp_peer = ENetMultiplayerPeer.new()
	temp_peer.set_bind_ip(address)
	var err = temp_peer.create_server(port, GameManager.max_players)
	if err != OK:
		print(err)
		return true
	else:
		temp_peer.close()
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
	if multiplayer.get_unique_id() == 1 and GameManager.game_in_progress:
		start_game.rpc_id(querying_id)

func _on_local_game_button_pressed():
	GameManager.using_multiplayer = false
	scene = main_scene.instantiate()
	get_tree().root.add_child(scene)
	queue_free()
