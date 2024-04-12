extends MeshInstance3D


@onready var bodies_charging = [] # Bodies being charged
@export var max_charge_rate = 100 # How much charge can a charge station put out?

func _physics_process(delta):
	var num_bodies_charging = bodies_charging.size()
	if num_bodies_charging <= 0:
		return # Don't do anything if nobody is charging!
	
	# Charge capacity split evenly between each body charging
	var charge_per_body = max_charge_rate / num_bodies_charging
	
	# Each body on the charger needs to be charged
	for body in bodies_charging:
		body.charge_component.change_charge(charge_per_body * delta)

# Body enters charge station
func _on_area_3d_body_entered(body):
	if body.is_in_group("chargeable"):
		body.charge_component.charging = true
		bodies_charging.append(body)

# Body leaves charge station
func _on_area_3d_body_exited(body):
	if body.is_in_group("chargeable"):
		body.charge_component.charging = false
		bodies_charging.erase(body)
