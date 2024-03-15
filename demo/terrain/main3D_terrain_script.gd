@tool   #<- allows you to see terrain in editor, though has weird side effects
extends Node3D

@export var shader : ShaderMaterial # renders the terrain

# Called when the node enters the scene tree for the first time.
func _ready():
	var terrain = $TerrainSim # Source of height data
	terrain.add_mesh(shader)
	terrain.add_static_collider();
