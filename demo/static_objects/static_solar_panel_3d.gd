extends StaticBody3D

@export var power_rate: float = 10.0

func _physics_process(delta):
	if get_parent().is_in_group("chargeable"):
		var parent_charge = get_parent().charge_component
		parent_charge.change_charge(delta * power_rate)
