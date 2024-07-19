extends StaticBody3D
# TODO: Instead of using fake tools, use real tools that are connected by
# an instantiated joint that gets removed when someone attaches to the tool.
# (is this possible?)
# OR, spawn real tools, and when the tool leaves an Area3D,
# spawn a new tool in its place. 
# Either of these alternate methods would allow us to drag/drop tools into
# exported variables!

const bucket_path = "res://astra/tool_attachments/bucket_attachment.tscn"
var can_spawn_bucket: bool = true
const forks_path = "res://astra/tool_attachments/fork/forks.tscn"
var can_spawn_forks: bool = true
const sawblade_path = "res://astra/tool_attachments/sawblade/saw_blade_attachment.tscn"
var can_spawn_sawblade: bool = true

func _on_bucket_area_3d_area_entered(area):
	if can_spawn_bucket:
		if GameManager.using_multiplayer and multiplayer.is_server():
			_spawn_new_tool(area, bucket_path, $BucketPlaceholder.global_transform)
			can_spawn_bucket = false
			_hide_bucket.rpc()
		elif not GameManager.using_multiplayer:
			_spawn_new_tool(area, bucket_path, $BucketPlaceholder.global_transform)
			can_spawn_bucket = false
			_hide_bucket()

@rpc("any_peer", "call_local")
func _hide_bucket():
	$BucketPlaceholder.hide()
	$BucketPlaceholder/BucketTimer.start()

func _on_bucket_timer_timeout():
	can_spawn_bucket = true
	$BucketPlaceholder.show()

func _on_fork_area_3d_area_entered(area):
	if can_spawn_forks:
		if GameManager.using_multiplayer and multiplayer.is_server():
			_spawn_new_tool(area, forks_path, $ForksPlaceholder.global_transform)
			can_spawn_forks = false
			_hide_forks.rpc()
		elif not GameManager.using_multiplayer:
			_spawn_new_tool(area, forks_path, $ForksPlaceholder.global_transform)
			can_spawn_forks = false
			_hide_forks()

@rpc("any_peer", "call_local")
func _hide_forks():
	$ForksPlaceholder.hide()
	$ForksPlaceholder/ForksTimer.start()

func _on_forks_timer_timeout():
	can_spawn_forks = true
	$ForksPlaceholder.show()

func _on_sawblade_area_3d_area_entered(area):
	if can_spawn_sawblade:
		if GameManager.using_multiplayer and multiplayer.is_server():
			_spawn_new_tool(area, sawblade_path, $SawbladePlaceholder.global_transform)
			can_spawn_sawblade = false
			_hide_sawblade.rpc()
		elif not GameManager.using_multiplayer:
			_spawn_new_tool(area, sawblade_path, $SawbladePlaceholder.global_transform)
			can_spawn_sawblade = false
			_hide_sawblade()

@rpc("any_peer", "call_local")
func _hide_sawblade():
	$SawbladePlaceholder.hide()
	$SawbladePlaceholder/SawbladeTimer.start()

func _on_sawblade_timer_timeout():
	can_spawn_sawblade = true
	$SawbladePlaceholder.show()

func _spawn_new_tool(area, tool_path, tool_trans):
	if area is ToolCoupler and not area.connected:
		var new_tool = load(tool_path).instantiate()
		new_tool.global_transform = tool_trans
		get_parent().objects.add_child(new_tool, true)
		if GameManager.using_multiplayer:
			GameManager.add_object(new_tool, tool_path)
			GameManager.new_object.emit(multiplayer.get_unique_id(), tool_path, new_tool.name)
