extends Control
# NOTE: If hosting a server from the console, be sure to
# add the tags --host AND --headless.

@export var address   = "127.0.0.1":
	set(value):
		address = IP.resolve_hostname(value)
@export var port: int = 31415 # Pi!

var peer: ENetMultiplayerPeer = null
var scene: Node = null
@onready var main_scene: PackedScene = load("res://levels/main3D.tscn")

var debugging_console_host = false

func _ready():
	multiplayer.set_multiplayer_peer(null)
	multiplayer.peer_connected.connect(player_connected)
	multiplayer.peer_disconnected.connect(player_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	GameManager.self_disconnected.connect(on_self_disconnected)
	
	$VersionLabel.text = str(GameManager.version)
	
	var arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
		else:
			# Options without an argument will be present in the dictionary,
			# with the value set to an empty string.
			arguments[argument.lstrip("--")] = ""
	
	if "game-version" in arguments:
		print(GameManager.version)
		get_tree().quit()
	if "port" in arguments:
		port = arguments["port"].to_int()
	if "address" in arguments:
		address = arguments["address"]
	if "maxplayers" in arguments:
		GameManager.max_players = arguments["maxplayers"].to_int()
	if "disable-chat" in arguments:
		GameManager.using_chat = false
	if "host" in arguments:
		GameManager.using_multiplayer = true
		host_game(true)

func host_game(console_host=false):
	GameManager.is_console_host = console_host
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
		start_game.rpc()
	else:
		%ConnectLabel.text = "Hosting game. Press start game to begin the game."
		$PanelContainer/VBoxContainer/HBoxContainer/StartButton.disabled = false
		update_num_players()
	print("Successfully hosting on ", address, " at port ", port)
	print("Waiting for players...")

@rpc("any_peer")
func send_player_info(id, username, version, player_choice):
	if multiplayer.is_server():
		if id != 1 and version != GameManager.version: # Version mismatch!
			GameManager.remove_player(id)
			_throw_version_mismatch.rpc_id(id, GameManager.version)
			return
	if not GameManager.get_players().has(id) and version == GameManager.version:
		GameManager.new_player_info.emit(id, username, version, player_choice)
		GameManager.add_player(id, username, version, player_choice)
		%AlertLabel.text = GameManager.get_player_username(id) + " has connected."
	if multiplayer.is_server():
		for pid in GameManager.get_player_ids():
			if pid != id:
				send_player_info.rpc(pid, GameManager.get_player_username(pid), GameManager.get_player_version(pid), GameManager.get_player_choice(pid))
			else:
				# Notify the new player of all existing players
				for existing_id in GameManager.get_players():
					if existing_id != id:
						send_player_info.rpc(id, username, version, player_choice)
	update_num_players()

@rpc("any_peer")
func _throw_version_mismatch(host_version):
	multiplayer.set_multiplayer_peer(null)
	leave_game("Version mismatch! Host is using "+str(host_version)+".")

# The function called when the host starts the game
@rpc("any_peer", "call_local")
func start_game():
	if not GameManager.game_in_progress:
		GameManager.game_in_progress = true
		scene = main_scene.instantiate()
		get_tree().root.add_child.call_deferred(scene)
		hide_menu()

func player_connected(id):
	print("Player Connected (ID ", id, ")")
	update_num_players()
	
func player_disconnected(id):
	print("Player Disconnected (ID ", id, ")")
	if GameManager.get_player_username(id):
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
	send_player_info(multiplayer.get_unique_id(), %NameTextEdit.text, GameManager.version, GameManager.player_choice)
	send_player_info.rpc_id(1, multiplayer.get_unique_id(), %NameTextEdit.text, GameManager.version, GameManager.player_choice)
	start_if_ongoing_game.rpc_id(1, multiplayer.get_unique_id(), GameManager.version)
	%ConnectLabel.text = "Connected. Waiting for game to start..."
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
	if GameManager.using_multiplayer:
		leave_game("You have disconnected.")
	else:
		leave_game("Left local game.")
		
func leave_game(message):
	GameManager.end_game()
	if GameManager.using_multiplayer:
		multiplayer.set_multiplayer_peer(null)  # Disconnect the peer
	update_num_players()
	show_menu(message)
	if scene:
		scene.queue_free()
		scene = null

func show_menu(message: String):
	self.show()
	%AlertLabel.text = message
	%ConnectLabel.text = ""
	$PanelContainer/VBoxContainer/HBoxContainer/StartButton.disabled = true
	
func hide_menu():
	self.hide()

func set_character_text():
	$PanelContainer/VBoxContainer/HBoxContainer2/OptionButton.hide()
	var character_text = ""
	match GameManager.player_choice:
		GameManager.Character.ASTRO:
			character_text = "Astronaut"
		GameManager.Character.ASTRA:
			character_text = "Astra"
		GameManager.Character.EXCAH:
			character_text = "Excahauler"
		GameManager.Character.SPECT:
			character_text = "Spectator"
	$PanelContainer/VBoxContainer/HBoxContainer2/Label2.text = character_text

func _on_host_button_pressed():
	set_character_text()
	
	%AlertLabel.text = ""
	GameManager.using_multiplayer = true
	address = %AddressTextEdit.text
	port = %PortTextEdit.text.to_int()
	print("Attempting to become host at ", address, " on port ", port)
	if multiplayer.get_multiplayer_peer(): # Can't join if we have a peer already!
		print("Already connected to a peer.")
		%AlertLabel.text = "Cannot host: Already connected to a peer."
		return
	if not host_exists():
		host_game(debugging_console_host)
		if not debugging_console_host:
			send_player_info(multiplayer.get_unique_id(), %NameTextEdit.text, GameManager.version, GameManager.player_choice)
	else:
		print("Host already exists.")
		%AlertLabel.text = "Cannot host: Host already exists."

func _on_join_button_pressed():
	set_character_text()
	
	%AlertLabel.text = ""
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
		update_num_players()
	else:
		%AlertLabel.text = "Cannot join: Host not found."
		multiplayer.set_multiplayer_peer(null)

# Try to become a host. If we can, there isn't a host to be found.
func host_exists():
	var temp_peer = ENetMultiplayerPeer.new()
	temp_peer.set_bind_ip(address)
	var err = temp_peer.create_server(port, GameManager.max_players)
	if err != OK:
		return true
	else:
		temp_peer.close()
		return false

func _on_start_button_pressed():
	start_game.rpc()
	
func update_num_players():
	if multiplayer.get_multiplayer_peer() and GameManager.get_num_players() > 0:
		%NumPlayersContainer.show()
		%NumPlayers.text = str(GameManager.get_num_players()) + "/" + str(GameManager.max_players)
	else:
		%NumPlayersContainer.hide()
		
@rpc("any_peer")
func start_if_ongoing_game(querying_id, version):
	if multiplayer.get_unique_id() == 1 and GameManager.game_in_progress:
		if version != GameManager.version:
			GameManager.remove_player(querying_id)
			_throw_version_mismatch.rpc_id(querying_id, GameManager.version)
		else:
			start_game.rpc_id(querying_id)

func _on_local_game_button_pressed():
	GameManager.using_multiplayer = false
	scene = main_scene.instantiate()
	get_tree().root.add_child(scene)
	hide()

func _on_leave_game_button_pressed():
	if multiplayer.get_multiplayer_peer() or peer:
		multiplayer.set_multiplayer_peer(null)
		peer = null
		%AlertLabel.text = "Disconnected from peer."
		%ConnectLabel.text = ""
		$PanelContainer/VBoxContainer/HBoxContainer/StartButton.disabled = true
		$PanelContainer/VBoxContainer/HBoxContainer2/Label2.text = "Player Type: "
		$PanelContainer/VBoxContainer/HBoxContainer2/OptionButton.show()
		GameManager.end_game()
		update_num_players()
	else:
		get_tree().quit() # Exit program

func _on_option_button_item_selected(index):
	GameManager.player_choice = index
