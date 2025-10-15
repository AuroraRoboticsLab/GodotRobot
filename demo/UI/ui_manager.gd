extends Node

# UI to world
signal new_cam_sens(cam_sens: Vector2)
signal new_zoom_sens(zoom_sens: float)
signal new_cam_inv(cam_inv: bool)
signal new_spawn_rate(spawn_rate: int)
signal new_tp_h(tp_h: int)

# World to UI
signal new_fps(fps: float)
signal new_ball_count(ball_count: int)

# Messaging
signal sent_message(message)

@rpc("any_peer")
func try_send_chat_message(sender_id, message):
	if multiplayer.is_server():
		if GameManager.using_chat:
			send_chat_message.rpc(message)
		else:
			send_chat_message.rpc_id(sender_id, "Host has disabled chat!")

@rpc("any_peer", "call_local")
func send_chat_message(message):
	sent_message.emit(message)
