extends CanvasLayer

@export var ball_count = 0
@export var fps = 60
@export var spawn_rate = 3
@export var charging: bool = false
@export var charge_level: float = 100.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$VSplitContainer/GridContainer/BallCount.text = str(ball_count)
	$VSplitContainer/GridContainer/FPS.text = str(fps)
	$VSplitContainer/GridContainer/SpawnRate.text = str(spawn_rate)
	$VSplitContainer/GridContainer/Charging.text = "Charging:" if charging else "Not charging:"
	$VSplitContainer/GridContainer/ChargePercent.text = str(int(charge_level)) + "%"
