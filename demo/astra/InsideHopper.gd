# Mark dirtballs inside our hopper.   Requires a collider as a child node.
#  Uses a counter because there can be (can there be?) multiple hoppers, possibly overlapping.
extends Area3D

const dirtball_t = preload("res://terrain/dirtball.gd")

func _on_body_entered ( body ):
	if body is dirtball_t:
		#print("InsideHopper dirtball enters")
		body.hopper_count += 1

func _on_body_exited ( body ):
	if body is dirtball_t:
		#print("InsideHopper dirtball leaves")
		body.hopper_count -= 1
