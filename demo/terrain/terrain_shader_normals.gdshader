/*
GLSL Godot 4 Shader for drawing a height map with a normal map.

To land a vertex in the center of each NxN height map pixel, you need
either a custom mesh, or a PlaneMesh with 2*N-1 x 2*N-1 subdivide slots.

https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html#doc-spatial-shader
*/
shader_type spatial;
//  render_mode cull_disabled; // draw both faces, for better shadows

uniform sampler2D heights : repeat_disable; // height of terrain in meters along Y axis

void vertex() {
	// Loft the geometry to match the texture image
	//VERTEX.y += texture(heights,UV).r;
	NORMAL = vec3(0,1,0);
}

uniform sampler2D normals : repeat_disable; // surface normal map (GIMP Filters -> Generic -> Normal map...)

vec3 lunar_surface_normal(vec2 uv)
{
	return texture(normals,uv).rgb;
}

#include "res://terrain/lunar_surface.gdshaderinc"
