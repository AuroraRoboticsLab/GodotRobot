extends CanvasLayer

@export var ball_count = 0
@export var fps = 60

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$GridContainer/BallCount.text = str(ball_count)
	$GridContainer/FPS.text = str(fps)

