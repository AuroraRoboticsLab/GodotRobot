extends Node3D

@onready var parent = get_parent()

func make_visible():
	parent.visible = true
	for child in parent.get_children():
		if child is CollisionShape3D:
			child.disabled = false
		if child.is_in_group("connector"):
			child.enabled = true

func make_invisible():
	parent.visible = false
	for child in parent.get_children():
		if child is CollisionShape3D:
			child.disabled = true
		if child.is_in_group("connector"):
			child.enabled = false
