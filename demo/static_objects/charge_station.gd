extends StaticBody3D

@onready var bodies_charging = [] # Bodies being charged

@onready var connector1 = $ConnectorComponent1
@onready var connector2 = $ConnectorComponent2
@onready var connector3 = $ConnectorComponent3
@onready var connector4 = $ConnectorComponent4
@onready var connectors = [connector1, connector2, connector3, connector4]

@onready var charge_component = $ChargeComponent

func _ready():
	add_to_group("chargeable")
	GameManager.network_process.connect(_network_process)

func _network_process(_delta):
	if not multiplayer.is_server():
		var static_data = GameManager.get_static_data(name)
		if not static_data:
			return
		charge_component.remaining_amp_hours = static_data["remaining_amp_hours"]
		return
	
	var new_static_data = {}
	new_static_data[name] = {
		"remaining_amp_hours": charge_component.remaining_amp_hours
	}
	
	GameManager.add_new_static_data(new_static_data)

func _physics_process(delta):
	# For battery-like shader level.
	set_shader_percentage(charge_component.charge_level)
	var num_bodies_charging = bodies_charging.size()
	if num_bodies_charging <= 0:
		return # Don't do anything if nobody is charging!
	
	# Charge opportunity split evenly between each body charging
	var charge_per_body = charge_component.max_draw_rate / num_bodies_charging
	
	# Each body on the charger needs to be charged
	for body in bodies_charging:
		if body.charge_component.charge_level < 100.0:
			var charge_exchange = charge_per_body * delta
			body.charge_component.change_charge(charge_exchange) # We give, and
			charge_component.change_charge(-charge_exchange)     # we take.


# Set the battery-like shader level based on charge.
func set_shader_percentage(new_charge: float) -> void:
	var material = $ChargeStationMesh.mesh.material
	if material and material is ShaderMaterial:
		material.set_shader_parameter("charge_percentage", new_charge/100.0)
	else:
		print("Invalid material or not a ShaderMaterial")

# Given a connector, start charging the attached body if possible.
func init_connect(area):
	var body = area.parent
	if body.is_in_group("chargeable"):
		body.charge_component.charging = true
		bodies_charging.append(body)

# Do connect logic for all connectors.
func _on_connector_component_1_just_connected(area):
	init_connect(area)
func _on_connector_component_2_just_connected(area):
	init_connect(area)
func _on_connector_component_3_just_connected(area):
	init_connect(area)
func _on_connector_component_4_just_connected(area):
	init_connect(area)

# Given a connector, stop charging it if possible,
# and remove it from connected body list.
func init_disconnect(area):
	var body = area.parent
	if body.is_in_group("chargeable"):
		body.charge_component.charging = false
		bodies_charging.erase(body)

# Do disconnect logic for all connectors.
func _on_connector_component_1_just_disconnected(area):
	init_disconnect(area)
func _on_connector_component_2_just_disconnected(area):
	init_disconnect(area)
func _on_connector_component_3_just_disconnected(area):
	init_disconnect(area)
func _on_connector_component_4_just_disconnected(area):
	init_disconnect(area)
