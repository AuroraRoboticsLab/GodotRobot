extends Node3D
class_name ChargeComponent

var charge_level: float = 100.0: # Battery %
	set(value):
		# Check: Did we overcharge?
		if value > 100.0:
			value = 100.0
			remaining_amp_hours = amp_hours
		
		# Check: Are we dead?
		if value <= 0.0:
			charge_level = 0.0
			remaining_amp_hours = 0.0
			is_dead = true
		else:
			charge_level = value
			is_dead = false
var is_dead: bool = false # Vehicle is out of battery
var charging: bool = false # Is vehicle charging?
# Voltage should instead be a function of remaining_amp_hours/amp_hours
var voltage: float = 12.0

@export var amp_hours: float = 100.0
@export var remaining_amp_hours: float = 100.0
@export var max_draw_rate: float = 100.0
@export var max_charge_rate: float = 50.0

var charge_interp: float = 0.0:
	set(value):
		charge_interp = value if value >= 0.0 else 0.0
func _physics_process(_delta: float) -> void:
	charge_level = (remaining_amp_hours/amp_hours) * 100
	
# Change the charge by a given value every frame.
# Given a negative, discharge. Positive, charge!
# This function expects value to be multiplied by delta.
func change_charge(value: float) -> void:
	charge_interp += value
	charge_interp = lerpf(charge_interp, -0.1, 0.5)
	if charge_interp > 0.0:
		charging = true
	else:
		charging = false
	# Ensure we are in bounds for charging and discharging
	if (value > 0 and remaining_amp_hours < amp_hours) or (value < 0 and remaining_amp_hours > 0.0):
		# Value in amps; expecting amp seconds (times delta), not hours.
		remaining_amp_hours += value/3600
		charge_level = (remaining_amp_hours/amp_hours) * 100 # Charge % value
