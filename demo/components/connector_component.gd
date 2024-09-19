extends Area3D
class_name Connector

# If another connector is nearby, we can attempt
# to connect to it. Let the parent know!
signal can_connect(area)

# If the connected connector leaves, we should
# probably disconnect. What does the parent need
# to do to disconnect?
signal must_disconnect(area)

# We just connected to a connector! What happens now?
signal just_connected(area)

# We just disconnected from a connector. What happens now?
signal just_disconnected(area)

# The connector we are close to.
@onready var nearby_connector: Area3D = null
# Are we connected, or not?
@onready var connected: bool = false
@export var enabled: bool = true
@export var charge_component: ChargeComponent = null

# Body connected to this connector.
@onready var parent: Node = get_parent()

# We have been told to connect.
func do_connect(connect_to=nearby_connector):
	if connected: # Connecting when connected; something went wrong.
		print("WARN: Attempting to connect when already connected!")
		return false
	
	if not connect_to: # Connecting to nothing.
		print("WARN: No connector to connect to!")
		return false
	
	# If previous checks passed, we are connected!
	connected = true
	if connect_to != nearby_connector:
		# Make sure the connector we are told to
		# connect to is the one we list as nearby.
		nearby_connector = connect_to
	
	# Tell everyone we just connected!
	just_connected.emit(connect_to)
	
# We have been told to disconnect
func do_disconnect(area=nearby_connector):
	if not connected:
		print("Already disconnected!")
		return false
	nearby_connector = null
	connected = false
	just_disconnected.emit(area)

# An area entered the connector's area
func _on_area_entered(area):
	if connected: # We are occupied, so we don't care.
		return
		
	if not enabled:
		return
	
	# We aren't already near a connector, and the area is a connector.
	if not nearby_connector and area is Connector:
		if not area.enabled:
			return
		# We are now near a connector.
		nearby_connector = area 
		# Let everyone know we can connect to it!
		can_connect.emit(nearby_connector)

# Area left the connector's area.
func _on_area_exited(area):
	# Was the area the connected area?
	if area == nearby_connector:
		# Let everyone know we must disconnect!
		must_disconnect.emit(area)
