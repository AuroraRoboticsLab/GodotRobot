extends Control

@export var address   = "127.0.0.1"
@export var port: int = 31415 # Pi!

var peer: ENetMultiplayerPeer
@onready var name_textbox = $PanelContainer/VBoxContainer/HBoxContainer2/NameTextEdit

func _ready():
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
		host_game()
	else:
		print("Unable to host (a host already exists!)")
		
func host_game():
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(port, GameManager.max_players)
	if err != OK:
		print("Unable to host: ", err)
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting for players...")

@rpc("any_peer")
func send_player_info(id, username):
	if not GameManager.players.has(id):
		GameManager.players[id] = {
			"username": username
		}
	if multiplayer.is_server():
		for pid in GameManager.players:
			#if id != pid:
			send_player_info.rpc(pid, GameManager.players[pid].username)

@rpc("any_peer", "call_local")
func start_game():
	if not GameManager.game_in_progress:
		GameManager.game_in_progress = true
		var scene = load("res://main3D.tscn").instantiate()
		get_tree().root.add_child(scene)
		self.hide()
	else:
		print("Game already in progress.")

func player_connected(id):
	print("Player Connected (ID ", id, ")")
	
func player_disconnected(id):
	print("Player Disconnected (ID #", id, ")")
	GameManager.players.erase(id)
	var player_node = get_tree().root.get_node_or_null("main3D/" + str(id))
	if player_node:
		player_node.queue_free()
	
func connected_to_server():
	print("Connected to server!")
	send_player_info.rpc_id(1, multiplayer.get_unique_id(), name_textbox.text)
	
func connection_failed():
	print("Connection failed.")

func _on_host_button_pressed():
	host_game()
	send_player_info(multiplayer.get_unique_id(), name_textbox.text)

func _on_join_button_pressed():
	if peer:
		peer.close_connection()
	peer = ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
		

func _on_start_button_pressed():
	start_game.rpc()
