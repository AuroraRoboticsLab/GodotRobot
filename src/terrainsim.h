/*
  Modifiable terrain simulator
  
*/
#ifndef GODOTROBOT_TERRAINSIM_H
#define GODOTROBOT_TERRAINSIM_H

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/image_texture.hpp>
#include <godot_cpp/classes/height_map_shape3d.hpp>
#include <godot_cpp/classes/shader_material.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/collision_shape3d.hpp>

namespace godot {

// Draw a demo sprite
class TerrainSim : public Node3D {
	GDCLASS(TerrainSim, Node3D)

public:
    /// Pixel dimensions of one chunk of terrain.
    ///   W is along X, H is along Z, elevation is along Y
    ///   Smaller ->  more granular updates
    ///   Larger -> fewer boundaries and object update overhead
    enum {W=64, H=64};

/// Float size of mesh cells, horizontal distance
#define MESH_SPACING 0.1f
    
    /// Size in meters of pixel, horizontal distance (along X or Z axes).
    float sz;
    
	TerrainSim();
	~TerrainSim();

	void _process(double delta) override;
	
    /// Publish updated height data to collision and image buffers
    void publish(void);
    
	/// Allows collision detection (add this to a collider)
    Ref<HeightMapShape3D> get_height_shape(void) { return height_shape; }
    
    /// Get float grayscale image of height map (allows rendering)
    Ref<Image> get_image(void) { return image; }
    
    /// Get image texture (for shader lookup of heights)
    Ref<ImageTexture> get_image_texture(void) { return image_texture; }
    
    
    /*
    // Setters are a bad idea
    void set_height_shape(Ref<HeightMapShape3D> r) { height_shape=r; }
    void set_image(Ref<Image> r) { image=r; }
    void set_image_texture(Ref<ImageTexture> r) { image_texture=r; }
    */
    
    /// Create a child mesh instance so you can see our terrain.
    ///  Renders using this shader as the basis,
    ///  replaces the shader's "heights" uniform.
    void add_mesh(Ref<ShaderMaterial> shader);
    
    /// Create a new CollisionShape3D for our collisions.
    ///   Includes a scale factor to match our shader and mesh.
    CollisionShape3D *create_collider(void) const;
    
    /// Create a child StaticBody3D so stuff bounces off this terrain.
    void add_static_collider(void);
    

private:
    /// Raw height data, in meters (can't be refcounted, hence no Ref<> here)
    PackedFloat32Array height_array;
    
    /// Points to our raw height data in the array, raster pattern WxH in size
    float *height_floats;
    
    /// Publish first time height data to Refs below.
    void publish_first(void);
    void publish_image(void);
    
    /// Allows collision detection
    Ref<HeightMapShape3D> height_shape;
    
    /// Allows rendering
    Ref<Image> image;
    
    Ref<ImageTexture> image_texture;
    
protected:
	static void _bind_methods();
};

}

#endif


