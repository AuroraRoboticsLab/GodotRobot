extends CanvasLayer

@export var ball_count = 0
@export var fps = 60
@export var spawn_rate = 3
@export var charging: bool = false
@export var charge_level: float = 100.0
@export var stalling: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Code from Godot forums
func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$VSplitContainer/GridContainer/BallCount.text = str(ball_count)
	$VSplitContainer/GridContainer/FPS.text = str(fps)
	$VSplitContainer/GridContainer/SpawnRate.text = str(spawn_rate)
	$VSplitContainer/GridContainer/Charging.text = "Charging:" if charging else "Not charging:"
	$VSplitContainer/GridContainer/ChargePercent.text = str(round_to_dec(charge_level, 2)) + "%"
	$VSplitContainer/GridContainer/AreStalling.visible = stalling
