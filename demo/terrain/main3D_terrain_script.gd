@tool   #<- allows you to see terrain in editor, though has weird side effects
extends Node3D

@export var shader : ShaderMaterial # renders the terrain
@onready var terrain = $TerrainSim # Source of height data

# Called in physics_process when a dirtball has stopped and needs to merge with the terrain
func dirtball_merge(dirtball):
	if terrain.try_merge(dirtball):
		dirtball.queue_free()

# Called when the node enters the scene tree for the first time.
func _ready():
	terrain.add_mesh(shader)
	terrain.add_static_collider();
	terrain.fill_heights(100,100,40);
