@tool  # run inside editor too, so we can see the terrain and line it all up
extends TerrainStatic256
@export var dem : Image # imported as an Image, not a Texture2D, for CPU access
@export var pixel_spacing : float
@export var shader : ShaderMaterial # renders the terrain

# Called when the node enters the scene tree for the first time.
func _ready():
	fill_from_image(dem,pixel_spacing)
	add_mesh(shader,true)
	add_static_collider() # fixme: what happens when we want to dig this area?

