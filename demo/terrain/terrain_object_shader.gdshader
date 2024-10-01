/*
GLSL Godot 4 Shader for drawing an object colored like the terrain.
*/
shader_type spatial;
render_mode cull_disabled; // draw both faces, for better shadows

void vertex() {
}


vec3 lunar_surface_normal(vec2 uv)
{
	return vec3(0.5,0.5,1.0); //<- Z up, uses vertex normals calculated above
}

#include "res://terrain/lunar_surface.gdshaderinc"
