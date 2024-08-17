/*
 Implements static terrain load functions.
*/
#include "terrainstatic.h"


using namespace godot;



void TerrainStatic256::_bind_methods()
{
    printf("TerrainStatic binding methods\n");

    // The get methods are so script can access our terrain data
    ClassDB::bind_method(D_METHOD("get_height_shape"), &TerrainStatic256::get_height_shape);
    ClassDB::bind_method(D_METHOD("get_image"), &TerrainStatic256::get_image);
    ClassDB::bind_method(D_METHOD("get_image_texture"), &TerrainStatic256::get_image_texture);
    
    // Methods to set up and configure the object
    ClassDB::bind_method(D_METHOD("add_mesh"), &TerrainStatic256::add_mesh);
    ClassDB::bind_method(D_METHOD("create_collider"), &TerrainStatic256::create_collider);
    ClassDB::bind_method(D_METHOD("add_static_collider"), &TerrainStatic256::add_static_collider);
}


