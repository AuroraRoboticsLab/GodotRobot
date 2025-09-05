extends Connector
class_name ToolCoupler
# ToolCouplerComponent
# Wrapper around connector component strictly for tool coupling logic.
# Expects to be the child of a RigidBody3D

signal add_joint(curr_joint: Generic6DOFJoint3D)

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

# Attempt to attach or detach
func try_toggle_attach():
	if can_attach and not connected and current_attachment:
		if GameManager.using_multiplayer:
			if multiplayer.is_server():
				_attach.rpc(1)
			else:
				_attach.rpc_id(1, multiplayer.get_unique_id())
		else:
			_attach()
	elif connected and nearby_connector:
		if GameManager.using_multiplayer:
			_detach.rpc()
		else:
			_detach()
	else:
		print("Cannot attach or detach!")

# Attach to nearby attachment
# Invariants:
#   A tool attachment is nearby
#   We are not already connected
@rpc("any_peer", "call_local")
func _attach(sender_id=null):
	if sender_id and sender_id != 1:
		if can_attach and current_attachment and not current_attachment.connector.connected:
			_attach.rpc(1)
		elif current_attachment:
			# Fixes when players leave while holding attachment
			if not current_attachment.connector.nearby_connector:
				current_attachment.connector.do_disconnect()
				_attach.rpc(1)
			return
		else:
			return
			
	if not current_attachment and current_attachment_path != "":
		current_attachment = get_node(NodePath(current_attachment_path))
	if not current_attachment:
		return
	
	# Connect connector components
	current_attachment.connector.do_connect(self)
	do_connect(current_attachment.connector)

# Detach from current attachment
# Invariant: We are currently connected to an attachment
@rpc("any_peer", "call_local")
func _detach():
	# Remove the joint
	if not curr_joint:
		return # Newly joining players won't synchronize new joints... yet.
	curr_joint.queue_free()
	curr_joint = null
	
	var curr_attach_trans = current_attachment.global_transform
	current_attachment.global_transform = curr_attach_trans
	
	current_attachment.connector.do_disconnect(self)
	do_disconnect(current_attachment.connector)
	
	current_attachment = null
	can_attach = false

# Another connector is nearby
# Invariant: area is a connector
func _on_connector_component_can_connect(area):
	var body = area.parent
	if body is BaseTool: # Body is an attachment
		current_attachment = body
		can_attach = true
		
func _on_connector_component_just_connected(_area):
	# Stick bodies together
	curr_joint = Generic6DOFJoint3D.new()
	curr_joint.global_transform = global_transform
	add_joint.emit(curr_joint)
	
	current_attachment.global_transform = get_parent().global_transform
	current_attachment.global_position = global_position

	curr_joint.global_transform = global_transform
	curr_joint.set_node_a(get_parent().get_path())
	curr_joint.set_node_b(current_attachment.get_path())
	can_attach = false

func _on_connector_component_must_disconnect(_area):
	if not connected: # Because position changes during attach trigger function
		nearby_connector = null
		can_attach = false
		current_attachment = null
