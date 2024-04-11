extends MeshInstance3D

signal body_on_charger(body)
signal body_left_charger(body)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


# Body enters charge station
func _on_area_3d_body_entered(body):
	body_on_charger.emit(body)

# Body leaves charge station
func _on_area_3d_body_exited(body):
	body_left_charger.emit(body)
