extends Node

var players = {}
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

func end_game():
	game_in_progress = false
	players = {}

func get_num_players():
	return len(players)
	
func remove_player(id):
	players.erase(id)
