@tool  # run inside editor too, so we can see the terrain and line it all up
class_name DemLoader extends TerrainStatic256

# Call this to load our cached DEM image, or create it if needed (first time)
#   HACK: This works around the bug where Godot only loads EXR files in the editor, not an export.
#   So we save a raw in-RAM Image resource after loading the EXR.
#   You'll need to delete the cache resource (which shouldn't be in git) if you change the EXR.
func load_image(dempath : String, cachepath : String):
	var cached = ResourceLoader.load(cachepath)
	if cached:
		return cached
	var dem = ResourceLoader.load(dempath)
	if dem:
		# refill the cache so we have it for next time (or export)
		ResourceSaver.save(dem,cachepath)
		return dem
	else:
		push_warning("Error loading DEM image from ",dempath," or cache at ",cachepath)
		return null
