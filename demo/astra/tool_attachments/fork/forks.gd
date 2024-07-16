extends RigidBody3D

const path = "res://astra/tool_attachments/fork/forks.tscn"

@onready var connector = $ConnectorComponent
@onready var attachment_type = "forks"

func _ready():
	add_to_group("attachment")
