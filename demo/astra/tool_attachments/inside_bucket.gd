# Mark dirtballs inside our bucket.   Requires a collider as a child node.
#  Uses a counter because there can be multiple buckets, possibly overlapping.
extends Area3D

# This type equality comparison seems like it would be more performant than groups:
# (from https://gamedev.stackexchange.com/questions/208718/checking-if-a-node-is-of-a-given-type-in-godot-4 )
const dirtball_t = preload("res://terrain/dirtball.gd")

func _on_body_entered ( body ):
	if body is dirtball_t:
		#print("InsideBucket dirtball enters")
		body.bucket_count += 1

func _on_body_exited ( body ):
	if body is dirtball_t:
		#print("InsideBucket dirtball leaves")
		body.bucket_count -= 1
