/*
  Modifiable terrain simulator:
    - Excavate dirtballs from terrain
    - Simulate unstable slopes for landsliding material
    - Merge mobile dirtballs back down into terrain
  
  by Orion Lawlor, lawlor@alaska.edu, 2024-03 through 2024-09 (Public Domain)
*/
#ifndef GODOTROBOT_TERRAINSIM_H
#define GODOTROBOT_TERRAINSIM_H

#include "terrainstatic.h"

namespace godot {

/// Represents a chunk of terrain.
class TerrainSim : public TerrainStatic256 {
    GDCLASS(TerrainSim, TerrainStatic256)

public:
/// Float size of mesh cells, horizontal distance
#define MESH_SPACING 0.1f
    
    TerrainSim();
    ~TerrainSim();
    
    /// Fill our mesh centered on this location
    void fill_heights(float cx, float cz, float cliffR);
    
    /// Animate our mesh with smoothly wobbling cosines
    void animate_heights(double dt);
    
    /// Apply physics of sand transport
    void animate_physics(double dt);
    
    
    /// Check slope stability, consider creating new dirtballs
    void _physics_process(double delta) override;
    
    
    
    /// Consider merging this dirtball with our terrain.
    ///   If so, do it and return true.  If not, return false.
    bool try_merge(Node3D *dirtball);
    
    /// Excavate down to this world-coordinates location.
    ///   dirtball_offset determines the world spawn point of any dirtballs excavated, relative to the terrain excavated.
    ///   spawn_vel determines the world velocity of any dirtballs excavated.
    ///   Returns an estimate of the amount of material excavated, in dirtballs.
    float excavate_point(Vector3 world, Vector3 dirtball_offset, Vector3 spawn_vel);
    

private:
    /// Simulated time
    double time;
    
    /// Next height data, in meters (jacobi iteration style)
    PackedFloat32Array height_next_array;
    float *height_next;
    
    /// Create a dirtball at this world coordinates location
    void spawn_dirtball(const char *reason, Vector3 spawn_pos, Vector3 spawn_vel);
    
protected:
    static void _bind_methods();
};

}

#endif


