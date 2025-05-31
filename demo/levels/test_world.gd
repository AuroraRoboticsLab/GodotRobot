extends Node3D

func _ready() -> void:
	GameManager.add_local_object.connect(_on_add_local_object)

func _on_add_local_object(body, deferred=false):
	$Objects.add_child(body, deferred)
