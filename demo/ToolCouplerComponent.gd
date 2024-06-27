extends Node3D
# ToolCouplerComponent
# Wrapper around connector component strictly for tool coupling logic.
# Expects to be the child of a RigidBody3D

@onready var tool_connector = $ConnectorComponent
@onready var current_attachment = null:
	get:
		return current_attachment
	set(value):
		current_attachment = value
		if value:
			current_attachment_path = value.get_path()
		else:
			current_attachment_path = ""
var current_attachment_path: String = ""
@onready var can_attach: bool = false
@onready var curr_joint: Generic6DOFJoint3D = null

func _ready():
	add_to_group("tool_coupler")

# Attempt to attach or detach
func try_toggle_attach():
	if can_attach and not tool_connector.connected and current_attachment:
		_attach.rpc()
		#_attach()
	elif tool_connector.connected and tool_connector.nearby_connector:
		_detach.rpc()
		#_detach()
	else:
		print("Cannot attach or detach!")

func _relocate_tool(node, to_node):
	#print("Relocating tool!")
	if to_node and node:
		node.get_parent().remove_child(node)
		to_node.add_child(node)

# Attach to nearby attachment
# Invariants:
#   A tool attachment is nearby
#   We are not already connected
@rpc("any_peer", "call_local")
func _attach():
	if not current_attachment and current_attachment_path != "":
		current_attachment = get_node(NodePath(current_attachment_path))
	
	# Connect connector components
	current_attachment.connector.do_connect(tool_connector)
	tool_connector.do_connect(current_attachment.connector)

# Detach from current attachment
# Invariants:
#   We are currently connected to an attachment
@rpc("any_peer", "call_local")
func _detach():
	# Remove the joint
	curr_joint.queue_free()
	curr_joint = null
	
	var curr_attach_trans = current_attachment.global_transform
	_relocate_tool(current_attachment, get_tree().root.get_children()[0])
	#current_attachment.get_parent().remove_child(current_attachment)
	#get_tree().root.get_children()[0].add_child(current_attachment)
	current_attachment.global_transform = curr_attach_trans
	
	current_attachment.connector.do_disconnect(tool_connector)
	tool_connector.do_disconnect(current_attachment.connector)
	
	current_attachment = null
	can_attach = false

# Another connector is nearby
# Invariants:
#   area is a connector
func _on_connector_component_can_connect(area):
	#print("can connect!")
	var body = area.parent
	if body.is_in_group("attachment"): # Body is an attachment
		current_attachment = body
		can_attach = true
		
func _on_connector_component_just_connected(_area):
	# Stick bodies together
	curr_joint = Generic6DOFJoint3D.new()
	curr_joint.global_transform = global_transform
	var grandparent = get_parent().get_parent()
	grandparent.add_child(curr_joint)
	
	_relocate_tool(current_attachment, grandparent)
	# Remove the current attachment from its current location
	#current_attachment.get_parent().remove_child(current_attachment)
	# Make its new location under our parent
	#grandparent.add_child(current_attachment)
	
	current_attachment.global_transform = get_parent().global_transform
	current_attachment.global_position = tool_connector.global_position

	curr_joint.global_transform = global_transform
	curr_joint.set_node_a(get_parent().get_path())
	curr_joint.set_node_b(current_attachment.get_path())
	can_attach = false

func _on_connector_component_must_disconnect(_area):
	if not tool_connector.connected: # Because position changes during attach trigger function
		tool_connector.nearby_connector = null
		can_attach = false
		current_attachment = null
