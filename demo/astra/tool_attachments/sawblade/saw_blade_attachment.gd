extends RigidBody3D

@onready var connector = $ConnectorComponent
@onready var attachment_type = "sawblade"

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("attachment")

func toggle_blade_spin():
	if $AnimationPlayer.is_playing("spin_blade"):
		$AnimationPlayer.stop("spin_blade")
	else:
		$AnimationPlayer.play("spin_blade")
