extends RigidBody3D

@onready var connector = $ConnectorComponent
@onready var attachment_type = "forks"

func _ready():
	add_to_group("attachment")
