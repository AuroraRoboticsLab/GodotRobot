extends StaticBody3D

# The bodies in each tool space
var tool_space_bodies = [null, null, null]
# The scenes for each tool
@export var tool_1_scene: PackedScene = null
@export var tool_2_scene: PackedScene = null
@export var tool_3_scene: PackedScene = null

func _on_tool_space_1_body_exited(body):
	if tool_space_bodies[0] and body.name == tool_space_bodies[0].name:
		tool_space_bodies[0] = null
		$ToolSpace1/ToolTimer1.start()

func _on_tool_timer_1_timeout():
	if GameManager.using_multiplayer and multiplayer.is_server():
		_spawn_new_tool(0, tool_1_scene, $ToolSpace1.global_transform)
	elif not GameManager.using_multiplayer:
		_spawn_new_tool(0, tool_1_scene, $ToolSpace1.global_transform)

func _on_tool_space_2_body_exited(body):
	if tool_space_bodies[1] and body.name == tool_space_bodies[1].name:
		tool_space_bodies[1] = null
		$ToolSpace2/ToolTimer2.start()

func _on_tool_timer_2_timeout():
	if GameManager.using_multiplayer and multiplayer.is_server():
		_spawn_new_tool(1, tool_2_scene, $ToolSpace2.global_transform)
	elif not GameManager.using_multiplayer:
		_spawn_new_tool(1, tool_2_scene, $ToolSpace2.global_transform)

func _on_tool_space_3_body_exited(body):
	if tool_space_bodies[2] and body.name == tool_space_bodies[2].name:
		tool_space_bodies[2] = null
		$ToolSpace3/ToolTimer3.start()

func _on_tool_timer_3_timeout():
	if GameManager.using_multiplayer and multiplayer.is_server():
		_spawn_new_tool(2, tool_3_scene, $ToolSpace3.global_transform)
	elif not GameManager.using_multiplayer:
		_spawn_new_tool(2, tool_3_scene, $ToolSpace3.global_transform)

func _spawn_new_tool(space_num, tool_scene, tool_trans):
	if not tool_scene:
		return
	var new_tool = tool_scene.instantiate()
	tool_space_bodies[space_num] = new_tool
	new_tool.global_transform = tool_trans
	GameManager.add_local_object.emit(new_tool, true)
	if GameManager.using_multiplayer:
		GameManager.add_object(new_tool, new_tool.path, tool_trans)
