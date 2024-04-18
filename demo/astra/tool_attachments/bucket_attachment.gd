extends RigidBody3D

@onready var connector = $ConnectorComponent
@onready var attachment_type = "bucket"
@export var start_invisible = false

func make_visible():
	visible = true
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = false
	connector.enabled = true

func make_invisible():
	visible = false
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = true
	connector.enabled = false
	
	

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("attachment")
	if start_invisible:
		make_invisible()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
