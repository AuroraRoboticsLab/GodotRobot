# Mark dirtballs inside our bucket.   Requires a collider as a child node.
#  Uses a counter because there can be multiple buckets, possibly overlapping.
extends Area3D

# This type equality comparison seems like it would be more performant than groups:
# (from https://gamedev.stackexchange.com/questions/208718/checking-if-a-node-is-of-a-given-type-in-godot-4 )
var num_dirtballs: int = 0

func _on_body_entered(body) -> void:
	if body is Dirtball:
		num_dirtballs += 1
		body.inside_count += 1

func _on_body_exited(body) -> void:
	if body is Dirtball:
		body.inside_count -= 1
		num_dirtballs -= 1
