/*

  
  PackedFloat32Array
    float *ptrw(); will return a pointer to the actual data.
  
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
    
    static Ref<Image> create_from_data(int32_t width, int32_t height, bool use_mipmaps, Image::Format format, const PackedByteArray &data);

*/
#include <stdio.h> // for printf
#include "terrainsim.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>


using namespace godot;

void TerrainSim::_bind_methods() {	
    printf("TerrainSim binding methods\n");
    ClassDB::bind_method(D_METHOD("get_height_shape"), &TerrainSim::get_height_shape);
    ClassDB::bind_method(D_METHOD("get_image"), &TerrainSim::get_image);
    // ClassDB::add_property("TerrainSim", PropertyInfo(Variant::OBJECT, "image", PROPERTY_HINT_NONE, "Image",PROPERTY_USAGE_DEFAULT), "", "get_image");

}

void TerrainSim::publish(void) {
    height_shape->set_map_data(height_array);
    bool mipmaps=false;
    image->set_data(W,H,mipmaps,Image::FORMAT_RF,height_array.to_byte_array());
}

TerrainSim::TerrainSim() 
    :sz{0.1f},
     height_shape{memnew(HeightMapShape3D)},
     image{memnew(Image)}
{
    sz = 0.1f;

    height_array.resize(W*H);
    height_floats=height_array.ptrw();

    for (int z=0;z<H;z++)
        for (int x=0;x<W;x++)
        {
            float r = sqrt(x*x+z*z);
            float h = ((x+z/2)%4)*0.25;

            if (r<10) h=0.5;            
            
            height_floats[z*W + x] = h;
        }

    height_shape->set_map_width(W);
    height_shape->set_map_depth(H);

	publish();
    printf("TerrainSim constructor finished (this=%p)\n",this);
}

TerrainSim::~TerrainSim() {
    printf("TerrainSim destructor (this=%p)\n",this);
    /*
    memdelete(height_array);
    memdelete(height_shape);
    memdelete(image);
    */
}

void TerrainSim::_process(double delta) {
}



