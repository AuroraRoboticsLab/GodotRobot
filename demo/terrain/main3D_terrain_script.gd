@tool
extends Node3D

@export var terrain : TerrainSim # Source of height data
@export var shader : ShaderMaterial # renders the terrain
@export var collider : CollisionShape3D # defines terrain collisions

# Called when the node enters the scene tree for the first time.
func _ready():
	if (collider):
		collider.shape = terrain.get_height_shape()
	
	var tex = terrain.get_image_texture()
	shader.set_shader_parameter("heights", tex)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	#print("TERRAIN SCRIPT PROCESS RUNNING")
	pass
