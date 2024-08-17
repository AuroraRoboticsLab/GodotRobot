/*
  Static terrain chunks:
    - Heightmap loaded from EXR file
    - Creates render geometry
    - Creates collision geometry
  
  by Orion Lawlor, lawlor@alaska.edu, 2024-03 through 2024-09 (Public Domain)
*/
#ifndef GODOTROBOT_TERRAINSTATIC_H
#define GODOTROBOT_TERRAINSTATIC_H

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/image_texture.hpp>
#include <godot_cpp/classes/height_map_shape3d.hpp>
#include <godot_cpp/classes/shader_material.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/collision_shape3d.hpp>


// Required to implement template methods here in-header:
#include <godot_cpp/classes/plane_mesh.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/static_body3d.hpp>


namespace godot {

/// Stores terrain data of size SIZE_W width (X axis) by SIZE_H height (Z axis).
template <int SIZE_W=256, int SIZE_H=256>
class TerrainTemplate : public Node3D {
public:
    
    /// Pixel dimensions of one chunk of terrain.
    ///   W is along X, H is along Z, elevation is along Y
    ///   Smaller ->  more granular updates
    ///   Larger -> fewer boundaries and object update overhead
    enum {W=SIZE_W, H=SIZE_H};
    
    /// Size in meters of a terrain pixel, horizontal distance (along X or Z axes).
    float sz;
    
    
    
    /// Publish updated height data to collision and image buffers
    void publish(void) {
        publish_image();
        
        image_texture->update(*image);
    }
    
    
    /// Create a new empty terrain, including our ref objects
    TerrainTemplate()
        :sz(1.0f),
         height_shape{memnew(HeightMapShape3D)},
         image{memnew(Image)},
         image_texture{memnew(ImageTexture)}
    {
        height_array.resize(W*H);
        height_floats=height_array.ptrw();
        
        for (int z=0;z<H;z++)
            for (int x=0;x<W;x++)
                height_floats[z*W + x] = 0.0f;

        height_shape->set_map_width(W);
        height_shape->set_map_depth(H);
        
        publish_first();
    }
    
    /// Deallocate our terrain, unref our objects
    ~TerrainTemplate()
    {
        
    }
    
    
    
    
protected:
    /// Raw height data, in meters (can't be refcounted, hence no Ref<> here)
    PackedFloat32Array height_array;
    
    /// Points to our raw height data in the array, raster pattern WxH in size
    float *height_floats;
    
    /// Publish first time height data to Refs below.
    void publish_first(void) {
        publish_image();
        
        image_texture->set_image(*image);
    }
    
    // Update just the height_shape and image from our array
    void publish_image(void)
    {
        height_shape->set_map_data(height_array);
        bool mipmaps=false;
        image->set_data(W,H,mipmaps,Image::FORMAT_RF,height_array.to_byte_array());
    }
    
    /// Allows collision detection with our heightmap
    Ref<HeightMapShape3D> height_shape;
    
    /// Allows rendering: this grayscale W x H image stores the height of each terrain point
    Ref<Image> image;    
    Ref<ImageTexture> image_texture;
};

/// Stores a static terrain of size 256 x 256
class TerrainStatic256 : public TerrainTemplate<256,256>
{
    GDCLASS(TerrainStatic256,Node3D)
public:
    /// Our templated parent class
    typedef TerrainTemplate<256,256> parent;
    
    /**
     Load our terrain data from this float heightmap image.
     Assumptions: float pixels, ideally grayscale image, scaled so
     0 to 1 in the input is -10000 to +10000 meters of elevation.
    **/
    void fill_from_image(Ref<Image> src, float meters_per_pixel);
    
   
    /// Allows collision detection (add this to a collider)
    Ref<HeightMapShape3D> get_height_shape(void) { return height_shape; }
    
    /// Get float grayscale image of height map (allows rendering)
    Ref<Image> get_image(void) { return image; }
    
    /// Get image texture (for shader lookup of heights)
    Ref<ImageTexture> get_image_texture(void) { return image_texture; }
    
    
    /// Create a child mesh instance so you can see our terrain.
    ///  Renders using this shader as the basis,
    ///  replaces the shader's "heights" uniform.
    void add_mesh(Ref<ShaderMaterial> shader, bool casts_shadows = true)
    {
        if (shader==NULL) { //<- we'd crash without a shader
            shader = ResourceLoader::get_singleton()->load("res://terrain/terrain_shader_material.tres");
        }
        if (shader==NULL) { // still NULL, no good.
            printf("TerrainSim can't find shader material, skipping mesh.\n");
            return;
        }
        
        /// Theoretically parts of this could be shared with other terrains with 
        ///   the same W, H, and sz, but it's not clear how to find them.
        Ref<PlaneMesh> my_mesh{ memnew(PlaneMesh) };
        
        // Uniform subdivisions are tricky to make exactly align with the terrain heights,
        //   a custom-spaced mesh would be fewer triangles, but this does work.
        my_mesh->set_subdivide_width(2*W-1);
        my_mesh->set_subdivide_depth(2*H-1);
        Vector2 size = Vector2(W*sz,H*sz);
        my_mesh->set_size(size);
        my_mesh->set_center_offset(0.5f*Vector3(
            size.x,0.0f,size.y
        ));
        
        // oddly, you can't seem to Ref<Node>, so use bare pointer.
        MeshInstance3D *mesh_instance{memnew(MeshInstance3D)};
        
        mesh_instance->set_mesh(my_mesh);
        mesh_instance->set_cast_shadows_setting(casts_shadows?
            GeometryInstance3D::SHADOW_CASTING_SETTING_ON:
            GeometryInstance3D::SHADOW_CASTING_SETTING_OFF);
        mesh_instance->set_extra_cull_margin(5.0f + 10.0*sz); // avoid vanishing when plane itself is not visible
        
        // Copy the shader material, so we can drop in our own heights texture
        Ref<ShaderMaterial> sm{shader->duplicate(true)};
        sm->set_shader_parameter("heights", image_texture);
        mesh_instance->set_surface_override_material(0,sm);
        
        add_child(mesh_instance);
    }
    
    /// Create a new CollisionShape3D for our collisions.
    ///   Includes a scale factor to match our shader and mesh.
    CollisionShape3D *create_collider(void) const {
        CollisionShape3D *c{memnew(CollisionShape3D)};
        
        c->set_shape(height_shape);
        
        c->set_position(Vector3(
            W*sz*0.5f,
            0.0f,
            H*sz*0.5f
        ));
        c->set_scale(Vector3(
            sz,
            1.0f,
            sz
        ));
        
        return c;
    }
    
    /// Create a child StaticBody3D so stuff bounces off this terrain.
    void add_static_collider(void)
    {
        StaticBody3D *sc{memnew(StaticBody3D)};
        
        sc->add_child(create_collider());
        
        add_child(sc);
    }
    
    
    static void _bind_methods();
};


};

#endif

