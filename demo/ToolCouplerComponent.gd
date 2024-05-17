extends Node3D
# ToolCouplerComponent
# Wrapper around connector component strictly for tool coupling logic.
# Expects to be the child of a RigidBody3D

@onready var tool_connector = $ConnectorComponent
@onready var current_attachment = null
@onready var can_attach: bool = false
@onready var curr_joint: Generic6DOFJoint3D = null

func _ready():
	add_to_group("tool_coupler")

# Attempt to attach or detach
func try_toggle_attach():
	if can_attach and not tool_connector.connected and current_attachment:
		_attach()
	elif tool_connector.connected and tool_connector.nearby_connector:
		_detach()
	else:
		print("Cannot attach or detach!")

# Attach to nearby attachment
# Invariants:
#   A tool attachment is nearby
#   We are not already connected
func _attach():
	print("attaching")
	# Connect connector components
	current_attachment.connector.do_connect(tool_connector)
	tool_connector.do_connect(current_attachment.connector)

# Detach from current attachment
# Invariants:
#   We are currently connected to an attachment
func _detach():
	# Remove the joint
	curr_joint.queue_free()
	curr_joint = null
	
	var curr_attach_trans = current_attachment.global_transform
	current_attachment.get_parent().remove_child(current_attachment)
	get_tree().root.get_children()[0].add_child(current_attachment)
	current_attachment.global_transform = curr_attach_trans
	
	current_attachment.connector.do_disconnect(tool_connector)
	tool_connector.do_disconnect(current_attachment.connector)
	
	current_attachment = null
	can_attach = false

# Another connector is nearby
# Invariants:
#   area is a connector
func _on_connector_component_can_connect(area):
	print("can connect!")
	var body = area.parent
	if body.is_in_group("attachment"): # Body is an attachment
		current_attachment = body
		can_attach = true
		
func _on_connector_component_just_connected(area):
	# Stick bodies together
	curr_joint = Generic6DOFJoint3D.new()
	curr_joint.global_transform = global_transform
	var grandparent = get_parent().get_parent()
	grandparent.add_child(curr_joint)
	# Remove the current attachment from its current location
	current_attachment.get_parent().remove_child(current_attachment)
	# Make its new location under our parent
	grandparent.add_child(current_attachment)
	
	current_attachment.global_transform = get_parent().global_transform
	current_attachment.global_position = tool_connector.global_position

	curr_joint.global_transform = global_transform
	curr_joint.set_node_a(get_parent().get_path())
	curr_joint.set_node_b(current_attachment.get_path())
	can_attach = false

func _on_connector_component_must_disconnect(area):
	if not tool_connector.connected: # Because position changes during attach trigger function
		tool_connector.nearby_connector = null
		can_attach = false
		current_attachment = null
