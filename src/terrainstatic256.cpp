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



