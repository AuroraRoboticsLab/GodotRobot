@tool
extends Node3D

@export var terrain : TerrainSim # Source of height data
@export var sprite : Sprite3D # Quick and dirty 2D only display of raw texture
@export var shade : ShaderMaterial # material for subdivided plane render

# Called when the node enters the scene tree for the first time.
func _ready():
	var image = terrain.get_image()
	print("Terrain image in script: ",image.get_width(),"x",image.get_height()," pixels")
	var tex = ImageTexture.create_from_image(image)
	sprite.texture = tex
	
	shade.set_shader_parameter("heights", tex)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	#print("TERRAIN SCRIPT PROCESS RUNNING")
	pass
