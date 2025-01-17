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


#include <godot_cpp/variant/signal.hpp>

#ifndef M_PI
#define M_PI 3.141592653589793238 // Windows export doesn't have M_PI defined.
#endif

// Parameters for our dirtball (discrete block of dust)
const float dirtball_sz = 0.1; // meters across a dirtball (for volume estimate)
const float dirtball_dh = powf(dirtball_sz,3.0)/(MESH_SPACING * MESH_SPACING); // volume conservation


using namespace godot;

/*
 See: https://docs.godotengine.org/en/stable/contributing/development/core_and_modules/object_class.html#properties-set-get
*/
void TerrainSim::_bind_methods() {    
    //printf("TerrainSim binding methods\n");
    
    // Methods to do physics or animation
    ClassDB::bind_method(D_METHOD("fill_heights"), &TerrainSim::fill_heights);
    ClassDB::bind_method(D_METHOD("animate_heights"), &TerrainSim::animate_heights);
    ClassDB::bind_method(D_METHOD("try_merge"), &TerrainSim::try_merge);
    ClassDB::bind_method(D_METHOD("excavate_point"), &TerrainSim::excavate_point);
    
    // We call this signal when we want to spawn a new dirtball
    ADD_SIGNAL(MethodInfo("spawn_dirtball", PropertyInfo(Variant::VECTOR3, "spawn_pos"), PropertyInfo(Variant::VECTOR3, "spawn_vel")));

    
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

TerrainSim::TerrainSim() 
    :time(0.0f)
{
    sz = MESH_SPACING; // parent member
    height_next_array.resize(W*H);
    height_next=height_next_array.ptrw();
    
    fill_heights(0,0,30);
}


TerrainSim::~TerrainSim() {
}



/// Fill our initial heights centered on this location
/*void TerrainSim::fill_heights(float cx, float cz,float cliffR)
{
    for (int z=0;z<H;z++)
        for (int x=0;x<W;x++)
        {
            int i = z*W + x;
            float h = ((x+z/2)%4)*0.0025; // slightly uneven floor

            //float r = sqrt((x-cx)*(x-cx)+(z-cz)*(z-cz));
            //if (r<cliffR) h=1.5; // rounded cliff 
            
            

            if (x==64 && z == 64) h=2.5; // demonstration spike, for dirtball calibration
            if (x>=180) h=0.25; // demonstration ridge
            
            height_floats[i] = h;
            height_next[i] = h;
        }
    publish();
}*/
/* CRATER CODE
void TerrainSim::fill_heights(float cx, float cz, float cliffR) {
    float crater_radius = 126.0f;
    float rim_height = 43.0f;
    float crater_depth = 5.0f;
    float sigma = crater_radius / 5.0f;
    const float METERS_PER_UNIT = 25.25f / 256.0f;

    for (int z = 0; z < H; ++z) {
        for (int x = 0; x < W; ++x) {
            int i = z * W + x;
            float dx = x - cx;
            float dz = z - cz;
            float r = std::sqrt(dx * dx + dz * dz);
            float h = 0.0f;

            // Gaussian function for the rim
            float rim_height_value = rim_height * std::exp(-((r - crater_radius) * (r - crater_radius)) / (2 * sigma * sigma));
            h = rim_height_value*METERS_PER_UNIT + ((x+z/2)%4)*0.0025f;
            // Demonstration ridge
            if (x>=180 and h <=0.5f)
                h = 0.5f;
            // Flat ground outside of crater
            if (r>=crater_radius+5.0f && h<=rim_height*METERS_PER_UNIT-0.5f)
                h = rim_height*METERS_PER_UNIT-0.5f;
            // demonstration spike, for dirtball calibration
            if (x==90 && z == 90) h=2.5;

            height_floats[i] = h;
            height_next[i] = h;
        }
    }

    publish();
}*/
void TerrainSim::fill_heights(float cx, float cz, float cliffR) {
    const float METERS_PER_UNIT = 25.25f / 256.0f;
    float hill_height = 3.0;
    float hill_radius = 10.0;

    for (int z = 0; z < H; ++z) {
        for (int x = 0; x < W; ++x) {
            int i = z * W + x;
            float dx = x - cx;
            float dz = z - cz;
            float r = std::sqrt(dx * dx + dz * dz) * METERS_PER_UNIT;
            float h = 0.0f;

            // Calculate the height value for the hill
            if (r <= hill_radius) {
                float hill = hill_height * (1.0f - (r / hill_radius) * (r / hill_radius));
                if (hill < 0) hill = 0;
                h += hill;
            }
            
            // Bevel edge rectangle
            float close = std::min(
                std::min( x - cx, 200.0f - x),
                std::min( z - cz, 240.0f - z)
            );
            float slope=0.18; // height change (meters) per terrain pixel (0.1 meters)
            float edge=close*slope;
            if (edge<0.0f) edge=0.0f;
            if (edge>0.5f) edge=0.5f;
            
            if (h < edge) // Demo ridge
                h = edge;
            

            height_floats[i] = h;
            height_next[i] = h;
        }
    }

    publish();
}

/// Animate low areas of our mesh with smoothly wobbling cosines
///  (useful as a physics test)
void TerrainSim::animate_heights(double dt)
{
    time += dt;
    
    for (int z=0;z<H;z++)
        for (int x=0;x<W;x++)
        {
            int i = z*W + x;
            float h = height_floats[i]; 
            
            if (h<0.5f) {
                h = 0.1f*(cos(time + x*0.5f)+cos(time + z*0.5f));
            
                height_floats[i] = h;
            }
        }
    publish();
}

/// Apply physics of sand transport
void TerrainSim::animate_physics(double dt)
{
    time += dt;
    
    float inv_2dh = 1.0/(2.0*sz); // horizontal pixel spacing
    
    float big = 1000.0; // limit height
    
    // Slope stability threshold
    float angle_of_repose = 60.0f; // degrees up from horizontal (high for jagged moon dust)
    float stability_Y = cos(angle_of_repose * M_PI/180.0f); // for dot product
    
    for (int z=1;z<H-1;z++)
        for (int x=1;x<W-1;x++)
        {
            int i = z*W + x;
            float C = height_floats[i]; 
            float h = C;
            
            // Load neighbor heights
            float           T = height_floats[i-W];
            float L = height_floats[i-1], R=height_floats[i+1];
            float           B = height_floats[i+W];
            float neighborhood = 0.25*(T+B+L+R);
            
            // Estimate slope
            float dx = (R-L)*inv_2dh;
            float dz = (T-B)*inv_2dh;
            Vector3 N = Vector3(dx,1.0f,dz).normalized();
            bool slope_failure = (N.y < stability_Y) && (C>neighborhood); // unstable slope and we're above average
            bool tower_failure = (C>neighborhood+1.5*dirtball_dh); // we're a 'tower' isolated by ourself
            
            if (slope_failure || tower_failure)
            {
                // 'blur' terrain, move with neighbors
                //    FIXME: transport inertia
                //    FIXME: will this conserve mass?
                // h += 1.0*(neighborhood-C);
                
                // convert slope to dirtball(s)
                // Our slope is too high, and we're above our neighbors:
                // Convert this terrain to a dirtball
                
                Vector3 o = get_global_position(); // our global origin
                float above_delta=0.1;
                Vector3 spawn_pos = o + Vector3(x*MESH_SPACING,h + above_delta,z*MESH_SPACING);
                
                float r = 0.5 + 1.0*((rand()%32)*(1.0/31.0)); // stochastic material removal
                h -= r*dirtball_dh; // material removed from terrain and converted to dirtball
                
                spawn_dirtball("slope", spawn_pos, Vector3(0,0,0));
            }
            else {
                // very weak erosion everywhere (prevents weird cliffs)
                //h += 0.001*(neighborhood-C);
            }
            
            if (h!=h) { h=0.0; } // fix NaNs
            
            height_next[i] = h;
        }
    
    // Swap the buffers (pointer swap, more efficient than copy)
    std::swap(height_next,height_floats);
    std::swap(height_next_array,height_array);
    
    publish();
}


void TerrainSim::_physics_process(double delta) {
    animate_physics(delta);
}

/// Create a dirtball at this world coordinates location
void TerrainSim::spawn_dirtball(const char *reason, Vector3 spawn_pos, Vector3 spawn_vel)
{
    printf("spawn %s dirtball at (%.2f,%.2f,%.2f)\n",reason, spawn_pos.x,spawn_pos.y,spawn_pos.z);
    
    emit_signal("spawn_dirtball", spawn_pos, spawn_vel);
}

/// Consider merging this dirtball down into our terrain.
///   If so, do it and return true.  If not, return false.
bool TerrainSim::try_merge(Node3D *dirtball) {
    if (dirtball == NULL) return false;
    
    Vector3 o = get_global_position(); // our global position
    Vector3 d = dirtball->get_global_position(); // dirtball's position
    float fx = (d.x-o.x)*(1.0/MESH_SPACING);
    float fz = (d.z-o.z)*(1.0/MESH_SPACING);
    int ix = (int)floor(fx); // round to lowest int
    int iz = (int)floor(fz); 
    if (ix<=0 || ix>=W-1 || iz<=0 || iz>=H-1) return false; // out of bounds
    
    // Load the terrain height under the dirtball
    float &h = height_floats[iz*W+ix];
    float dY = d.y - (o.y + h); // height of dirtball center over terrain surface
    if (dY<-MESH_SPACING) {
        // already underground!?
        return false;
    }
    if (dY>2.0f*MESH_SPACING) {
        // too high over surface
        return false;
    }

// Add the dirtball to the terrain
    
    // Nearest: raise terrain height at the closest one pixel (lumpy)
    // h += dirtball_dh; // raise terrain height at that one pixel
    /*
    // Bilinear interpolation: makes a smoother initial deposit on terrain, but doesn't seem to scale
    float fracx = fx - ix, fracz = fz - iz; // between 0.0 (on the int) and 1.0 (almost to next)
    height_floats[(iz+0)*W + (ix+0)] += (1.0-fracx)*(1.0-fracz)*dirtball_dh;
    height_floats[(iz+1)*W + (ix+0)] += (1.0-fracx)*     fracz *dirtball_dh;
    height_floats[(iz+0)*W + (ix+1)] +=      fracx *(1.0-fracz)*dirtball_dh;
    height_floats[(iz+1)*W + (ix+1)] +=      fracx *     fracz *dirtball_dh;
    */
    
    // Lowest: Find lowest neighboring terrain pixel to merge dirt onto
    int low_i=iz*W+ix;
    float low_ht = h-0.05; //<- definite preference for nearest pixel
    for (int dx=-1;dx<=+1;dx++) for (int dz=-1;dz<=+1;dz++) {
        int i=(iz+dz)*W+(ix+dx);
        if (i>0 && i<W*H) { // source index is in bounds
            float h = height_floats[i];
            if (h<low_ht) {
                low_ht=h;
                low_i=i;
            }
        }
    }
    height_floats[low_i] += dirtball_dh; // dump dirt into low spot
    
    printf("Merged dirtball at terrain pixel (%d,%d)\n", ix,iz);
    
    return true;
}

/// Excavate down to this world-coordinates location.
///   dirtball_offset determines the spawn point of any dirtballs excavated.
///   Returns an estimate of the amount of material excavated.
float TerrainSim::excavate_point(Vector3 world, Vector3 dirtball_offset, Vector3 spawn_vel)
{
    float pushback = 0.0f;
    Vector3 o = get_global_position(); // our global position
    float fx = (world.x-o.x)*(1.0f/MESH_SPACING);
    float fz = (world.z-o.z)*(1.0f/MESH_SPACING);
    int ix = (int)roundf(fx); // round to nearest int
    int iz = (int)roundf(fz); 
    if (ix<=0 || ix>=W-1 || iz<=0 || iz>=H-1) return false; // out of bounds
    
    // Load the terrain height
    float &h = height_floats[iz*W+ix];
    float dY = (o.y + h) - world.y; // height over terrain surface
    
    if (dY < 0.0) { // the cutting edge isn't really inside the terrain yet
        return 0.0f;
    }
    
    int nspawn = roundf(dY / dirtball_dh);
    //printf("excavating world %.2f, %.2f, %.2f: dY %.2f, nspawn %d\n", world.x,world.y,world.z, dY,nspawn);
    if (nspawn>2) { // just stall out instead of making huge cut (detonates a crater)
        return dY / dirtball_dh;
    }
    
    for (int i=0;i<nspawn;i++)
        spawn_dirtball("excavate", world + dirtball_offset + Vector3(0,(0.5+i)*dirtball_dh,0), spawn_vel);

    h -= dY; // lower the terrain height to match the dirtballs excavated here
    
    pushback += dY / dirtball_dh;
    return pushback;
}




