extends RigidBody3D

const path = "res://astra/tool_attachments/sawblade/saw_blade_attachment.tscn"

@onready var connector = $ConnectorComponent
@onready var attachment_type = "sawblade"

func _ready():
	add_to_group("attachment")

func toggle_blade_spin():
	if $AnimationPlayer.is_playing("spin_blade"):
		$AnimationPlayer.stop("spin_blade")
	else:
		$AnimationPlayer.play("spin_blade")
