/*
 Implements static terrain load functions.
*/
#include "terrainstatic.h"


using namespace godot;



void TerrainStatic256::_bind_methods()
{
    //printf("TerrainStatic binding methods\n");
    
    ClassDB::bind_method(D_METHOD("fill_from_image"), &TerrainStatic256::fill_from_image);

    // The get methods are so script can access our terrain data
    ClassDB::bind_method(D_METHOD("get_height_shape"), &TerrainStatic256::get_height_shape);
    ClassDB::bind_method(D_METHOD("get_image"), &TerrainStatic256::get_image);
    ClassDB::bind_method(D_METHOD("get_image_texture"), &TerrainStatic256::get_image_texture);
    
    // Methods to set up and configure the object
    ClassDB::bind_method(D_METHOD("add_mesh"), &TerrainStatic256::add_mesh);
    ClassDB::bind_method(D_METHOD("create_collider"), &TerrainStatic256::create_collider);
    ClassDB::bind_method(D_METHOD("add_static_collider"), &TerrainStatic256::add_static_collider);
}


TerrainStatic256::TerrainStatic256()
{}


/**
 Load our terrain data from this float heightmap image.
 Assumptions: float pixels, ideally grayscale image, scaled so
 0 to 1 in the input is -10000 to +10000 meters of elevation.
**/
void TerrainStatic256::fill_from_image(Ref<Image> src, float meters_per_pixel)
{
    sz = meters_per_pixel;
    
    const float scale_to_meters = 20000.0;  /* input has range -10000 to +10000 */
    const float shift_to_meters = -10000.0; /* subtract back to be zero centered */
    
    for (int z = 0; z < H; ++z)
        for (int x = 0; x < W; ++x) {
            int i = z * W + x;
            float h=0.0;
            
            int ix = x, iy = z;
            //if (src in bounds) 
            {
                Color c = src->get_pixel(ix,iy);
                h = c.r * scale_to_meters + shift_to_meters;
            }
            
            height_floats[i] = h;
        }
    
    publish();
}

/**
 A plane mesh deformed up into a 3D terrain.
*/
class TerrainMesh : public PlaneMesh {
    float hlo, hhi; // our height range
    Vector2 size; // our xy size
public:
    TerrainMesh(int W, int H, float sz, const float *height_floats) {
        set_subdivide_width(2*W-1);
        set_subdivide_depth(2*H-1);
        
        size = Vector2(W*sz,H*sz);
        set_size(size);
        set_center_offset(0.5f*Vector3(
            size.x,0.0f,size.y
        ));
        
        
        hlo=1.0e20; hhi=-1.0e20;
        
        for (int z = 0; z < H; ++z)
            for (int x = 0; x < W; ++x) {
                int i = z * W + x;
                float h=height_floats[i];
                
                if (h<hlo) hlo=h;
                if (h>hhi) hhi=h;
            }
    }
    
    virtual _create_mesh_array(Array &p_arr) const {
        PlaneMesh::_create_mesh_array(p_arr);
        
        /* fix up UVs? */
        
    }
    
    // The plane has the wrong bounding box, so set this custom one including our terrain heights
    virtual AABB get_aabb() const
    {
        AABB aabb(Vector3(0.0,hlo,0.0), Vector3(size.x,hhi,size.y));
        return aabb;
    }
    
};

/// Create a child mesh instance so you can see our terrain.
///  Renders using this shader as the basis,
///  replaces the shader's "heights" uniform.
void TerrainStatic256::add_mesh(Ref<ShaderMaterial> shader, bool casts_shadows)
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
    Ref<TerrainMesh> my_mesh{ memnew(TerrainMesh(W,H,sz,height_floats)) };
    
    // oddly, you can't seem to Ref<Node>, so use bare pointer.
    MeshInstance3D *mesh_instance{memnew(MeshInstance3D)};
    
    mesh_instance->set_mesh(my_mesh);
    mesh_instance->set_cast_shadows_setting(casts_shadows?
        GeometryInstance3D::SHADOW_CASTING_SETTING_ON:
        GeometryInstance3D::SHADOW_CASTING_SETTING_OFF);
    
    // Copy the shader material, so we can drop in our own heights texture
    Ref<ShaderMaterial> sm{shader->duplicate(true)};
    sm->set_shader_parameter("heights", image_texture);
    mesh_instance->set_surface_override_material(0,sm);
    
    add_child(mesh_instance);
}

/// Create a new CollisionShape3D for our collisions.
///   Includes a scale factor to match our shader and mesh.
CollisionShape3D *TerrainStatic256::create_collider(void) const {
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
void TerrainStatic256::add_static_collider(void)
{
    StaticBody3D *sc{memnew(StaticBody3D)};
    
    sc->add_child(create_collider());
    
    add_child(sc);
}

