extends Area3D

signal can_connect(area) # Handled by connectee, generally
signal must_disconnect(area)
signal just_connected(body)
signal just_disconnected(body)

@onready var is_connector_nearby: bool = false
@onready var nearby_connector: Area3D = null
@onready var connected: bool = false

@onready var parent = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("connector")


# We have been told to connect.
func do_connect(connect_to=nearby_connector):
	if connected:
		print("WARN: Attempting to connect when already connected!")
		return false
	
	if not connect_to:
		print("No connector to connect to!")
		return false
	connected = true
	if connect_to != nearby_connector:
		nearby_connector = connect_to
	
	just_connected.emit(connect_to)
	
# We have been told to disconnect
func do_disconnect(area):
	if not connected:
		print("Already disconnected!")
		return false
	connected = false
	just_disconnected.emit(area)

func _on_area_entered(area):
	if connected: # We are occupied, so we don't care.
		return
	
	if not nearby_connector and area.is_in_group("connector"):
		nearby_connector = area
		can_connect.emit(nearby_connector)

func _on_area_exited(area):
	if not connected: # If we're not connected, we don't care!
		return
	
	if area == nearby_connector:
		# If the connected area left, alert that we must disconnect!
		# Functionalities for each connection vary between scenes, so
		# we can't do this entirely by ourselves.
		nearby_connector = null
		must_disconnect.emit(area)
