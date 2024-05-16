extends RigidBody3D

@onready var connector = $ConnectorComponent
@onready var attachment_type = "bucket"

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("attachment")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
