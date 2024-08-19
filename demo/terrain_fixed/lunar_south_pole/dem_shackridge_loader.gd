@tool  # run inside editor too, so we can see the terrain and line it all up
extends DemLoader
@export var pixel_spacing : float
@export var shader : ShaderMaterial # renders the terrain

# Called when the node enters the scene tree for the first time.
func _ready():
	var dem : Image = load_image(
		"res://terrain_fixed/lunar_south_pole/dem_shackridge_200m_256x256.exr",
		"res://terrain_fixed/lunar_south_pole/dem_shackridge_cache.res")
	if dem:
		fill_from_image(dem,pixel_spacing)
		add_mesh(shader,true)
		# no static collider, to save physics cycles?
