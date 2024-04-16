extends StaticBody3D


@onready var bodies_charging = [] # Bodies being charged
@export var max_charge_rate = 30 # How much charge can a charge station put out?

@onready var connector1 = $ConnectorComponent1
@onready var connector2 = $ConnectorComponent2
@onready var connector3 = $ConnectorComponent3
@onready var connector4 = $ConnectorComponent4
@onready var connectors = [connector1, connector2, connector3, connector4]

func _physics_process(delta):
	var num_bodies_charging = bodies_charging.size()
	if num_bodies_charging <= 0:
		return # Don't do anything if nobody is charging!
	
	# Charge capacity split evenly between each body charging
	var charge_per_body = max_charge_rate / num_bodies_charging
	
	# Each body on the charger needs to be charged
	for body in bodies_charging:
		body.charge_component.change_charge(charge_per_body * delta)

func init_connect(area):
	var body = area.parent
	if body.is_in_group("chargeable"):
		body.charge_component.charging = true
		bodies_charging.append(body)

func _on_connector_component_1_just_connected(area):
	init_connect(area)
func _on_connector_component_2_just_connected(area):
	init_connect(area)
func _on_connector_component_3_just_connected(area):
	init_connect(area)
func _on_connector_component_4_just_connected(area):
	init_connect(area)

func init_disconnect(area):
	var body = area.parent
	body.charge_component.charging = false
	bodies_charging.erase(body)

func _on_connector_component_1_just_disconnected(area):
	init_disconnect(area)
func _on_connector_component_2_just_disconnected(area):
	init_disconnect(area)
func _on_connector_component_3_just_disconnected(area):
	init_disconnect(area)
func _on_connector_component_4_just_disconnected(area):
	init_disconnect(area)

