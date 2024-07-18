extends StaticBody3D

@export var power_rate: float = 50.0
@export var connected_charge_component: ChargeComponent = null

func _physics_process(delta):
	if connected_charge_component:
		connected_charge_component.change_charge(delta * power_rate)
