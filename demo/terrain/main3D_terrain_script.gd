extends Node3D

@export var terrain : TerrainSim
@export var sprite : Sprite3D

# Called when the node enters the scene tree for the first time.
func _ready():
	print("TERRAIN SCRIPT IS ALIVE")
	var image = terrain.get_image()
	print("Terrain image: ",image.get_width(),"x",image.get_height())
	sprite.texture = ImageTexture.create_from_image(image)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	#print("TERRAIN SCRIPT PROCESS RUNNING")
	pass
