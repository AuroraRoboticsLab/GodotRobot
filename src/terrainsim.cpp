/*

  Simulate a terrain using a table of height values.
  
  
  Compute shaders are another option, though they don't work in WebGL for now ("RenderingDevice is only available in Forward Plus and Forward Mobile, not Compatibility"). 
  https://github.com/godotengine/godot-demo-projects/tree/master/misc/compute_shader_heightmap
  
  https://docs.godotengine.org/en/stable/tutorials/shaders/compute_shaders.html
  Example generating a float32 heightmap:
  https://www.reddit.com/r/godot/comments/12e8nc1/is_there_a_faster_way_to_work_with_heightmaps/


Routes to get PackedFlat32Array onscreen:
    Mesh: PackedVector3Array 
        Would need conversion to 3D on the CPU, seems slow.


    Texture: Image  create_from_data or set_data takes a PackedByteArray
        Higher performance, and GPU forward design.    
        Needs a vertex shader to project to heights.
    
    I think bare floats is: Image::FORMAT_RF
        Can get PackedByteArray via to_byte_array()
    PackedFloat32Array
        float *ptrw(); will return a pointer to the actual data.
    
    static Ref<Image> create_from_data(int32_t width, int32_t height, bool use_mipmaps, Image::Format format, const PackedByteArray &data);

*/
#include <stdio.h> // for printf, which spews to the console
#include "terrainsim.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/static_body3d.hpp>


using namespace godot;
/*
 See: https://docs.godotengine.org/en/stable/contributing/development/core_and_modules/object_class.html#properties-set-get
*/
void TerrainSim::_bind_methods() {	
    printf("TerrainSim binding methods\n");
    
    // The get methods are so script can access our terrain data
    ClassDB::bind_method(D_METHOD("get_height_shape"), &TerrainSim::get_height_shape);
    ClassDB::bind_method(D_METHOD("get_image"), &TerrainSim::get_image);
    ClassDB::bind_method(D_METHOD("get_image_texture"), &TerrainSim::get_image_texture);
    
    // Methods to set up and configure the object
    ClassDB::bind_method(D_METHOD("add_mesh"), &TerrainSim::add_mesh);
    ClassDB::bind_method(D_METHOD("create_collider"), &TerrainSim::create_collider);
    ClassDB::bind_method(D_METHOD("add_static_collider"), &TerrainSim::add_static_collider);
    
    
    /*
    // These setters are probably a bad idea:
    ClassDB::bind_method(D_METHOD("set_height_shape"), &TerrainSim::set_height_shape);
    ClassDB::bind_method(D_METHOD("set_image"), &TerrainSim::set_image);
    ClassDB::bind_method(D_METHOD("set_image_texture"), &TerrainSim::set_image_texture);
    
    // Just giving accessing to our fields like this results in editor warnings like:
    //   WARNING: Instantiated Image used as default value for TerrainSim's "image" property.
    ClassDB::add_property("TerrainSim", PropertyInfo(Variant::OBJECT, "shape", PROPERTY_HINT_NONE, "",PROPERTY_USAGE_DEFAULT, "HeightMapShape3D"), "", "get_height_shape");  
    ClassDB::add_property("TerrainSim", PropertyInfo(Variant::OBJECT, "image", PROPERTY_HINT_NONE, "",PROPERTY_USAGE_DEFAULT, "Image"), "", "get_image"); 
    ClassDB::add_property("TerrainSim", PropertyInfo(Variant::OBJECT, "texture", PROPERTY_HINT_NONE, "",PROPERTY_USAGE_DEFAULT, "ImageTexture"), "", "get_image_texture"); 
    */

}

// Update just the height_shape and image from our array
void TerrainSim::publish_image(void)
{
    height_shape->set_map_data(height_array);
    bool mipmaps=false;
    image->set_data(W,H,mipmaps,Image::FORMAT_RF,height_array.to_byte_array());
}

// Private: setup during constructor
void TerrainSim::publish_first() {
    publish_image();
    
    image_texture->set_image(*image);
}

void TerrainSim::publish(void) {
    publish_image();
    
    image_texture->update(*image);
}

TerrainSim::TerrainSim() 
    :sz{MESH_SPACING},
     height_shape{memnew(HeightMapShape3D)},
     image{memnew(Image)},
     image_texture{memnew(ImageTexture)}
{
    height_array.resize(W*H);
    height_floats=height_array.ptrw();

    for (int z=0;z<H;z++)
        for (int x=0;x<W;x++)
        {
            float h = ((x+z/2)%4)*0.025; // slightly fuzzy floor

            float r = sqrt(x*x+z*z);
            if (r<30) h=1.5; // rounded cliff 
            
            if (x==2 && z == 2) h=3.0; // spike, for vertex calibration
            
            height_floats[z*W + x] = h;
        }

    height_shape->set_map_width(W);
    height_shape->set_map_depth(H);
	
	publish_first();
	
    printf("TerrainSim constructor finished (this=%p)\n",this);
}

TerrainSim::~TerrainSim() {
    printf("TerrainSim destructor (this=%p)\n",this);
}


/// Create a mesh as a child of us, so you can see our terrain.
///  Renders using this shader as the basis,
///  replaces the shader's "heights" uniform.
void TerrainSim::add_mesh(Ref<ShaderMaterial> shader)
{
    if (shader==NULL) { //<- we'd crash without a shader
        shader = ResourceLoader::get_singleton()->load("res://terrain/terrain_shader_material.tres");
    }
    if (shader==NULL) {
        printf("TerrainSim can't find shader material, skipping mesh.\n");
        return; // still NULL, no good.
    }
    
    // oddly, you can't seem to Ref<Node>, so use bare pointer.
    MeshInstance3D *mesh_instance{memnew(MeshInstance3D)};
    
    // FIXME: figure out how to share my_mesh with other terrain copies
    Ref<PlaneMesh> my_mesh{ memnew(PlaneMesh) };
    
    my_mesh->set_subdivide_width(2*TerrainSim::W-1);
    my_mesh->set_subdivide_depth(2*TerrainSim::H-1);
    Vector2 size = Vector2(
        TerrainSim::W*MESH_SPACING,
        TerrainSim::H*MESH_SPACING
    );
    my_mesh->set_size(Vector2(
        size.x,size.y
    ));
    my_mesh->set_center_offset(0.5f*Vector3(
        size.x,0.0f,size.y
    ));
    mesh_instance->set_mesh(my_mesh);
    
    // Copy the shader material, so we can use our texture
    Ref<ShaderMaterial> sm{shader->duplicate(true)};
    sm->set_shader_parameter("heights", image_texture);
    mesh_instance->set_surface_override_material(0,sm);
    
    add_child(mesh_instance);
}

/// Create a new CollisionShape3D for our collisions.
///   Includes a scale factor to match our shader and mesh.
CollisionShape3D *TerrainSim::create_collider(void) const
{
    CollisionShape3D *c{memnew(CollisionShape3D)};
    
    c->set_shape(height_shape);
    
    c->set_position(Vector3(
        TerrainSim::W*MESH_SPACING*0.5f,
        0.0f,
        TerrainSim::H*MESH_SPACING*0.5f
    ));
    c->set_scale(Vector3(
        MESH_SPACING,
        1.0f,
        MESH_SPACING
    ));
    
    return c;
}

/// Create a child StaticBody3D so stuff bounces off this terrain.
void TerrainSim::add_static_collider(void)
{
    StaticBody3D *sc{memnew(StaticBody3D)};
    
    sc->add_child(create_collider());
    
    add_child(sc);
}


void TerrainSim::_process(double delta) {
}



