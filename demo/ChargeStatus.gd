extends Node3D

@export var charging: bool = false
@export var moving: bool = false
@export var charge_level: float = 10.0
@export var is_dead: bool = false # Vehicle is out of battery

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if charging:
		charge_level += delta * 5.0
	if moving:
		charge_level -= delta * 1.0
	if charge_level <= 0.0:
		charge_level = 0.0
		is_dead = true
	else:
		is_dead = false
	if charge_level > 100.0:
		charge_level = 100.0

func start_charge():
	if charging == true:
		print("Charging is true when it shouldn't be!")
	charging = true
	
	
func stop_charge():
	if charging == false:
		print("Charging is false when it shouldn't be!")
	charging = false
