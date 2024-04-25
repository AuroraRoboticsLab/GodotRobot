extends RigidBody3D


@onready var tool_connector = $ConnectorComponent
@onready var current_attachment = null
@onready var bucket = $BucketAttachment
@onready var forks = $ForkAttachment
@onready var referenced_attachment = null
@onready var can_attach: bool = false

func attach():
	if current_attachment:
		referenced_attachment.ghost_component.make_invisible()
		current_attachment.ghost_component.make_visible()
		tool_connector.do_connect(current_attachment.connector)
		current_attachment.connector.do_connect(tool_connector)
		can_attach = false # because we're currently connected!
	else:
		print("WARN: No current attachment!")
		
func detach():
	if current_attachment:
		current_attachment.ghost_component.make_invisible()
		referenced_attachment.ghost_component.make_visible()
		referenced_attachment.global_position = tool_connector.global_position
		referenced_attachment.global_rotation = global_rotation
		
		tool_connector.do_disconnect(current_attachment.connector)
		current_attachment.connector.do_disconnect(tool_connector)
		referenced_attachment = null
		current_attachment = null
		can_attach = true
	else:
		print("WARN: Detaching when have no attachment!")

func _on_connector_component_can_connect(area):
	var body = area.parent
	if body.is_in_group("attachment"): # Check if body is attachment
		referenced_attachment = body # Remember the other body exists
		if body.attachment_type == "bucket":
			current_attachment = bucket
			can_attach = true
		elif body.attachment_type == "forks":
			current_attachment = forks
			can_attach = true
		else:
			print("WARN: Unrecognized attachment!")
	if body.is_in_group("chargeable"):
		pass # Handle if thing is chargeable

func _on_connector_component_must_disconnect(area):
	var body = area.parent
	if tool_connector.connected:
		print("WARN: Connector connected when it shouldn't be!")
		return
	
	tool_connector.nearby_connector = null
	can_attach = false
	current_attachment = null
	referenced_attachment = null



# Old connector logic.

#@onready var joint = null
# Connector for tool can connect
#func _on_connector_component_can_connect(area):
#	var attachment_node = area.parent
#	var new_attachment = attachment_node.duplicate()
#	attachment_node.get_parent().remove_child(attachment_node)
#	get_parent().add_child(new_attachment)
#	tool_connector.nearby_connector = new_attachment.connector
#	new_attachment.connector.nearby_connector = tool_connector
#	
#	new_attachment.global_position = tool_connector.global_position
#	new_attachment.global_rotation = global_rotation
#	current_attachment = new_attachment
#	new_attachment.connector.do_connect(tool_connector)
#	tool_connector.do_connect(new_attachment.connector)
#	
#func _on_connector_component_must_disconnect(area):
#	print("Must disconnect!")
#	get_parent().remove_child(joint)
#	joint = null
#	area.do_disconnect(tool_connector)
#	tool_connector.do_disconnect(area)
#
#func _on_connector_component_just_connected(area):
#	joint = HingeJoint3D.new()
#	get_parent().add_child(joint)
#	joint.global_position = tool_connector.global_position
#	joint.node_a = get_parent().get_path_to(self)
#	joint.node_b = get_parent().get_path_to(current_attachment)
#	joint.set("angular_limit/enable", true)
#	joint.set("angular_limit/upper", 0)
#	joint.set("angular_limit/lower", 0)

