extends ToolAttachment
class_name SawBlade

func toggle_blade_spin():
	if $AnimationPlayer.is_playing("spin_blade"):
		$AnimationPlayer.stop("spin_blade")
	else:
		$AnimationPlayer.play("spin_blade")
