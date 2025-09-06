# Mark dirtballs inside our hopper.   Requires a collider as a child node.
#  Uses a counter because there can be (can there be?) multiple hoppers, possibly overlapping.
extends Area3D

@onready var num_dirtballs: int = 0

func _on_body_entered ( body ):
	if body is Dirtball:
		#print("InsideHopper dirtball enters")
		body.inside_count += 1
		num_dirtballs += 1

func _on_body_exited ( body ):
	if body is Dirtball:
		#print("InsideHopper dirtball leaves")
		body.inside_count -= 1
		num_dirtballs -= 1
