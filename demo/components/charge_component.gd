extends Node3D


@export var charge_level: float = 10.0 # Battery %
var is_dead: bool = false # Vehicle is out of battery
var charging: bool = false # Is vehicle charging?
	
# Change the charge by a given value every frame.
# Given a negative, discharge. Positive, charge!
# Given an efficiency
# This function expects value to be multiplied by delta.
func change_charge(value, efficiency = 1.0):
	if efficiency > 1.0 or efficiency < 0.0: # Check for okay efficiency
		print("WARNING: Efficiency value is unrealistic:", efficiency)
	
	# Ensure we are in bounds for charging and discharging
	if (value > 0 and charge_level < 100.0) or (value < 0 and charge_level > 0.0):
		charge_level += value * efficiency * 0.01 # Scale down values (do this some other way?)

	# Check: Did we overcharge?
	if charge_level > 100.0:
		charge_level = 100.0
		
	# Check: Are we dead?
	if charge_level <= 0.0:
		charge_level = 0.0
		is_dead = true
	else:
		is_dead = false
